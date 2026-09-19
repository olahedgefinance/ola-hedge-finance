import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/gmail/v1.dart' as gmail;

const _identityScopes = <String>[
  'https://www.googleapis.com/auth/userinfo.profile',
  'https://www.googleapis.com/auth/userinfo.email',
];

List<String> googleAuthorizationScopes({
  bool driveEnabled = false,
  bool attachmentAccess = false,
  bool gmailEnabled = false,
}) {
  return <String>[
    ..._identityScopes,
    if (driveEnabled) drive.DriveApi.driveAppdataScope,
    if (driveEnabled && attachmentAccess) drive.DriveApi.driveFileScope,
    if (gmailEnabled) ...[
      gmail.GmailApi.gmailReadonlyScope,
      gmail.GmailApi.gmailModifyScope,
    ],
  ];
}
