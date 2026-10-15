/// This source tree carries temporary internal branding, not release artwork.
const developmentReleaseBlocked =
    'TEMPORARY ÓLA DEV BRAND ASSETS PRESENT — PUBLIC RELEASE BLOCKED';

const _productBuild = bool.fromEnvironment('dart.vm.product');
const _profileBuild = bool.fromEnvironment('dart.vm.profile');
const _environment =
    String.fromEnvironment('OLA_ENVIRONMENT', defaultValue: 'development');

/// A const assertion fails compilation, including builds with runtime asserts off.
/// All app entrypoints must instantiate this guard before starting the app.
class DevelopmentReleaseGuard {
  const DevelopmentReleaseGuard()
      : assert(!_productBuild, developmentReleaseBlocked),
        assert(!_profileBuild, developmentReleaseBlocked),
        assert(
          _environment == '' ||
              _environment == 'development' ||
              _environment == 'staging',
          developmentReleaseBlocked,
        );

  void ensureInternalBuild() {}
}
