/// 应用配置（示例文件，可提交到仓库）。
///
/// 使用方法：
/// 1. 复制本文件为 `lib/config.dart`
/// 2. 把 `amapWebApiKey` 换成你自己的高德 Web 服务 Key
///    （申请地址：https://console.amap.com/ ，服务平台选「Web服务」）
///
/// 注意：`lib/config.dart` 已被 .gitignore 忽略，不会提交到仓库，
/// 避免泄露你的 Key。
class AppConfig {
  AppConfig._();

  /// 高德 Web 服务 Key（用于逆地理编码 + 周边搜索）。
  static const String amapWebApiKey = '在这里填你的高德Key';
}
