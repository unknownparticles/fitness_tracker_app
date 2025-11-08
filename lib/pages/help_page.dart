import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('使用帮助'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 应用介绍
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.fitness_center, size: 32, color: Colors.blue),
                  const SizedBox(height: 8),
                  const Text(
                    'DeepSeek AI 健身计划',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '基于 DeepSeek AI 的个性化健身计划生成和管理应用，为您提供智能的健身指导和进度跟踪。',
                    style: TextStyle(fontSize: 14, color: Colors.blue),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 主要功能
          const Text(
            '主要功能',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildFeatureCard(
            context,
            '📋 个性化健身计划',
            '根据您的身高、体重、年龄、性别等信息，AI 自动生成适合您的每日健身计划',
            Icons.list_alt,
          ),
          _buildFeatureCard(
            context,
            '🏋️ 今日体重记录',
            '记录每日体重变化，跟踪健身效果',
            Icons.scale,
          ),
          _buildFeatureCard(
            context,
            '🤖 AI 智能分析',
            '基于完成情况和体重变化，获得专业的健身建议',
            Icons.insights,
          ),
          _buildFeatureCard(
            context,
            '✅ 进度跟踪',
            '勾选完成的训练项目，实时跟踪进度',
            Icons.check_circle,
          ),
          _buildFeatureCard(
            context,
            '🍽️ 饮食记录',
            '记录每日三餐和加餐内容，帮助管理饮食习惯',
            Icons.restaurant,
          ),
          _buildFeatureCard(
            context,
            '📋 建议食谱',
            'AI 根据个人信息生成个性化饮食建议，包含营养搭配和热量计算',
            Icons.restaurant_menu,
          ),
          const SizedBox(height: 16),

          // 使用步骤
          const Text(
            '使用步骤',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildStepCard(
            context,
            '1. 配置个人信息',
            '在设置页面填写身高、体重、出生年份、性别等基本信息',
            'settings',
          ),
          _buildStepCard(
            context,
            '2. 获取 DeepSeek API Key',
            '访问 DeepSeek 官网注册账号并获取 API Key（详见下方说明）',
            'key',
          ),
          _buildStepCard(
            context,
            '3. 生成健身计划',
            '点击主页"生成/刷新今日计划"按钮，AI 会根据您的信息生成个性化计划',
            'refresh',
          ),
          _buildStepCard(
            context,
            '4. 记录训练进度',
            '完成训练项目后勾选相应项目，记录今日体重',
            'checklist',
          ),
          _buildStepCard(
            context,
            '5. 记录饮食情况',
            '在饮食记录区域填写今日三餐和加餐内容，帮助跟踪饮食习惯',
            'restaurant',
          ),
          _buildStepCard(
            context,
            '6. 查看建议食谱',
            '生成健身计划时会同时生成个性化建议食谱，点击展开查看详细内容',
            'menu',
          ),
          _buildStepCard(
            context,
            '7. 获取 AI 分析',
            '点击"一键AI分析"获得基于完成情况和饮食记录的专业建议',
            'analytics',
          ),
          const SizedBox(height: 16),

          // 获取 API Key 指南
          const Text(
            '如何获取 DeepSeek API Key',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            color: Colors.green[50],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '步骤说明：',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  const SizedBox(height: 8),
                  const Text('1. 访问 DeepSeek 官网：https://deepseek.com'),
                  const SizedBox(height: 4),
                  const Text('2. 注册账号并登录'),
                  const SizedBox(height: 4),
                  const Text('3. 进入控制台或 API 管理页面'),
                  const SizedBox(height: 4),
                  const Text('4. 创建新的 API Key'),
                  const SizedBox(height: 4),
                  const Text('5. 复制 API Key 并粘贴到应用设置页面'),
                  const SizedBox(height: 12),
                  const Text(
                    '⚠️ 注意事项：',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 4),
                  const Text('• API Key 是敏感信息，请勿分享给他人'),
                  const SizedBox(height: 4),
                  const Text('• 建议定期更换 API Key'),
                  const SizedBox(height: 4),
                  const Text('• 如果 API Key 失效，请重新获取并更新'),
                  const SizedBox(height: 8),
                  const Text(
                    '💡 提示：您可以点击下方按钮复制官网链接',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 常见问题
          const Text(
            '常见问题',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildFAQCard(
            context,
            'Q: 为什么生成计划失败？',
            'A: 请检查以下几点：\n• 确认已正确配置 DeepSeek API Key\n• 检查网络连接是否正常\n• 确认个人信息填写完整',
          ),
          _buildFAQCard(
            context,
            'Q: API Key 无效怎么办？',
            'A: 请重新访问 DeepSeek 官网获取新的 API Key，并在设置页面更新',
          ),
          _buildFAQCard(
            context,
            'Q: 计划数据会保存吗？',
            'A: 是的，所有数据都会本地保存，重启应用后仍然存在',
          ),
          _buildFAQCard(
            context,
            'Q: 可以修改已生成的计划吗？',
            'A: 目前计划由 AI 生成，如需修改请重新生成新的计划',
          ),
          const SizedBox(height: 16),

          // 联系支持
          const Text(
            '联系支持',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            color: Colors.orange[50],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.support_agent, size: 32, color: Colors.orange),
                  const SizedBox(height: 8),
                  const Text(
                    '如果您遇到问题或有建议，请通过以下方式联系我们：',
                    style: TextStyle(color: Colors.orange),
                  ),
                  const SizedBox(height: 8),
                  const Text('• 检查应用更新'),
                  const Text('• 查看设置页面的帮助信息'),
                  const Text('• 重新配置 API Key'),
                  const SizedBox(height: 8),
                  Text(
                    'DeepSeek AI 健身计划 - 使用指南',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '应用会持续更新和改进，感谢您的使用！',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, String title, String description, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard(BuildContext context, String title, String description, String iconType) {
    IconData icon;
    Color color;
    
    switch (iconType) {
      case 'settings':
        icon = Icons.settings;
        color = Colors.blue;
        break;
      case 'key':
        icon = Icons.key;
        color = Colors.orange;
        break;
      case 'refresh':
        icon = Icons.refresh;
        color = Colors.green;
        break;
      case 'checklist':
        icon = Icons.checklist;
        color = Colors.purple;
        break;
      case 'analytics':
        icon = Icons.analytics;
        color = Colors.red;
        break;
      case 'restaurant':
        icon = Icons.restaurant;
        color = Colors.green;
        break;
      case 'menu':
        icon = Icons.restaurant_menu;
        color = Colors.orange;
        break;
      default:
        icon = Icons.circle;
        color = Colors.grey;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQCard(BuildContext context, String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 4),
            Text(
              answer,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
