enum RestoreFailureStage {
  format,
  open,
  compatibility,
  schema,
  integrity,
  references,
  migration,
  staging,
  activation,
  postActivation,
  rollback,
}

class DatabaseRestoreResult {
  final bool isSuccess;
  final String message;
  final RestoreFailureStage? failureStage;
  final int? sourceSchemaVersion;
  final int? activatedSchemaVersion;
  final String? safetyBackupPath;
  final String? recoveryPath;
  final bool rollbackSucceeded;

  const DatabaseRestoreResult._({
    required this.isSuccess,
    required this.message,
    this.failureStage,
    this.sourceSchemaVersion,
    this.activatedSchemaVersion,
    this.safetyBackupPath,
    this.recoveryPath,
    this.rollbackSucceeded = false,
  });

  const DatabaseRestoreResult.success({
    required int sourceSchemaVersion,
    required int activatedSchemaVersion,
    required String? safetyBackupPath,
  }) : this._(
          isSuccess: true,
          message: 'Backup validated and activated.',
          sourceSchemaVersion: sourceSchemaVersion,
          activatedSchemaVersion: activatedSchemaVersion,
          safetyBackupPath: safetyBackupPath,
        );

  const DatabaseRestoreResult.failure({
    required RestoreFailureStage stage,
    required String message,
    int? sourceSchemaVersion,
    String? safetyBackupPath,
    String? recoveryPath,
    bool rollbackSucceeded = false,
  }) : this._(
          isSuccess: false,
          message: message,
          failureStage: stage,
          sourceSchemaVersion: sourceSchemaVersion,
          safetyBackupPath: safetyBackupPath,
          recoveryPath: recoveryPath,
          rollbackSucceeded: rollbackSucceeded,
        );
}

class DatabaseRestoreException implements Exception {
  final DatabaseRestoreResult result;

  const DatabaseRestoreException(this.result);

  @override
  String toString() => result.message;
}
