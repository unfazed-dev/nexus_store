#!/usr/bin/env bash
# render-diagrams.sh — Render Mermaid diagrams from Markdown files to SVG/PNG
#
# Usage:
#   ./render-diagrams.sh <file.md>             # Render diagrams from single file
#   ./render-diagrams.sh <directory>            # Render all .md files recursively
#   ./render-diagrams.sh                        # Render docs/diagrams/ by default
#   ./render-diagrams.sh --format png <file>    # Render as PNG instead of SVG
#   ./render-diagrams.sh --theme <file.json>    # Use custom theme config
#
# Output:
#   Rendered files go to docs/diagrams/.rendered/ (gitignored)
#   Filenames: <source-filename>-<block-number>.<format>
#
# Requirements:
#   npm install -g @mermaid-js/mermaid-cli    # Provides 'mmdc' command

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Defaults
FORMAT="svg"
THEME_CONFIG=""
TARGET=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --format)
            FORMAT="$2"
            shift 2
            ;;
        --theme)
            THEME_CONFIG="$2"
            shift 2
            ;;
        *)
            TARGET="$1"
            shift
            ;;
    esac
done

TARGET="${TARGET:-docs/diagrams}"
OUTPUT_DIR="docs/diagrams/.rendered"

# Check mmdc is installed
if ! command -v mmdc &> /dev/null; then
    echo -e "${RED}Error: mmdc (mermaid-cli) not found${NC}"
    echo "Install with: npm install -g @mermaid-js/mermaid-cli"
    exit 2
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Add .rendered to .gitignore if not already there
GITIGNORE="docs/diagrams/.gitignore"
if [[ ! -f "$GITIGNORE" ]] || ! grep -q ".rendered" "$GITIGNORE" 2>/dev/null; then
    echo ".rendered/" >> "$GITIGNORE"
    echo -e "${YELLOW}Added .rendered/ to $GITIGNORE${NC}"
fi

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

TOTAL=0
RENDERED=0
FAILED=0

# Find markdown files
if [[ -f "$TARGET" ]]; then
    FILES=("$TARGET")
elif [[ -d "$TARGET" ]]; then
    mapfile -t FILES < <(find "$TARGET" -name "*.md" -type f | sort)
else
    echo -e "${RED}Error: $TARGET is not a file or directory${NC}"
    exit 1
fi

echo -e "${BLUE}Rendering Mermaid diagrams to ${FORMAT}...${NC}"
echo -e "Output: ${OUTPUT_DIR}/"
echo ""

# Build mmdc args
MMDC_ARGS=()
if [[ -n "$THEME_CONFIG" ]]; then
    MMDC_ARGS+=("-c" "$THEME_CONFIG")
fi

for file in "${FILES[@]}"; do
    BASENAME=$(basename "$file" .md)
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
            TEMP_FILE="$TEMP_DIR/${BASENAME}-${BLOCK_NUM}.mmd"
            echo "$BLOCK_CONTENT" > "$TEMP_FILE"

            # Render with mmdc
            OUTPUT_FILE="$OUTPUT_DIR/${BASENAME}-${BLOCK_NUM}.${FORMAT}"
            if mmdc -i "$TEMP_FILE" -o "$OUTPUT_FILE" "${MMDC_ARGS[@]}" -q 2>/dev/null; then
                RENDERED=$((RENDERED + 1))
                echo -e "  ${GREEN}OK${NC} ${BASENAME}-${BLOCK_NUM}.${FORMAT}"
            else
                FAILED=$((FAILED + 1))
                echo -e "  ${RED}FAIL${NC} ${BASENAME}-${BLOCK_NUM} (syntax error)"
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
echo -e "  Total:    $TOTAL"
echo -e "  ${GREEN}Rendered: $RENDERED${NC}"
if [[ $FAILED -gt 0 ]]; then
    echo -e "  ${RED}Failed:   $FAILED${NC}"
fi
echo -e "  Output:   $OUTPUT_DIR/"

if [[ $FAILED -gt 0 ]]; then
    exit 1
fi
