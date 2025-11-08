# DeepSeek AI 健身计划

一个基于 DeepSeek Chat API 的 Flutter 健身计划管理应用，支持自动生成个性化健身计划和 AI 分析建议。

## 功能特性

### 🏋️ 核心功能
- **个性化健身计划生成**：基于身高、体重、年龄、性别自动生成每日训练计划
- **计划进度跟踪**：可勾选的训练项目，支持本地持久化
- **体重记录管理**：每日体重记录，支持历史数据对比
- **AI 智能分析**：基于完成率和体重变化提供专业建议
- **离线可用**：除调用 DeepSeek API 外，所有数据本地存储

### 🎯 用户体验
- **极简界面**：Material3 设计，操作简单直观
- **数据隔离**：按日期隔离计划和体重数据
- **实时反馈**：加载状态、错误提示、操作反馈
- **年龄自动计算**：根据出生年份自动计算并随年份更新

## 技术规格

### 依赖库
- `http`: ^1.2.1 - 网络请求
- `shared_preferences`: ^2.2.3 - 本地数据存储
- Flutter SDK: ^3.6.2

### 支持平台
- Android (API 21+)
- iOS (12.0+)

### 数据存储
所有数据使用 SharedPreferences 本地存储，键名规范：

**用户资料**
- `profile.height_cm` - 身高（厘米）
- `profile.weight_kg` - 体重（公斤）
- `profile.birth_year` - 出生年份
- `profile.gender` - 性别（male/female/other）
- `profile.ds_key` - DeepSeek API Key

**每日数据（按日期隔离）**
- `today.weight_YYYYMMDD` - 当日体重
- `plan.json_YYYYMMDD` - 训练计划 JSON
- `plan.checked_YYYYMMDD` - 勾选状态（逗号分隔的 0/1 字符串）

## 快速开始

### 1. 安装依赖
```bash
cd fitness_tracker_app
flutter pub get
```

### 2. 配置 DeepSeek API
1. 访问 [DeepSeek 官网](https://deepseek.com) 注册账号
2. 获取 API Key
3. 在应用设置页填写 API Key

### 3. 运行应用
```bash
# Android
flutter run

# iOS
flutter run -d ios

# 指定设备
flutter run -d <设备ID>
```

## 使用指南

### 首次使用
1. **完善个人信息**：进入设置页填写身高、体重、出生年份、性别
2. **配置 API Key**：输入 DeepSeek API Key
3. **开始使用**：返回主页生成今日健身计划

### 日常使用流程
1. **记录今日体重**：在主页输入今日体重并保存
2. **生成训练计划**：点击"生成/刷新今日计划"
3. **跟踪训练进度**：完成训练项目后勾选对应条目
4. **获取 AI 建议**：点击"一键AI分析"查看专业建议

### 数据管理
- **计划持久化**：今日计划和勾选状态自动保存
- **体重记录**：每日体重独立保存，支持历史对比
- **数据隔离**：不同日期的数据完全隔离，互不影响

## API 集成

### DeepSeek API 配置
- **Base URL**: `https://api.deepseek.com`
- **模型**: `deepseek-chat`
- **超时**: 10 秒（可重试 1 次）

### Prompt 设计

#### A. 生成健身计划
系统指令确保返回严格 JSON 格式：
```json
{
  "date": "YYYY-MM-DD",
  "total_minutes": 45,
  "items": [
    { "title": "热身慢跑", "minutes": 8, "note": "心率上到120-130" },
    { "title": "俯卧撑", "minutes": 10, "note": "3组×12次，组间休息60秒" }
  ]
}
```

#### B. AI 分析建议
基于完成率和体重变化，返回 ≤100 字的专业建议。

### 错误处理
- **Key 缺失/无效**：友好提示用户检查 API Key
- **网络超时**：提示检查网络连接
- **API 限制**：429 状态码提示调用频率限制
- **服务器错误**：5xx 状态码提示服务器繁忙

## 项目结构

```
lib/
├── main.dart                 # 应用入口
├── pages/
│   ├── home_page.dart        # 主页（健身计划管理）
│   └── settings_page.dart    # 设置页（个人信息配置）
└── services/
    ├── storage_service.dart  # 本地存储服务
    └── deepseek_service.dart # DeepSeek API 服务
```

## 已知限制

1. **网络依赖**：生成计划和 AI 分析需要网络连接
2. **API 配额**：DeepSeek API 可能有调用频率限制
3. **数据本地化**：所有数据仅保存在本地设备
4. **单用户**：当前版本仅支持单用户配置

## 开发与维护

### 构建 APK
```bash
flutter build apk --release
```

### 构建 IPA
```bash
flutter build ipa --release
```

### 代码规范
- 使用 null safety
- 遵循 Dart 代码风格
- 统一使用 Material3 组件
- 错误处理使用 try-catch 包装

## 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

## 贡献

欢迎提交 Issue 和 Pull Request 来改进这个项目！

## 联系方式

如有问题或建议，请通过 GitHub Issues 联系我们。
# fitness_tracker_app
