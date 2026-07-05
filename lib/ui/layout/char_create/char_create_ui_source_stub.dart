/// 非 IO 平台（Web / Release）：僅使用 rootBundle，不支援檔案監聽。
Future<String?> readDebugAssetFile(String assetPath) async => null;

void watchDebugAssetFile(String assetPath, void Function() onChanged) {}
