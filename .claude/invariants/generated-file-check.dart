// Invariant: No generated files checked into git
// Verifies that .g.dart files are not tracked by git.
// They should be in .gitignore and regenerated via build_runner.
// Enforces: .claude/rules/architecture.md

import 'dart:io';

void main() {
  // Use git ls-files to find tracked .g.dart files
  final result = Process.runSync(
    'git',
    ['ls-files', '--cached', '*.g.dart', 'packages/'],
    workingDirectory: Directory.current.path,
  );

  if (result.exitCode != 0) {
    print('generated-file-check: SKIP (not a git repository or git error)');
    exit(0);
  }

  final trackedFiles = (result.stdout as String)
      .split('\n')
      .where((line) => line.trim().isNotEmpty && line.endsWith('.g.dart'))
      .toList();

  if (trackedFiles.isEmpty) {
    print('generated-file-check: PASS (no .g.dart files tracked by git)');
    exit(0);
  }

  print(
      'generated-file-check: FAIL (${trackedFiles.length} generated files tracked by git)',);
  for (final f in trackedFiles) {
    print('  $f — remove with: git rm --cached "$f"');
  }
  exit(1);
}
