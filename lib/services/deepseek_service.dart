import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'storage_service.dart';
import 'dart:developer' as developer;

/// DeepSeek API 响应数据模型
class FitnessPlan {
  final String date;
  final int totalMinutes;
  final List<PlanItem> items;

  FitnessPlan({
    required this.date,
    required this.totalMinutes,
    required this.items,
  });

  factory FitnessPlan.fromJson(Map<String, dynamic> json) {
    return FitnessPlan(
      date: json['date'],
      totalMinutes: json['total_minutes'],
      items: List<PlanItem>.from(json['items'].map((item) => PlanItem.fromJson(item))),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'total_minutes': totalMinutes,
        'items': items.map((item) => item.toJson()).toList(),
      };
}

class PlanItem {
  final String title;
  final int minutes;
  final String note;

  PlanItem({
    required this.title,
    required this.minutes,
    required this.note,
  });

  factory PlanItem.fromJson(Map<String, dynamic> json) {
    return PlanItem(
      title: json['title'],
      minutes: json['minutes'],
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'minutes': minutes,
        'note': note,
      };
}

/// DeepSeek API 服务类
class DeepSeekService {
  static const String _baseUrl = 'https://api.deepseek.com/v1';
  static const String _model = 'deepseek-chat';
  
  final StorageService _storageService;

  DeepSeekService(this._storageService);

  /// 生成今日健身计划
  Future<FitnessPlan?> generateFitnessPlan({
    required double height,
    required double weight,
    required int age,
    required String gender,
    String experienceLevel = 'beginner',
    String goal = 'general_fitness',
  }) async {
    developer.log('开始生成健身计划: 身高=$height, 体重=$weight, 年龄=$age, 性别=$gender', name: 'DeepSeekService');
    
    final apiKey = _storageService.getDsKey();
    final trimmedApiKey = apiKey.trim();
    
    if (trimmedApiKey.isEmpty) {
      developer.log('API Key 为空', name: 'DeepSeekService');
      throw Exception('请先在设置页填写 DeepSeek API Key');
    }
    
    if (trimmedApiKey.length < 10) {
      developer.log('API Key 长度过短: ${trimmedApiKey.length}', name: 'DeepSeekService');
      throw Exception('API Key 格式不正确，请检查后重新输入');
    }
    
    developer.log('API Key 长度: ${trimmedApiKey.length}', name: 'DeepSeekService');

    final prompt = '''
你是一名专业体能教练。基于用户的身高(cm)、体重(kg)、年龄、性别与可执行时长，为今天制定训练清单。仅输出严格 JSON，不要多余文本。动作选择以徒手/基础器械为主，安全优先，强度适中，避免超量。总时长 ≤ 60 分钟，至少包含 4 个条目（热身、主训练x2-3、拉伸收尾）。

用户信息：
- height_cm: $height
- weight_kg: $weight
- age: $age
- gender: $gender
- experience_level: $experienceLevel
- goal: $goal

请严格按照以下 JSON 格式输出：
{
  "date": "YYYY-MM-DD",
  "total_minutes": 45,
  "items": [
    { "title": "热身慢跑", "minutes": 8, "note": "心率上到120-130" },
    { "title": "俯卧撑", "minutes": 10, "note": "3组×12次，组间休息60秒" },
    { "title": "深蹲", "minutes": 12, "note": "3组×15次，组间休息60秒" },
    { "title": "平板支撑", "minutes": 5, "note": "3组×45秒" },
    { "title": "拉伸放松", "minutes": 10, "note": "腿后腱/股四头肌/胸背" }
  ]
}
''';
    
    developer.log('构建请求参数', name: 'DeepSeekService');

    try {
      developer.log('开始发送 API 请求到 $_baseUrl/chat/completions', name: 'DeepSeekService');
      final response = await http
          .post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $trimmedApiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'max_tokens': 1000,
          'temperature': 0.7,
        }),
      )
          .timeout(const Duration(seconds: 10));

      developer.log('API 响应状态码: ${response.statusCode}', name: 'DeepSeekService');
      developer.log('API 响应内容: ${response.body}', name: 'DeepSeekService');

      if (response.statusCode != 200) {
        developer.log('API 请求失败，状态码: ${response.statusCode}', name: 'DeepSeekService');
        developer.log('API 错误详情: ${response.body}', name: 'DeepSeekService');
        
        // 尝试解析错误响应
        try {
          final errorData = jsonDecode(response.body);
          if (errorData.containsKey('error')) {
            final errorMessage = errorData['error']['message'] ?? '未知错误';
            if (errorMessage.contains('Authentication Fails') || errorMessage.contains('invalid')) {
              throw Exception('API Key 无效或格式不正确，请检查后重新输入');
            }
            throw Exception('API 错误: $errorMessage');
          }
        } catch (e) {
          // 如果无法解析错误响应，则使用默认错误消息
          throw Exception('API 请求失败: ${response.statusCode}, 响应: ${response.body}');
        }
      }

      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      developer.log('AI 响应内容长度: ${content.length} 字符', name: 'DeepSeekService');
      
      // 尝试解析 JSON
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (jsonMatch == null) {
        developer.log('无法从 AI 响应中解析 JSON', name: 'DeepSeekService');
        throw Exception('AI 返回格式错误，无法解析 JSON');
      }

      final jsonData = jsonDecode(jsonMatch.group(0)!);
      developer.log('JSON 解析成功，开始转换为 FitnessPlan 对象', name: 'DeepSeekService');
      final plan = FitnessPlan.fromJson(jsonData);

      // 验证分钟数总和
      final sumMinutes = plan.items.fold(0, (sum, item) => sum + item.minutes);
      developer.log('分钟数验证: 计划总分钟=${plan.totalMinutes}, 实际总和=$sumMinutes', name: 'DeepSeekService');
      
      if (sumMinutes != plan.totalMinutes) {
        developer.log('分钟数不匹配，修正总分钟数从 ${plan.totalMinutes} 到 $sumMinutes', name: 'DeepSeekService');
        // 修正总分钟数
        return FitnessPlan(
          date: plan.date,
          totalMinutes: sumMinutes,
          items: plan.items,
        );
      }

      developer.log('健身计划生成成功: ${plan.items.length} 个项目，总时长: ${plan.totalMinutes} 分钟', name: 'DeepSeekService');
      return plan;
    } on SocketException {
      developer.log('网络连接超时异常', name: 'DeepSeekService');
      throw Exception('网络连接超时，请检查网络后重试');
    } on TimeoutException {
      developer.log('请求超时异常', name: 'DeepSeekService');
      throw Exception('请求超时，请稍后重试');
    } catch (e) {
      if (e.toString().contains('401') || e.toString().contains('Invalid authorization')) {
        developer.log('API Key 无效异常，API Key: ${trimmedApiKey}', name: 'DeepSeekService');
        developer.log('API Key 前缀: ${trimmedApiKey.substring(0, min(10, trimmedApiKey.length))}', name: 'DeepSeekService');
        throw Exception('API Key 无效，请检查后重试');
      } else if (e.toString().contains('429')) {
        developer.log('API 调用频率限制异常', name: 'DeepSeekService');
        throw Exception('API 调用频率限制，请稍后重试');
      } else if (e.toString().contains('500') || e.toString().contains('502') || e.toString().contains('503')) {
        developer.log('服务器错误异常', name: 'DeepSeekService');
        throw Exception('服务器繁忙，请稍后重试');
      }
      developer.log('其他网络错误: ${e.toString()}', name: 'DeepSeekService');
      throw Exception('网络错误: ${e.toString()}');
    }
  }

  /// 生成今日建议食谱
  Future<String> generateSuggestedRecipe({
    required double height,
    required double weight,
    required int age,
    required String gender,
    String experienceLevel = 'beginner',
    String goal = 'general_fitness',
  }) async {
    developer.log('开始生成建议食谱: 身高=$height, 体重=$weight, 年龄=$age, 性别=$gender', name: 'DeepSeekService');
    
    final apiKey = _storageService.getDsKey();
    final trimmedApiKey = apiKey.trim();
    
    if (trimmedApiKey.isEmpty) {
      developer.log('API Key 为空', name: 'DeepSeekService');
      throw Exception('请先在设置页填写 DeepSeek API Key');
    }
    
    if (trimmedApiKey.length < 10) {
      developer.log('API Key 长度过短: ${trimmedApiKey.length}', name: 'DeepSeekService');
      throw Exception('API Key 格式不正确，请检查后重新输入');
    }
    
    developer.log('API Key 长度: ${trimmedApiKey.length}', name: 'DeepSeekService');

    final prompt = '''
你是一名专业营养师。基于用户的身高(cm)、体重(kg)、年龄、性别和健身目标，为今天制定个性化的饮食建议。请输出严格 JSON 格式，不要多余文本。食谱要营养均衡、热量适中，适合健身人群。考虑训练消耗，提供合理的蛋白质、碳水化合物和脂肪比例。

用户信息：
- height_cm: $height
- weight_kg: $weight
- age: $age
- gender: $gender
- experience_level: $experienceLevel
- goal: $goal

请严格按照以下 JSON 格式输出：
{
  "date": "YYYY-MM-DD",
  "total_calories": 2500,
  "meals": [
    { "type": "breakfast", "name": "营养早餐", "description": "全麦面包+煎蛋+牛奶+水果", "calories": 500, "time": "07:30" },
    { "type": "lunch", "name": "健康午餐", "description": "糙米饭+鸡胸肉+蔬菜沙拉", "calories": 700, "time": "12:30" },
    { "type": "dinner", "name": "清淡晚餐", "description": "清蒸鱼+红薯+西兰花", "calories": 600, "time": "18:30" }
  ],
  "notes": "总热量2500kcal，蛋白质30%，碳水40%，脂肪30%。三餐均衡，营养全面。"
}

注意事项：
- 早餐必须包含，时间在6:00-9:00之间
- 午餐必须包含，时间在11:00-14:00之间  
- 晚餐必须包含，时间 in 17:00-20:00之间
- 总热量根据用户基础代谢和活动量计算
- 食材要常见易得，做法简单
''';
    
    developer.log('构建建议食谱请求参数', name: 'DeepSeekService');

    try {
      developer.log('开始发送 API 请求到 $_baseUrl/chat/completions', name: 'DeepSeekService');
      final response = await http
          .post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $trimmedApiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'max_tokens': 1000,
          'temperature': 0.7,
        }),
      )
          .timeout(const Duration(seconds: 15)); // 增加超时时间到15秒

      developer.log('建议食谱 API 响应状态码: ${response.statusCode}', name: 'DeepSeekService');
      developer.log('建议食谱 API 响应内容: ${response.body}', name: 'DeepSeekService');

      if (response.statusCode != 200) {
        developer.log('建议食谱 API 请求失败，状态码: ${response.statusCode}', name: 'DeepSeekService');
        developer.log('建议食谱 API 错误详情: ${response.body}', name: 'DeepSeekService');
        
        // 尝试解析错误响应
        try {
          final errorData = jsonDecode(response.body);
          if (errorData.containsKey('error')) {
            final errorMessage = errorData['error']['message'] ?? '未知错误';
            if (errorMessage.contains('Authentication Fails') || errorMessage.contains('invalid')) {
              throw Exception('API Key 无效或格式不正确，请检查后重新输入');
            }
            throw Exception('API 错误: $errorMessage');
          }
        } catch (e) {
          // 如果无法解析错误响应，则使用默认错误消息
          throw Exception('API 请求失败: ${response.statusCode}, 响应: ${response.body}');
        }
      }

      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      developer.log('建议食谱 AI 响应内容长度: ${content.length} 字符', name: 'DeepSeekService');
      developer.log('建议食谱 AI 响应内容: $content', name: 'DeepSeekService');
      
      // 尝试解析 JSON - 更宽松的正则表达式
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (jsonMatch == null) {
        developer.log('无法从 AI 响应中解析建议食谱 JSON', name: 'DeepSeekService');
        developer.log('AI 响应内容: $content', name: 'DeepSeekService');
        throw Exception('AI 返回格式错误，无法解析建议食谱 JSON');
      }

      final jsonData = jsonDecode(jsonMatch.group(0)!);
      developer.log('建议食谱 JSON 解析成功: $jsonData', name: 'DeepSeekService');
      
      // 验证必要的字段
      if (!jsonData.containsKey('meals') || (jsonData['meals'] as List).isEmpty) {
        throw Exception('AI 返回的食谱格式不正确，缺少必要的餐食信息');
      }
      
      return jsonEncode(jsonData);
    } on SocketException {
      developer.log('网络连接超时异常', name: 'DeepSeekService');
      throw Exception('网络连接超时，请检查网络后重试');
    } on TimeoutException {
      developer.log('请求超时异常', name: 'DeepSeekService');
      throw Exception('请求超时，请稍后重试');
    } catch (e) {
      if (e.toString().contains('401') || e.toString().contains('Invalid authorization')) {
        developer.log('API Key 无效异常，API Key: ${trimmedApiKey}', name: 'DeepSeekService');
        developer.log('API Key 前缀: ${trimmedApiKey.substring(0, min(10, trimmedApiKey.length))}', name: 'DeepSeekService');
        throw Exception('API Key 无效，请检查后重试');
      } else if (e.toString().contains('429')) {
        developer.log('API 调用频率限制异常', name: 'DeepSeekService');
        throw Exception('API 调用频率限制，请稍后重试');
      } else if (e.toString().contains('500') || e.toString().contains('502') || e.toString().contains('503')) {
        developer.log('服务器错误异常', name: 'DeepSeekService');
        throw Exception('服务器繁忙，请稍后重试');
      }
      developer.log('其他网络错误: ${e.toString()}', name: 'DeepSeekService');
      throw Exception('网络错误: ${e.toString()}');
    }
  }

  /// 获取 AI 分析建议
  Future<String> getAnalysis(
    double completionRate,
    double todayWeight,
    double lastWeight,
    String breakfast,
    String lunch,
    String dinner,
    String snack,
    String snackTime,
  ) async {
    final apiKey = _storageService.getDsKey();
    final trimmedApiKey = apiKey.trim();
    
    if (trimmedApiKey.isEmpty) {
      throw Exception('请先在设置页填写 DeepSeek API Key');
    }
    
    if (trimmedApiKey.length < 10) {
      throw Exception('API Key 格式不正确，请检查后重新输入');
    }

    final prompt = '''
你是一名健身教练。根据用户当日训练清单的完成比例、体重变化和饮食记录，给出≤150字建议，包含：今天表现评级（好/一般/差）、1条训练纠正建议、1条饮食建议、明日一条重点提示。仅输出纯文本，无 JSON。

用户数据：
- completion_rate: ${completionRate.toStringAsFixed(1)}%
- today_weight_kg: ${todayWeight.toStringAsFixed(1)}
- last_weight_kg: ${lastWeight.toStringAsFixed(1)}
- breakfast: ${breakfast.isNotEmpty ? breakfast : '未记录'}
- lunch: ${lunch.isNotEmpty ? lunch : '未记录'}
- dinner: ${dinner.isNotEmpty ? dinner : '未记录'}
- snack: ${snack.isNotEmpty ? snack : '未记录'}
- snack_time: ${snackTime.isNotEmpty ? snackTime : '未记录'}

请给出简洁的建议（不超过150字）：
''';

    try {
      final response = await http
          .post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $trimmedApiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'max_tokens': 200,
          'temperature': 0.7,
        }),
      )
          .timeout(const Duration(seconds: 10));

      developer.log('分析建议API响应状态码: ${response.statusCode}', name: 'DeepSeekService');
      developer.log('分析建议API响应内容: ${response.body}', name: 'DeepSeekService');

      if (response.statusCode != 200) {
        developer.log('分析建议API请求失败，状态码: ${response.statusCode}', name: 'DeepSeekService');
        developer.log('分析建议API错误详情: ${response.body}', name: 'DeepSeekService');
        
        // 尝试解析错误响应
        try {
          final errorData = jsonDecode(response.body);
          if (errorData.containsKey('error')) {
            final errorMessage = errorData['error']['message'] ?? '未知错误';
            if (errorMessage.contains('Authentication Fails') || errorMessage.contains('invalid')) {
              throw Exception('API Key 无效或格式不正确，请检查后重新输入');
            }
            throw Exception('API 错误: $errorMessage');
          }
        } catch (e) {
          // 如果无法解析错误响应，则使用默认错误消息
          throw Exception('API 请求失败: ${response.statusCode}, 响应: ${response.body}');
        }
      }

      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      
      return content.trim();
    } on SocketException {
      throw Exception('网络连接超时，请检查网络后重试');
    } on TimeoutException {
      throw Exception('请求超时，请稍后重试');
    } catch (e) {
      if (e.toString().contains('401') || e.toString().contains('Invalid authorization')) {
        throw Exception('API Key 无效，请检查后重试');
      } else if (e.toString().contains('429')) {
        throw Exception('API 调用频率限制，请稍后重试');
      } else if (e.toString().contains('500') || e.toString().contains('502') || e.toString().contains('503')) {
        throw Exception('服务器繁忙，请稍后重试');
      }
      throw Exception('网络错误: ${e.toString()}');
    }
  }
}
