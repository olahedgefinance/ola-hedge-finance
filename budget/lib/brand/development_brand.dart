import 'package:flutter/services.dart';
import 'brand_identity.dart';

/// Supplemental identity for internal development. Frozen release metadata stays intact.
const developmentBrand = BrandIdentity(
  productName: 'ÓLA HEDGE FINANCE',
  shortName: 'ÓLA HEDGE',
  description: 'A budget and financial tracking application designed for you',
);

/// Explicit UI overlay: historical paths remain evidenced, debug screens load DEV art.
/// This does not modify the original files or claim they are release-cleared.
class DevelopmentBrandAssetBundle extends CachingAssetBundle {
  DevelopmentBrandAssetBundle(this.base);
  final AssetBundle base;

  static const aliases = <String, String>{
    'assets/icon/icon.png': 'assets/icon/ola_dev_icon.png',
    'assets/icon/icon-small.png': 'assets/icon/ola_dev_icon-small.png',
    'assets/icon/notification_icon_android.png':
        'assets/icon/ola_dev_notification_icon_android.png',
    'assets/icon/notification_icon_android2.png':
        'assets/icon/ola_dev_notification_icon_android2.png',
  };

  @override
  Future<ByteData> load(String key) => base.load(aliases[key] ?? key);
}
