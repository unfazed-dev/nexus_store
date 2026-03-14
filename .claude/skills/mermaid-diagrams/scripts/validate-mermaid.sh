#!/usr/bin/env bash
# validate-mermaid.sh — Extract and validate Mermaid diagrams from Markdown files
#
# Usage:
#   ./validate-mermaid.sh <file.md>           # Validate single file
#   ./validate-mermaid.sh <directory>          # Validate all .md files recursively
#   ./validate-mermaid.sh                      # Validate docs/diagrams/ by default
#
# Requirements:
#   npm install -g @mermaid-js/mermaid-cli    # Provides 'mmdc' command
#
# Exit codes:
#   0 — All diagrams valid
#   1 — One or more diagrams have syntax errors
#   2 — mmdc not installed

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check mmdc is installed
if ! command -v mmdc &> /dev/null; then
    echo -e "${RED}Error: mmdc (mermaid-cli) not found${NC}"
    echo "Install with: npm install -g @mermaid-js/mermaid-cli"
    exit 2
fi

# Determine target
TARGET="${1:-docs/diagrams}"
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

TOTAL=0
PASSED=0
FAILED=0
ERRORS=()

# Find markdown files
if [[ -f "$TARGET" ]]; then
    FILES=("$TARGET")
elif [[ -d "$TARGET" ]]; then
    mapfile -t FILES < <(find "$TARGET" -name "*.md" -type f | sort)
else
    echo -e "${RED}Error: $TARGET is not a file or directory${NC}"
    exit 1
fi

echo -e "${BLUE}Validating Mermaid diagrams...${NC}"
echo ""

for file in "${FILES[@]}"; do
    # Extract mermaid code blocks using awk
    BLOCK_NUM=0
    IN_MERMAID=false
    BLOCK_CONTENT=""

    while IFS= read -r line; do
        if [[ "$line" =~ ^\`\`\`mermaid ]]; then
            IN_MERMAID=true
            BLOCK_CONTENT=""
            continue
        fi

        if [[ "$IN_MERMAID" == true ]] && [[ "$line" =~ ^\`\`\` ]]; then
            IN_MERMAID=false
            BLOCK_NUM=$((BLOCK_NUM + 1))
            TOTAL=$((TOTAL + 1))

            # Write block to temp file
            TEMP_FILE="$TEMP_DIR/block_${TOTAL}.mmd"
            echo "$BLOCK_CONTENT" > "$TEMP_FILE"

            # Validate with mmdc
            OUTPUT_FILE="$TEMP_DIR/output_${TOTAL}.svg"
            if mmdc -i "$TEMP_FILE" -o "$OUTPUT_FILE" -q 2>/dev/null; then
                PASSED=$((PASSED + 1))
                echo -e "  ${GREEN}PASS${NC} $file (block $BLOCK_NUM)"
            else
                FAILED=$((FAILED + 1))
                ERRORS+=("$file:block-$BLOCK_NUM")
                echo -e "  ${RED}FAIL${NC} $file (block $BLOCK_NUM)"
            fi
            continue
        fi

        if [[ "$IN_MERMAID" == true ]]; then
            BLOCK_CONTENT+="$line"$'\n'
        fi
    done < "$file"
done

# Summary
echo ""
echo -e "${BLUE}Results:${NC}"
echo -e "  Total:  $TOTAL"
echo -e "  ${GREEN}Passed: $PASSED${NC}"

if [[ $FAILED -gt 0 ]]; then
    echo -e "  ${RED}Failed: $FAILED${NC}"
    echo ""
    echo -e "${RED}Failed diagrams:${NC}"
    for err in "${ERRORS[@]}"; do
        echo -e "  - $err"
    done
    exit 1
else
    echo -e "  Failed: 0"
    echo ""
    echo -e "${GREEN}All diagrams valid!${NC}"
    exit 0
fi
