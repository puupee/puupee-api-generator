# Puupee SDK Generator

一个用于生成 Puupee API 客户端代码的工具，支持多种编程语言。

## 功能

- 从远程 API 下载 Swagger JSON 规范
- 自动解析版本号
- 使用 OpenAPI Generator 生成客户端代码
- 支持多种编程语言：Dart、TypeScript (Axios)、Go
- 自动修复生成的 pubspec.yaml 文件（确保 `resolution: workspace` 字段存在，确保版本号正确）
- 自动运行 `dart run build_runner build --delete-conflicting-outputs` 生成 Dart 序列化代码
- 自动安装依赖（Dart: `dart pub get`，TypeScript: `yarn install`，Go: `go mod tidy`）

## 安装

```bash
cd packages/puupee_sdk_generator
dart pub get
```

## 使用方法

### 构建 Dart SDK

```bash
dart run bin/puupee_sdk_generator.dart dart
```

### 构建 TypeScript Axios SDK

```bash
dart run bin/puupee_sdk_generator.dart axios
```

### 构建 Go SDK

```bash
dart run bin/puupee_sdk_generator.dart go
```

### 构建所有支持的 SDK

```bash
dart run bin/puupee_sdk_generator.dart build
```

### 选项

- `--verbose` / `-v`: 显示详细输出
- `--swagger-url <url>`: 指定 Swagger JSON URL（默认: https://dev.api.puupee.com/swagger/v1/swagger.json）
- `--output-dir <dir>`: 指定输出目录
  - `dart` 命令默认: `../puupee_api_client`
  - `axios` 命令默认: `../puupee-api-axios`
  - `go` 命令默认: `../puupee-api-go`

### 示例

```bash
# 使用默认设置构建 Dart SDK
dart run bin/puupee_sdk_generator.dart dart

# 构建 TypeScript Axios SDK
dart run bin/puupee_sdk_generator.dart axios

# 构建 Go SDK
dart run bin/puupee_sdk_generator.dart go

# 构建所有 SDK
dart run bin/puupee_sdk_generator.dart build

# 使用自定义 URL 和输出目录
dart run bin/puupee_sdk_generator.dart dart \
  --swagger-url https://api.puupee.com/swagger/v1/swagger.json \
  --output-dir ../my_api_client

# 使用自定义输出目录构建 Axios SDK
dart run bin/puupee_sdk_generator.dart axios \
  --output-dir ../my_axios_client

# 使用自定义输出目录构建 Go SDK
dart run bin/puupee_sdk_generator.dart go \
  --output-dir ../my_go_client

# 显示详细输出
dart run bin/puupee_sdk_generator.dart build --verbose
```

## 修复的问题

### 版本号问题

生成的 `pubspec.yaml` 文件中的版本号现在会正确对应 Swagger JSON 中的版本号。

### resolution 字段问题

生成的 `pubspec.yaml` 文件中会确保包含 `resolution: workspace` 字段（用于 monorepo 工作区解析）。

## 开发

### 项目结构

```
puupee_sdk_generator/
├── bin/
│   └── puupee_sdk_generator.dart  # 命令行入口
├── lib/
│   ├── puupee_sdk_generator.dart  # 库导出
│   └── src/
│       ├── generator.dart         # SDK 生成器
│       ├── swagger_downloader.dart # Swagger 下载器
│       └── pubspec_fixer.dart     # Pubspec 修复器
├── configs/                       # OpenAPI Generator 配置
├── templates/                     # 代码生成模板
└── pubspec.yaml
```

## 依赖

- `args`: 命令行参数解析
- `http`: HTTP 客户端
- `yaml`: YAML 解析
