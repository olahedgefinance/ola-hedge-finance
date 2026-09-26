import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/compliance/release_compliance.dart';

void main() {
  final repositoryRoot = Directory.current.parent;

  test('SHA-256 verification uses file bytes rather than manifest trust',
      () async {
    final directory = await Directory.systemTemp.createTemp('ola-sbom-test-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}${Platform.pathSeparator}fixture.txt');
    await file.writeAsString('abc');

    expect(await sha256File(file),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
  });

  test('release manifest rejects placeholders and unsigned human gates', () {
    final template = jsonDecode(
        File('${repositoryRoot.path}${Platform.pathSeparator}compliance'
                '${Platform.pathSeparator}release${Platform.pathSeparator}'
                'release-manifest.template.json')
            .readAsStringSync()) as Map<String, dynamic>;

    final errors = validateReleaseManifestStructure(template);

    expect(errors, contains(contains('releaseVersion')));
    expect(errors, contains(contains('sourceCommit')));
    expect(errors, contains(contains('correspondingSourceUrl')));
    expect(errors, contains(contains('noticesIncluded')));
    expect(errors, contains(contains('legalReview')));
  });

  test('release manifest accepts a structurally complete reviewed record', () {
    final errors = validateReleaseManifestStructure(<String, dynamic>{
      'schemaVersion': 1,
      'releaseVersion': '5.4.3+416',
      'sourceCommit': '0123456789abcdef0123456789abcdef01234567',
      'sourceTag': 'ola-5.4.3+416',
      'correspondingSourceUrl':
          'https://github.com/olahedgefinance/ola-hedge-finance/releases/tag/ola-5.4.3%2B416',
      'sourceArchive': <String, dynamic>{
        'path': 'release/ola-5.4.3+416-source.tar.gz',
        'sha256':
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      },
      'binaryArtifacts': <Map<String, dynamic>>[
        <String, dynamic>{
          'platform': 'web',
          'path': 'release/web-5.4.3+416.zip',
          'sha256':
              'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
        }
      ],
      'sbomPath': 'compliance/sbom/5.4.3+416.spdx.json',
      'noticesIncluded': true,
      'gplSourceOfferReviewed': true,
      'assetAndFontRightsCleared': true,
      'storeTermsReviewed': true,
      'legalReview': <String, dynamic>{
        'approved': true,
        'reviewer': 'Qualified reviewer',
        'reviewDate': '2026-09-25',
      },
    });

    expect(errors, isEmpty);
  });

  test('inventory validation rejects unaccounted missing licence evidence', () {
    final errors = validateInventoryContract(<String, dynamic>{
      'schemaVersion': 1,
      'summary': <String, dynamic>{'components': 1},
      'components': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'example:missing',
          'licenseDeclared': 'NOASSERTION',
          'licenseEvidence': '',
          'reviewStatus': 'verified',
        }
      ],
      'auditGaps': <dynamic>[],
    });

    expect(errors, contains(contains('example:missing')));
    expect(errors, contains(contains('review-required')));
    expect(errors, contains(contains('audit gap')));
  });

  test('current repository passes the non-release compliance audit', () async {
    final errors = await runRepositoryComplianceAudit(
      repositoryRoot: repositoryRoot,
    );

    expect(errors, isEmpty, reason: errors.join('\n'));
  });
}
