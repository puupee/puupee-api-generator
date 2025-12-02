import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Swagger 下载器
class SwaggerDownloader {
  final String swaggerUrl;

  SwaggerDownloader({this.swaggerUrl = 'https://dev.api.puupee.com/swagger/v1/swagger.json'});

  /// 下载 Swagger JSON
  Future<SwaggerInfo> download() async {
    print('正在从 $swaggerUrl 下载 Swagger JSON...');
    
    final response = await http.get(Uri.parse(swaggerUrl));
    
    if (response.statusCode != 200) {
      throw Exception('下载 Swagger JSON 失败: HTTP ${response.statusCode}');
    }

    final swaggerJson = utf8.decode(response.bodyBytes);
    
    // 解析版本信息
    final swagger = jsonDecode(swaggerJson) as Map<String, dynamic>;
    final info = swagger['info'] as Map<String, dynamic>;
    final version = info['version'] as String;
    
    print('检测到版本: $version');
    
    return SwaggerInfo(
      json: swaggerJson,
      version: version,
    );
  }

  /// 保存 Swagger JSON 到文件
  Future<void> saveToFile(String filePath, String content) async {
    final file = File(filePath);
    await file.writeAsString(content);
    print('已保存 Swagger JSON 到: $filePath');
  }
}

/// Swagger 信息
class SwaggerInfo {
  final String json;
  final String version;

  SwaggerInfo({
    required this.json,
    required this.version,
  });
}

