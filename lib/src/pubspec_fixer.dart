import 'dart:io';

/// Pubspec 修复器
/// 修复生成的 pubspec.yaml 文件中的问题
class PubspecFixer {
  /// 修复 pubspec.yaml 文件
  /// 
  /// 修复内容：
  /// 1. 确保 `resolution: workspace` 字段存在（用于 monorepo 工作区解析）
  /// 2. 确保版本号正确对应 Swagger JSON 中的版本号
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
    final resolutionPattern = RegExp(r'^resolution:\s*workspace\s*$', multiLine: true);
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
        final resolutionPattern = RegExp(r'^(resolution:\s*workspace\s*)$', multiLine: true);
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
    }

    // 写回文件
    await file.writeAsString(content);
    
    print('pubspec.yaml 修复完成');
  }
}

