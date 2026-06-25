import 'dart:convert';
import 'dart:io';

import 'package:felorx_sdk_generator/felorx_sdk_generator.dart';
import 'package:test/test.dart';

void main() {
  test('local swagger download makes duplicate operationIds unique', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'felorx_swagger_downloader_test_',
    );
    addTearDown(() => tempDir.delete(recursive: true));

    final swaggerFile = File('${tempDir.path}/swagger.json');
    await swaggerFile.writeAsString(
      jsonEncode({
        'openapi': '3.0.1',
        'info': {'title': 'Felorx API', 'version': '1.0.0'},
        'paths': {
          '/api/app/account': {
            'get': {
              'tags': ['Account'],
              'operationId': 'GetAccount',
              'responses': {
                '200': {'description': 'OK'},
              },
            },
          },
          '/api/app/credit/account/{appId}': {
            'get': {
              'tags': ['Credit'],
              'operationId': 'GetAccount',
              'responses': {
                '200': {'description': 'OK'},
              },
            },
          },
        },
      }),
    );

    final info = await SwaggerDownloader(
      swaggerUrl: swaggerFile.path,
    ).download();
    final swagger = jsonDecode(info.json) as Map<String, dynamic>;
    final paths = swagger['paths'] as Map<String, dynamic>;
    final accountOperation =
        (paths['/api/app/account'] as Map<String, dynamic>)['get']
            as Map<String, dynamic>;
    final creditOperation =
        (paths['/api/app/credit/account/{appId}']
                as Map<String, dynamic>)['get']
            as Map<String, dynamic>;

    expect(info.version, '1.0.0');
    expect(accountOperation['operationId'], 'GetAccount');
    expect(creditOperation['operationId'], 'CreditGetAccount');
  });
}
