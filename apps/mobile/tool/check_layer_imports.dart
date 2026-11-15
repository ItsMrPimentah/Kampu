import 'dart:io';

/// Checks dependency direction for migrated screens, core, and shared code.
void main() {
  final lib = Directory('lib').absolute.uri;
  var violations = 0;
  for (final entity in Directory('lib').listSync()) {
    if (entity is Directory &&
        entity
            .listSync(recursive: true)
            .whereType<File>()
            .any((f) => f.path.endsWith('.dart')) &&
        !['app', 'screens', 'core', 'shared'].contains(
          entity.uri.pathSegments[entity.uri.pathSegments.length - 2],
        )) {
      stderr.writeln(
        '${entity.path}: feature directories must be inside a layer',
      );
      violations++;
    }
  }
  if (Directory('lib/core/auth').existsSync() &&
      Directory('lib/core/auth')
          .listSync(recursive: true)
          .whereType<File>()
          .any((f) => f.path.endsWith('.dart'))) {
    stderr.writeln(
      'lib/core/auth: app-wide authentication belongs in lib/app/auth',
    );
    violations++;
  }
  for (final layer in ['shared', 'core', 'screens']) {
    for (final entity in Directory('lib/$layer').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final directives = RegExp(r'''(?:import|export)\s+['"]([^'"]+)['"]''');
      for (final match in directives.allMatches(entity.readAsStringSync())) {
        final target = match.group(1);
        if (target == null) continue;
        final path = _localPath(target, entity.absolute.uri, lib);
        if (path == null) continue;
        final valid =
            path.startsWith('shared/') ||
            (layer != 'shared' && path.startsWith('core/')) ||
            (layer == 'screens' && path.startsWith('screens/'));
        if (!valid) {
          stderr.writeln(
            '${entity.path}: $target violates $layer dependency direction',
          );
          violations++;
        }
      }
    }
  }
  if (violations > 0) {
    exitCode = 1;
  } else {
    stdout.writeln('Migrated layer imports are valid.');
  }
}

String? _localPath(String target, Uri source, Uri lib) {
  const packagePrefix = 'package:showtime_mobile/';
  if (target.startsWith(packagePrefix)) {
    return target.substring(packagePrefix.length);
  }
  if (target.contains(':')) return null;
  final resolved = source.resolve(target).normalizePath().toFilePath();
  final root = lib.toFilePath();
  return resolved.startsWith(root)
      ? resolved.substring(root.length)
      : '../outside-lib';
}
