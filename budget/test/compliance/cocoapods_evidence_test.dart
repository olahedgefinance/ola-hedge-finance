import 'dart:io';
import 'dart:convert';
import '../../tool/compliance/cocoapods_evidence.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../tool/compliance/generate_sbom.dart';

void main() {
  test('exact locked AppAuth source licence becomes a conditional declaration',
      () async {
    final bundle = await createComplianceArtifactBundle(
        repositoryRoot: Directory.current.parent);
    final pod =
        bundle.components.singleWhere((c) => c.id == 'cocoapods:AppAuth');
    expect(pod.version, '1.7.5');
    expect(pod.licenseDeclared, 'Apache-2.0');
    expect(pod.reviewStatus, 'verified-with-conditions');
    expect(pod.downloadLocation,
        contains('c89ed571ae140f8eb1142735e6e23d7bb8c34cb2'));
  });

  final root = Directory.current.parent;
  final folder = Directory('${root.path}/$cocoaPodsEvidencePath');
  final manifest =
      jsonDecode(File('${folder.path}/manifest.json').readAsStringSync());
  final lockBytes =
      File('${root.path}/budget/ios/Podfile.lock').readAsBytesSync();
  final pods = parsePodfileLock(utf8.decode(lockBytes));
  Map<String, dynamic> row(String name) => Map<String, dynamic>.from(
      (manifest['records'] as List).singleWhere((r) => r['name'] == name));
  void verify(Map<String, dynamic> r,
      {List<int>? bytes, String? text, String? receipt}) {
    verifyCocoaPodRecord(
        record: r,
        locked: pods.singleWhere((p) => p.name == r['name']),
        specBytes:
            bytes ?? File('${folder.path}/${r['specFile']}').readAsBytesSync(),
        licenceText: text ??
            (r['licenceFile'] == null
                ? null
                : File('${folder.path}/${r['licenceFile']}')
                    .readAsStringSync()),
        licenceResponse: r['licenceResponseFile'] == null
            ? null
            : File('${folder.path}/${r['licenceResponseFile']}')
                .readAsBytesSync(),
        refReceipt: receipt ??
            (r['refReceipt'] == null
                ? null
                : File('${folder.path}/${r['refReceipt']}')
                    .readAsStringSync()));
  }

  test('every registry podspec replays against current locked checksums', () {
    final records = loadCocoaPodsSourceEvidence(root, pods);
    expect(records.keys,
        containsAll(['AppAuth', 'FirebaseAuth', 'gRPC-Core', 'sqlite3']));
    for (final r in records.values) {
      verify(r);
    }
  });
  test('changed podspec bytes and stale locked versions are rejected', () {
    final r = row('AppAuth');
    expect(() => verify(r, bytes: utf8.encode('{}')), throwsStateError);
    r['version'] = '1.7.4';
    expect(() => verify(r), throwsStateError);
  });
  test('source substitution and tag drift are rejected', () {
    final r = row('AppAuth');
    r['source'] = {'git': 'https://example.invalid/other.git', 'tag': '1.7.5'};
    expect(() => verify(r), throwsStateError);
    expect(
        () => verify(row('AppAuth'), receipt: '${'0' * 40}\trefs/tags/1.7.5'),
        throwsStateError);
    final changed = row('BoringSSL-GRPC')..['resolvedCommit'] = '0' * 40;
    expect(() => verify(changed), throwsStateError);
  });
  test('missing source URLs and altered licence bytes cannot be accepted', () {
    final r = row('AppAuth')..['downloadLocation'] = '';
    expect(() => verify(r), throwsStateError);
    expect(() => verify(row('AppAuth'), text: 'replaced licence'),
        throwsStateError);
  });
  test(
      'metadata alone cannot clear composite, proprietary or public-domain terms',
      () {
    for (final name in [
      'BoringSSL-GRPC',
      'FirebaseFirestore',
      'FirebaseFirestoreInternal',
      'GoogleUtilities',
      'gRPC-C++',
      'gRPC-Core',
      'RecaptchaEnterprise',
      'sqlite3'
    ]) {
      final r = row(name);
      verify(r);
      expect(r['licenseDeclared'], 'NOASSERTION', reason: name);
      r['licenseDeclared'] = 'Apache-2.0';
      expect(() => verify(r), throwsStateError, reason: name);
    }
    expect(cocoaPodsDeclaration('MIT', 'custom terms'), 'NOASSERTION');
    expect(cocoaPodsDeclaration('MIT', null), 'NOASSERTION');
  });
  test('licence origin must match authenticated repository revision and path',
      () {
    for (final url in [
      'https://example.invalid/LICENSE',
      'https://raw.githubusercontent.com/openid/AppAuth-iOS/main/LICENSE'
    ]) {
      expect(
          () => verify(row('AppAuth')..['licenceUrl'] = url), throwsStateError);
    }
    expect(() => verify(row('AppAuth')..['licencePath'] = '../LICENSE'),
        throwsStateError);
    expect(() => verify(row('SwiftyGif')..['licenceResponseSha256'] = '0' * 64),
        throwsStateError);
  });
  test('native evidence cannot promote itself to legal clearance', () {
    final r = row('AppAuth')..['status'] = 'verified';
    expect(() => verify(r), throwsStateError);
  });
  test('manifest coverage, path escape and changed lock are rejected', () {
    final temp = Directory.systemTemp.createTempSync('ola-pod-proof-');
    addTearDown(() => temp.deleteSync(recursive: true));
    final lock = File('${temp.path}/budget/ios/Podfile.lock')
      ..createSync(recursive: true);
    lock.writeAsBytesSync(lockBytes);
    final file = File('${temp.path}/$cocoaPodsEvidencePath/manifest.json')
      ..createSync(recursive: true);
    final data = jsonDecode(jsonEncode(manifest)) as Map<String, dynamic>;
    data['records'] = [];
    file.writeAsStringSync(jsonEncode(data));
    expect(() => loadCocoaPodsSourceEvidence(temp, pods), throwsStateError);
    data['records'] = [row('AppAuth')..['specFile'] = '../escape.json'];
    file.writeAsStringSync(jsonEncode(data));
    expect(() => loadCocoaPodsSourceEvidence(temp, pods), throwsStateError);
    lock.writeAsStringSync('changed');
    expect(() => loadCocoaPodsSourceEvidence(temp, pods), throwsStateError);
  });
}
