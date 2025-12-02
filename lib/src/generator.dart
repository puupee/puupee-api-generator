import 'dart:io';

/// SDK 生成器
class SdkGenerator {
  final String openApiGeneratorJar;
  final String swaggerJsonPath;
  final String configPath;
  final String templateDirectory;
  final String outputDirectory;
  final String version;
  final String gitUserId;
  final String gitRepoId;
  final bool skipValidateSpec;

  SdkGenerator({
    required this.openApiGeneratorJar,
    required this.swaggerJsonPath,
    required this.configPath,
    required this.templateDirectory,
    required this.outputDirectory,
    required this.version,
    this.gitUserId = 'puupee',
    this.gitRepoId = 'puupee-api-dart',
    this.skipValidateSpec = true,
  });

  /// 生成 Dart SDK
  Future<void> generateDart() async {
    print('正在生成 Dart SDK...');
    
    final args = [
      '-jar',
      openApiGeneratorJar,
      'generate',
      '-g',
      'dart-dio',
      '-o',
      outputDirectory,
      '-c',
      configPath,
      '-t',
      templateDirectory,
      '-i',
      swaggerJsonPath,
      '--git-user-id',
      gitUserId,
      '--git-repo-id',
      gitRepoId,
      '--release-note',
      'update',
      '--artifact-version',
      version,
    ];

    if (skipValidateSpec) {
      args.add('--skip-validate-spec');
    }

    final process = await Process.start(
      'java',
      args,
      runInShell: false,
    );

    // 输出标准输出和标准错误
    await stdout.addStream(process.stdout);
    await stderr.addStream(process.stderr);

    final exitCode = await process.exitCode;
    
    if (exitCode != 0) {
      throw Exception('生成 Dart SDK 失败，退出码: $exitCode');
    }

    print('Dart SDK 生成完成');
  }

  /// 生成其他语言的 SDK（如 Go、TypeScript 等）
  Future<void> generate({
    required String generator,
    required String outputDir,
    required String configFile,
    String? templateDir,
  }) async {
    print('正在生成 $generator SDK...');
    
    final args = [
      '-jar',
      openApiGeneratorJar,
      'generate',
      '-g',
      generator,
      '-o',
      outputDir,
      '-c',
      configFile,
      '-i',
      swaggerJsonPath,
      '--git-user-id',
      gitUserId,
      '--git-repo-id',
      gitRepoId,
      '--release-note',
      'update',
      '--artifact-version',
      version,
    ];

    if (templateDir != null) {
      args.addAll(['-t', templateDir]);
    }

    if (skipValidateSpec) {
      args.add('--skip-validate-spec');
    }

    final process = await Process.start(
      'java',
      args,
      runInShell: false,
    );

    await stdout.addStream(process.stdout);
    await stderr.addStream(process.stderr);

    final exitCode = await process.exitCode;
    
    if (exitCode != 0) {
      throw Exception('生成 $generator SDK 失败，退出码: $exitCode');
    }

    print('$generator SDK 生成完成');
  }
}

