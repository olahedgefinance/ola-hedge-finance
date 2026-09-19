import 'package:budget/config/google_auth_scopes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/gmail/v1.dart' as gmail;

void main() {
  test('identity sign-in requests only minimum identity scopes', () {
    expect(
      googleAuthorizationScopes(),
      const [
        'https://www.googleapis.com/auth/userinfo.profile',
        'https://www.googleapis.com/auth/userinfo.email',
      ],
    );
  });

  test('Drive scopes require the Drive capability', () {
    expect(
      googleAuthorizationScopes(driveEnabled: true),
      contains(drive.DriveApi.driveAppdataScope),
    );
    expect(
      googleAuthorizationScopes(
        driveEnabled: true,
        attachmentAccess: true,
      ),
      contains(drive.DriveApi.driveFileScope),
    );
    expect(
      googleAuthorizationScopes(attachmentAccess: true),
      isNot(contains(drive.DriveApi.driveFileScope)),
    );
  });

  test('Gmail scopes require the Gmail capability', () {
    expect(
      googleAuthorizationScopes(gmailEnabled: true),
      containsAll([
        gmail.GmailApi.gmailReadonlyScope,
        gmail.GmailApi.gmailModifyScope,
      ]),
    );
    expect(
      googleAuthorizationScopes(),
      isNot(contains(gmail.GmailApi.gmailReadonlyScope)),
    );
  });
}
