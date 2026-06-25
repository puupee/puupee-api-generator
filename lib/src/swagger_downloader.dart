import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Swagger 下载器
class SwaggerDownloader {
  final String swaggerUrl;

  SwaggerDownloader({
    this.swaggerUrl = 'https://dev.api.felorx.com/swagger/v1/swagger.json',
  });

  /// 下载或读取本地 Swagger JSON
  Future<SwaggerInfo> download() async {
    final String swaggerJson;
    if (swaggerUrl.startsWith('http://') || swaggerUrl.startsWith('https://')) {
      print('正在从 $swaggerUrl 下载 Swagger JSON...');

      final response = await http.get(Uri.parse(swaggerUrl));

      if (response.statusCode != 200) {
        throw Exception('下载 Swagger JSON 失败: HTTP ${response.statusCode}');
      }

      swaggerJson = utf8.decode(response.bodyBytes);
    } else {
      final filePath = swaggerUrl.startsWith('file:')
          ? Uri.parse(swaggerUrl).toFilePath()
          : swaggerUrl;
      print('正在从本地文件读取 Swagger JSON: $filePath');
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Swagger JSON 文件不存在: $filePath');
      }
      swaggerJson = await file.readAsString();
    }

    final swagger = jsonDecode(swaggerJson) as Map<String, dynamic>;
    final renamedOperationCount = _makeOperationIdsUnique(swagger);
    final info = swagger['info'] as Map<String, dynamic>;
    final version = info['version'] as String;
    final normalizedJson = renamedOperationCount == 0
        ? swaggerJson
        : const JsonEncoder.withIndent('  ').convert(swagger);

    print('检测到版本: $version');
    if (renamedOperationCount > 0) {
      print('已重命名 $renamedOperationCount 个重复 operationId');
    }

    return SwaggerInfo(json: normalizedJson, version: version);
  }

  /// 保存 Swagger JSON 到文件
  Future<void> saveToFile(String filePath, String content) async {
    final file = File(filePath);
    await file.writeAsString(content);
    print('已保存 Swagger JSON 到: $filePath');
  }
}

const _httpMethods = {
  'delete',
  'get',
  'head',
  'options',
  'patch',
  'post',
  'put',
  'trace',
};

int _makeOperationIdsUnique(Map<String, dynamic> swagger) {
  final paths = swagger['paths'];
  if (paths is! Map) {
    return 0;
  }

  final usedOperationIds = <String>{};
  var renamedCount = 0;

  for (final pathEntry in paths.entries) {
    final path = pathEntry.key.toString();
    final pathItem = pathEntry.value;
    if (pathItem is! Map) {
      continue;
    }

    for (final operationEntry in pathItem.entries) {
      final method = operationEntry.key.toString().toLowerCase();
      if (!_httpMethods.contains(method)) {
        continue;
      }

      final operation = operationEntry.value;
      if (operation is! Map) {
        continue;
      }

      final operationId = operation['operationId'];
      if (operationId is! String || operationId.trim().isEmpty) {
        continue;
      }

      if (usedOperationIds.add(operationId)) {
        continue;
      }

      final uniqueOperationId = _buildUniqueOperationId(
        operation: operation,
        operationId: operationId,
        method: method,
        path: path,
        usedOperationIds: usedOperationIds,
      );
      operation['operationId'] = uniqueOperationId;
      usedOperationIds.add(uniqueOperationId);
      renamedCount++;
    }
  }

  return renamedCount;
}

String _buildUniqueOperationId({
  required Map operation,
  required String operationId,
  required String method,
  required String path,
  required Set<String> usedOperationIds,
}) {
  final baseName = _toPascalCase(operationId);
  final tagScope = _tagScope(operation);
  final pathScope = _pathScope(path);
  final candidates = [
    _joinPascal([tagScope, baseName]),
    _joinPascal([pathScope, baseName]),
    _joinPascal([_toPascalCase(method), pathScope, baseName]),
  ].where((candidate) => candidate.isNotEmpty && candidate != operationId);

  for (final candidate in candidates) {
    if (!usedOperationIds.contains(candidate)) {
      return candidate;
    }
  }

  final fallbackPrefix = tagScope.isNotEmpty ? tagScope : pathScope;
  final fallbackBase = _joinPascal([fallbackPrefix, baseName]);
  var index = 2;
  while (true) {
    final candidate = '$fallbackBase$index';
    if (!usedOperationIds.contains(candidate)) {
      return candidate;
    }
    index++;
  }
}

String _tagScope(Map operation) {
  final tags = operation['tags'];
  if (tags is! List || tags.isEmpty) {
    return '';
  }

  final firstTag = tags.first;
  if (firstTag is! String) {
    return '';
  }

  return _toPascalCase(firstTag);
}

String _pathScope(String path) {
  const ignoredSegments = {'api', 'app'};
  final segments = path
      .split('/')
      .map((segment) => segment.trim())
      .where((segment) => segment.isNotEmpty)
      .where((segment) => !segment.startsWith('{'))
      .where((segment) => !RegExp(r'^v\d+$').hasMatch(segment))
      .where((segment) => !ignoredSegments.contains(segment))
      .map(_toPascalCase)
      .where((segment) => segment.isNotEmpty)
      .toList();

  if (segments.length <= 2) {
    return segments.join();
  }

  return segments.sublist(segments.length - 2).join();
}

String _joinPascal(Iterable<String> parts) {
  return parts.where((part) => part.isNotEmpty).join();
}

String _toPascalCase(String value) {
  final words = RegExp(r'[A-Za-z0-9]+')
      .allMatches(value)
      .map((match) => match.group(0)!)
      .where((word) => word.isNotEmpty)
      .toList();

  return words.map((word) {
    if (word.length == 1) {
      return word.toUpperCase();
    }
    return word[0].toUpperCase() + word.substring(1);
  }).join();
}

/// Swagger 信息
class SwaggerInfo {
  final String json;
  final String version;

  SwaggerInfo({required this.json, required this.version});
}
