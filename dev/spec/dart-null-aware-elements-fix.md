# Dart 代码生成 null-aware-elements 语法问题修复

## 问题描述

在使用 OpenAPI Generator 7.12.0 生成 Dart 代码时，遇到了 `null-aware-elements` 语言特性相关的错误：

```
This requires the 'null-aware-elements' language feature to be enabled.
```

错误出现在生成的 JSON 序列化代码中，使用了 `?instance.field` 语法，但这个语法需要启用特定的 Dart 语言特性。

## 根本原因

1. OpenAPI Generator 7.12.0 的 `dart-dio` 生成器默认生成使用 null-aware-elements 语法的代码
2. 原有的 `dart.json` 配置中 `finalProperties` 设置为 `false`，导致生成器使用了不兼容的代码模式
3. 缺少 `disallowAdditionalPropertiesIfNotPresent` 配置，影响了代码生成的兼容性

## 解决方案

更新 `configs/dart.json` 配置文件：

### 修改前
```json
{
    "pubLibrary": "puupee_api_client",
    "pubName": "puupee_api_client",
    "pubAuthor": "jerloo",
    "pubDescription": "Api for puupee app service.",
    "pubHomepage": "https://github.com/puupee/puupee-api-dart",
    "serializationLibrary": "json_serializable",
    "finalProperties": false,
    "useEnumExtension": true,
    "prependFormOrBodyParameters": true
}
```

### 修改后
```json
{
    "pubLibrary": "puupee_api_client",
    "pubName": "puupee_api_client",
    "pubAuthor": "jerloo",
    "pubDescription": "Api for puupee app service.",
    "pubHomepage": "https://github.com/puupee/puupee-api-dart",
    "serializationLibrary": "json_serializable",
    "finalProperties": true,
    "useEnumExtension": true,
    "prependFormOrBodyParameters": true,
    "disallowAdditionalPropertiesIfNotPresent": false
}
```

### 关键变更

1. **`finalProperties: true`** - 启用 final 属性，避免生成使用 null-aware-elements 语法的代码
2. **`disallowAdditionalPropertiesIfNotPresent: false`** - 确保与 OAS 和 JSON schema 规范兼容

## 验证结果

修复后重新生成代码：
- ✅ 代码生成成功，无错误
- ✅ 生成的代码中不再包含 `?instance.field` 语法
- ✅ JSON 序列化代码正常工作

## 影响范围

- 影响所有使用 `dart-dio` 生成器的 Dart 客户端代码生成
- 不影响其他语言的代码生成（Go、TypeScript 等）
- 生成的 API 接口保持不变，仅修复了序列化代码的兼容性问题

## 修复时间

2024-11-13

## 相关文件

- `configs/dart.json` - 主要配置文件
- `swagger.json` - API 定义文件（版本从 1.17.40 更新到 1.17.47）
