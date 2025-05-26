// lib/core/providers/app_info_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:package_info_plus/package_info_plus.dart';

part 'app_info_provider.g.dart';

// Keep alive might not be needed, but harmless
@Riverpod(keepAlive: true)
Future<PackageInfo> packageInfo(PackageInfoRef ref) async {
  // Initialize PackageInfo
  final info = await PackageInfo.fromPlatform();
  print("PackageInfo loaded: v${info.version} b${info.buildNumber}"); // Debug log
  return info;
}