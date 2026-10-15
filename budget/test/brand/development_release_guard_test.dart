import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory temporary;
  late String dart;
  late File fixture;
  setUpAll(() {
    final config = File('.dart_tool/package_config.json').absolute;
    final packages = jsonDecode(config.readAsStringSync())['packages'] as List;
    final flutter = packages.singleWhere((p) => p['name'] == 'flutter');
    final sdk =
        Directory.fromUri(config.uri.resolve(flutter['rootUri'])).parent.parent;
    dart =
        '${sdk.path}/bin/cache/dart-sdk/bin/dart${Platform.isWindows ? '.exe' : ''}';
    temporary = Directory.systemTemp.createTempSync('ola-dev-guard-');
    fixture = File('${temporary.path}/guard.dart')
      ..writeAsStringSync(
        "import '${File('lib/brand/development_release_guard.dart').absolute.uri}';\n"
        'void main() { const DevelopmentReleaseGuard().ensureInternalBuild(); }\n',
      );
  });
  tearDownAll(() => temporary.deleteSync(recursive: true));

  Future<ProcessResult> compile(List<String> defines) => Process.run(
      dart,
      [
        'compile',
        'kernel',
        ...defines,
        '-o',
        '${temporary.path}/probe.dill',
        fixture.path,
      ],
      stdoutEncoding: utf8,
      stderrEncoding: utf8);

  test('ordinary internal debug compilation is permitted', () async {
    for (final defines in <List<String>>[
      [],
      ['-DOLA_ENVIRONMENT=development'],
      ['-DOLA_ENVIRONMENT=staging']
    ]) {
      final result = await compile(defines);
      expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
    }
  });
  test(
      'release and profile compilation fail with explicit public-release block',
      () async {
    for (final define in ['dart.vm.product=true', 'dart.vm.profile=true']) {
      final result = await compile(['-D$define']);
      expect(result.exitCode, isNot(0));
      expect(
          '${result.stdout}${result.stderr}',
          contains(
              'TEMPORARY ÓLA DEV BRAND ASSETS PRESENT — PUBLIC RELEASE BLOCKED'));
    }
  });
  test('production environment variants cannot bypass the debug guard',
      () async {
    for (final environment in [
      'production',
      'Production',
      ' production ',
      'PRODUCTION'
    ]) {
      final result = await compile(['-DOLA_ENVIRONMENT=$environment']);
      expect(result.exitCode, isNot(0), reason: environment);
      expect(
          '${result.stdout}${result.stderr}',
          contains(
              'TEMPORARY ÓLA DEV BRAND ASSETS PRESENT — PUBLIC RELEASE BLOCKED'));
    }
  });
}
