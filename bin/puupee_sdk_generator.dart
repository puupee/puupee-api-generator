#!/usr/bin/env dart

/// Puupee SDK 生成器命令行工具
///
/// 使用示例：
/// ```bash
/// dart run puupee_sdk_generator build
/// dart run puupee_sdk_generator build --verbose
/// ```

import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:puupee_sdk_generator/puupee_sdk_generator.dart';

void main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag('verbose', abbr: 'v', help: '显示详细输出')
    ..addOption(
      'swagger-url',
      help: 'Swagger JSON URL',
      defaultsTo: 'https://dev.api.puupee.com/swagger/v1/swagger.json',
    )
    ..addOption('output-dir', help: '输出目录', defaultsTo: '../puupee_api_client')
    ..addFlag('help', abbr: 'h', help: '显示帮助信息');

  final results = parser.parse(args);

  if (results['help'] as bool || results.rest.isEmpty) {
    print('Puupee SDK 生成器');
    print('');
    print('用法: dart run puupee_sdk_generator <command> [选项]');
    print('');
    print('命令:');
    print('  build    构建所有支持的 SDK');
    print('  dart     仅构建 Dart SDK');
    print('  axios    仅构建 TypeScript Axios SDK');
    print('  go       仅构建 Go SDK');
    print('');
    print('选项:');
    print(parser.usage);
    exit(0);
  }

  final command = results.rest[0];
  final verbose = results['verbose'] as bool;
  final swaggerUrl = results['swagger-url'] as String;
  final outputDir = results['output-dir'] as String;

  try {
    switch (command) {
      case 'build':
        await buildAll(
          verbose: verbose,
          swaggerUrl: swaggerUrl,
          outputDir: outputDir,
        );
        break;
      case 'dart':
        await buildDart(
          verbose: verbose,
          swaggerUrl: swaggerUrl,
          outputDir: outputDir,
        );
        break;
      case 'axios':
        await buildAxios(verbose: verbose, swaggerUrl: swaggerUrl);
        break;
      case 'go':
        await buildGo(verbose: verbose, swaggerUrl: swaggerUrl);
        break;
      default:
        print('未知命令: $command');
        print('使用 --help 查看帮助信息');
        exit(1);
    }
  } catch (e, stackTrace) {
    stderr.writeln('错误: $e');
    if (verbose) {
      stderr.writeln('堆栈跟踪:');
      stderr.writeln(stackTrace);
    }
    exit(1);
  }
}

/// 构建所有支持的 SDK
Future<void> buildAll({
  required bool verbose,
  required String swaggerUrl,
  required String outputDir,
}) async {
  print('开始构建所有 SDK...');

  // 先构建 Dart
  await buildDart(
    verbose: verbose,
    swaggerUrl: swaggerUrl,
    outputDir: outputDir,
  );

  // 构建 Axios SDK
  await buildAxios(verbose: verbose, swaggerUrl: swaggerUrl);

  // 构建 Go SDK
  await buildGo(verbose: verbose, swaggerUrl: swaggerUrl);

  print('所有 SDK 构建完成');
}

/// 清理输出目录，但保留 .git 文件夹
Future<void> cleanOutputDirectory(String dirPath) async {
  final directory = Directory(dirPath);
  if (!await directory.exists()) {
    return;
  }

  print('清理输出目录: $dirPath');

  await for (final entity in directory.list()) {
    // 跳过 .git 文件夹
    if (path.basename(entity.path) == '.git') {
      continue;
    }

    // 删除其他所有文件和文件夹
    if (entity is File) {
      await entity.delete();
    } else if (entity is Directory) {
      await entity.delete(recursive: true);
    }
  }
}

/// 构建 Dart SDK
Future<void> buildDart({
  required bool verbose,
  required String swaggerUrl,
  required String outputDir,
}) async {
  // 获取当前脚本所在目录
  final scriptDir = path.dirname(Platform.script.toFilePath());
  final packageDir = path.dirname(scriptDir);

  final swaggerJsonPath = path.join(packageDir, 'swagger.json');
  final openApiGeneratorJar = path.join(
    packageDir,
    'openapi-generator-cli.jar',
  );
  final configPath = path.join(packageDir, 'configs', 'dart.json');
  final templateDirectory = path.join(
    packageDir,
    'templates',
    'dart',
    'libraries',
    'dio',
  );
  final versionLockPath = path.join(packageDir, 'version.lock');

  // 检查必要文件是否存在
  if (!await File(openApiGeneratorJar).exists()) {
    throw Exception('找不到 openapi-generator-cli.jar: $openApiGeneratorJar');
  }

  if (!await File(configPath).exists()) {
    throw Exception('找不到配置文件: $configPath');
  }

  // 1. 下载 Swagger JSON
  final downloader = SwaggerDownloader(swaggerUrl: swaggerUrl);
  final swaggerInfo = await downloader.download();
  await downloader.saveToFile(swaggerJsonPath, swaggerInfo.json);

  print('构建目标版本: ${swaggerInfo.version}');

  // 2. 清理输出目录
  final outputDirPath = path.absolute(outputDir);
  await cleanOutputDirectory(outputDirPath);

  // 3. 生成 Dart SDK
  final generator = SdkGenerator(
    openApiGeneratorJar: openApiGeneratorJar,
    swaggerJsonPath: swaggerJsonPath,
    configPath: configPath,
    templateDirectory: templateDirectory,
    outputDirectory: outputDirPath,
    version: swaggerInfo.version,
    gitUserId: 'puupee',
    gitRepoId: 'puupee-api-dart',
    skipValidateSpec: true,
  );

  await generator.generateDart();

  // 4. 修复生成的 pubspec.yaml
  final pubspecPath = path.join(outputDirPath, 'pubspec.yaml');
  final fixer = PubspecFixer();
  await fixer.fixPubspec(
    pubspecPath: pubspecPath,
    expectedVersion: swaggerInfo.version,
  );

  // 5. 安装依赖
  print('安装依赖...');
  final pubGetProcess = await Process.start(
    'dart',
    ['pub', 'get'],
    workingDirectory: outputDirPath,
    runInShell: false,
  );
  await stdout.addStream(pubGetProcess.stdout);
  await stderr.addStream(pubGetProcess.stderr);
  final pubGetExitCode = await pubGetProcess.exitCode;
  if (pubGetExitCode != 0) {
    throw Exception('安装依赖失败，退出码: $pubGetExitCode');
  }

  // 6. 运行 build_runner 生成代码
  print('运行 build_runner 生成代码...');
  final buildRunnerProcess = await Process.start(
    'dart',
    ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
    workingDirectory: outputDirPath,
    runInShell: false,
  );
  await stdout.addStream(buildRunnerProcess.stdout);
  await stderr.addStream(buildRunnerProcess.stderr);
  final buildRunnerExitCode = await buildRunnerProcess.exitCode;
  if (buildRunnerExitCode != 0) {
    throw Exception('运行 build_runner 失败，退出码: $buildRunnerExitCode');
  }

  // 7. 保存版本锁
  print('保存版本锁到: $versionLockPath');
  await File(versionLockPath).writeAsString(swaggerInfo.version);

  print('Dart SDK 构建完成！版本: ${swaggerInfo.version}');
}

/// 构建 TypeScript Axios SDK
Future<void> buildAxios({
  required bool verbose,
  required String swaggerUrl,
}) async {
  // 获取当前脚本所在目录
  final scriptDir = path.dirname(Platform.script.toFilePath());
  final packageDir = path.dirname(scriptDir);

  final swaggerJsonPath = path.join(packageDir, 'swagger.json');
  final openApiGeneratorJar = path.join(
    packageDir,
    'openapi-generator-cli.jar',
  );
  final configPath = path.join(packageDir, 'configs', 'axios.json');
  final outputDir = path.absolute('../../../sdk/puupee-api-axios');
  final versionLockPath = path.join(packageDir, 'version.lock');

  // 检查必要文件是否存在
  if (!await File(openApiGeneratorJar).exists()) {
    throw Exception('找不到 openapi-generator-cli.jar: $openApiGeneratorJar');
  }

  if (!await File(configPath).exists()) {
    throw Exception('找不到配置文件: $configPath');
  }

  // 1. 下载 Swagger JSON
  final downloader = SwaggerDownloader(swaggerUrl: swaggerUrl);
  final swaggerInfo = await downloader.download();
  await downloader.saveToFile(swaggerJsonPath, swaggerInfo.json);

  print('构建目标版本: ${swaggerInfo.version}');

  // 2. 清理输出目录
  await cleanOutputDirectory(outputDir);

  // 3. 生成 TypeScript Axios SDK
  final generator = SdkGenerator(
    openApiGeneratorJar: openApiGeneratorJar,
    swaggerJsonPath: swaggerJsonPath,
    configPath: configPath,
    templateDirectory: '', // Axios 不需要自定义模板
    outputDirectory: outputDir,
    version: swaggerInfo.version,
    gitUserId: 'puupee',
    gitRepoId: 'puupee-api-axios',
    skipValidateSpec: true,
  );

  await generator.generate(
    generator: 'typescript-axios',
    outputDir: outputDir,
    configFile: configPath,
  );

  // 4. 安装依赖
  print('安装依赖...');
  final yarnProcess = await Process.start(
    'yarn',
    ['install'],
    workingDirectory: outputDir,
    runInShell: false,
  );
  await stdout.addStream(yarnProcess.stdout);
  await stderr.addStream(yarnProcess.stderr);
  final yarnExitCode = await yarnProcess.exitCode;
  if (yarnExitCode != 0) {
    throw Exception('安装依赖失败，退出码: $yarnExitCode');
  }

  // 5. 保存版本锁
  print('保存版本锁到: $versionLockPath');
  await File(versionLockPath).writeAsString(swaggerInfo.version);

  print('TypeScript Axios SDK 构建完成！版本: ${swaggerInfo.version}');
}

/// 构建 Go SDK
Future<void> buildGo({
  required bool verbose,
  required String swaggerUrl,
}) async {
  // 获取当前脚本所在目录
  final scriptDir = path.dirname(Platform.script.toFilePath());
  final packageDir = path.dirname(scriptDir);

  final swaggerJsonPath = path.join(packageDir, 'swagger.json');
  final openApiGeneratorJar = path.join(
    packageDir,
    'openapi-generator-cli.jar',
  );
  final configPath = path.join(packageDir, 'configs', 'go.json');
  final outputDir = path.absolute('../../../sdk/puupee-api-go');
  final versionLockPath = path.join(packageDir, 'version.lock');

  // 检查必要文件是否存在
  if (!await File(openApiGeneratorJar).exists()) {
    throw Exception('找不到 openapi-generator-cli.jar: $openApiGeneratorJar');
  }

  if (!await File(configPath).exists()) {
    throw Exception('找不到配置文件: $configPath');
  }

  // 1. 下载 Swagger JSON
  final downloader = SwaggerDownloader(swaggerUrl: swaggerUrl);
  final swaggerInfo = await downloader.download();
  await downloader.saveToFile(swaggerJsonPath, swaggerInfo.json);

  print('构建目标版本: ${swaggerInfo.version}');

  // 2. 清理输出目录
  await cleanOutputDirectory(outputDir);

  // 3. 生成 Go SDK
  final generator = SdkGenerator(
    openApiGeneratorJar: openApiGeneratorJar,
    swaggerJsonPath: swaggerJsonPath,
    configPath: configPath,
    templateDirectory: '', // Go 不需要自定义模板
    outputDirectory: outputDir,
    version: swaggerInfo.version,
    gitUserId: 'puupee',
    gitRepoId: 'puupee-api-go',
    skipValidateSpec: false, // Go 不需要跳过验证
  );

  await generator.generate(
    generator: 'go',
    outputDir: outputDir,
    configFile: configPath,
  );

  // 4. 运行 go mod tidy
  print('运行 go mod tidy...');
  final goModTidyProcess = await Process.start(
    'go',
    ['mod', 'tidy'],
    workingDirectory: outputDir,
    runInShell: false,
  );
  await stdout.addStream(goModTidyProcess.stdout);
  await stderr.addStream(goModTidyProcess.stderr);
  final goModTidyExitCode = await goModTidyProcess.exitCode;
  if (goModTidyExitCode != 0) {
    throw Exception('go mod tidy 失败，退出码: $goModTidyExitCode');
  }

  // 5. 保存版本锁
  print('保存版本锁到: $versionLockPath');
  await File(versionLockPath).writeAsString(swaggerInfo.version);

  print('Go SDK 构建完成！版本: ${swaggerInfo.version}');
}
