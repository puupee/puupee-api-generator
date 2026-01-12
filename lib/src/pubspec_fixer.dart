import 'dart:io';
import 'package:yaml/yaml.dart';

/// Pubspec 修复器
/// 修复生成的 pubspec.yaml 文件中的问题
class PubspecFixer {
  /// 从 pubspec.yaml 文件中读取版本号
  static Future<String?> readVersionFromPubspec(String pubspecPath) async {
    final file = File(pubspecPath);

    if (!await file.exists()) {
      return null;
    }

    try {
      final content = await file.readAsString();
      final yaml = loadYaml(content) as Map;
      return yaml['version'] as String?;
    } catch (e) {
      print('警告: 无法读取 pubspec.yaml 版本号: $e');
      return null;
    }
  }

  /// 修复 pubspec.yaml 文件
  ///
  /// 修复内容：
  /// 1. 确保 `resolution: workspace` 字段存在（用于 monorepo 工作区解析）
  /// 2. 如果提供了 expectedVersion，则更新版本号；否则保持现有版本号不变
  Future<void> fixPubspec({
    required String pubspecPath,
    String? expectedVersion,
  }) async {
    final file = File(pubspecPath);

    if (!await file.exists()) {
      print('警告: pubspec.yaml 文件不存在: $pubspecPath');
      return;
    }

    print('正在修复 pubspec.yaml: $pubspecPath');

    // 读取文件内容
    var content = await file.readAsString();

    // 确保 resolution: workspace 字段存在
    final resolutionPattern = RegExp(
      r'^resolution:\s*workspace\s*$',
      multiLine: true,
    );
    if (!resolutionPattern.hasMatch(content)) {
      print('添加 resolution: workspace 字段');
      // 在 name 字段后添加 resolution: workspace
      final namePattern = RegExp(r'^(name:\s*.+)$', multiLine: true);
      if (namePattern.hasMatch(content)) {
        content = content.replaceFirst(
          namePattern,
          r'$1\nresolution: workspace',
        );
      }
    }

    // 如果提供了期望版本号，更新版本号
    // 如果 expectedVersion 为 null，则保持现有版本号不变
    if (expectedVersion != null) {
      final versionPattern = RegExp(r'^version:\s*(.+)$', multiLine: true);
      final match = versionPattern.firstMatch(content);
      if (match != null) {
        final currentVersion = match.group(1)?.trim();
        if (currentVersion != expectedVersion) {
          print('更新版本号: $currentVersion -> $expectedVersion');
          content = content.replaceFirst(
            versionPattern,
            'version: $expectedVersion',
          );
        } else {
          print('版本号已正确: $expectedVersion');
        }
      } else {
        // 如果找不到 version 字段，在 resolution 字段后添加
        final resolutionPattern = RegExp(
          r'^(resolution:\s*workspace\s*)$',
          multiLine: true,
        );
        if (resolutionPattern.hasMatch(content)) {
          content = content.replaceFirst(
            resolutionPattern,
            r'$1\nversion: $expectedVersion',
          );
        } else {
          // 如果连 resolution 都没有，在 name 后添加
          final namePattern = RegExp(r'^(name:\s*.+)$', multiLine: true);
          if (namePattern.hasMatch(content)) {
            content = content.replaceFirst(
              namePattern,
              r'$1\nresolution: workspace\nversion: $expectedVersion',
            );
          }
        }
      }
    } else {
      // 不更新版本号，保持现有版本号
      final versionPattern = RegExp(r'^version:\s*(.+)$', multiLine: true);
      final match = versionPattern.firstMatch(content);
      if (match != null) {
        final currentVersion = match.group(1)?.trim();
        print('保持版本号不变: $currentVersion');
      } else {
        print('警告: 未找到版本号字段，且未提供期望版本号');
      }
    }

    // 写回文件
    await file.writeAsString(content);

    print('pubspec.yaml 修复完成');
  }
}
