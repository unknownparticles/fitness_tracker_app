import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:self_discipline_planet/services/storage_service.dart';
import 'package:self_discipline_planet/services/deepseek_service.dart';
import 'settings_page.dart';
import 'dart:developer' as developer;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late StorageService _storageService;
  late DeepSeekService _deepSeekService;
  bool _isLoading = false;
  String? _planJson;
  List<bool> _checkedList = [];
  double _todayWeight = 0.0;
  final _weightController = TextEditingController();
  
  // 饮食记录控制器
  final _breakfastController = TextEditingController();
  final _lunchController = TextEditingController();
  final _dinnerController = TextEditingController();
  final _snackController = TextEditingController();
  final _trainingFeedbackController = TextEditingController();

  // 各模块展开状态 - 默认只有健身打卡展开
  bool _isDietExpanded = false;
  bool _isRecipeExpanded = false;
  bool _isFeedbackExpanded = false;
  
  // 建议食谱数据
  dynamic _suggestedRecipeData;
  
  // 训练感受相关
  String _selectedFeedback = ''; // 'too_hard', 'just_right', 'too_easy'

  // 拖动按钮位置（不再使用）
  // double _fabX = 0.0;
  // double _fabY = 0.0;
  // double _screenWidth = 0.0;
  // double _screenHeight = 0.0;
  // double _bottomPadding = 0.0; // 底部安全区域高度
  // bool _isDragging = false; // 拖拽状态

  @override
  void initState() {
    super.initState();
    developer.log('HomePage initState', name: 'HomePage');
    _initData().then((_) {
      _checkShowOnboarding();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 移除悬浮按钮相关的屏幕尺寸获取
  }

  Future<void> _initData() async {
    developer.log('开始初始化主页数据', name: 'HomePage');
    _storageService = await StorageService.getInstance();
    _deepSeekService = DeepSeekService(_storageService);
    
    _loadTodayData();
    developer.log('主页数据初始化完成', name: 'HomePage');
  }

  // 检查并显示引导
  void _checkShowOnboarding() {
    if (!_storageService.hasOnboardingShown()) {
      // 延迟显示引导，确保UI已经渲染
      Future.delayed(const Duration(milliseconds: 500), () {
        _showOnboardingDialog();
      });
    }
  }

  // 显示引导对话框
  void _showOnboardingDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('欢迎使用 自律星球'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '这是一个智能健身助手，帮你制定和管理每日训练计划。\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('📋 如何开始：'),
              const Text('  1. 点击右上角⚙️进入设置页面'),
              const Text('  2. 填写身高、体重、出生年份、性别'),
              const Text('  3. 输入 DeepSeek API Key（获取方式见帮助）'),
              const Text('  4. 返回主页，点击右下角🤖生成今日计划\n'),
              const Text('🎯 主要功能：'),
              const Text('  • 健身打卡：勾选完成的训练项目'),
              const Text('  • 记录体重：在Summary区域点击体重数字编辑'),
              const Text('  • AI 分析：点击🤖选择"分析今日运动"'),
              const Text('  • 饮食记录：点击"今日饮食"展开后填写'),
              const Text('  • 查看帮助：设置页面的帮助按钮'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _storageService.markOnboardingShown();
              },
              child: const Text('我知道了'),
            ),
          ],
        );
      },
    );
  }

  void _loadTodayData() {
    developer.log('开始加载今日数据', name: 'HomePage');
    setState(() {
      _planJson = _storageService.getPlanJson();
      _checkedList = _storageService.getPlanChecked();
      _todayWeight = _storageService.getTodayWeight();
      _weightController.text = _todayWeight > 0 ? _todayWeight.toStringAsFixed(1) : '';
      
      // 加载饮食数据
      final breakfast = _storageService.getBreakfast();
      final lunch = _storageService.getLunch();
      final dinner = _storageService.getDinner();
      final snack = _storageService.getSnack();
      
      _breakfastController.text = breakfast;
      _lunchController.text = lunch;
      _dinnerController.text = dinner;
      _snackController.text = snack;
      
      // 加载训练感受数据
      final feedback = _storageService.getTrainingFeedback();
      _trainingFeedbackController.text = feedback;
    });
    _loadSuggestedRecipe();
    developer.log('今日数据加载完成', name: 'HomePage');
  }

  // 计算完成率
  double _getCompletionRate() {
    if (_checkedList.isEmpty) return 0.0;
    final completed = _checkedList.where((checked) => checked).length;
    return ((completed / _checkedList.length) * 100).toDouble();
  }

  // 计算总时长
  int _getTotalMinutes() {
    if (_planJson == null) return 0;
    try {
      final data = jsonDecode(_planJson!);
      return data['total_minutes'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // 计算已完成时长
  int _getCompletedMinutes() {
    if (_planJson == null) return 0;
    try {
      final data = jsonDecode(_planJson!);
      final items = data['items'] as List;
      var completedMinutes = 0;
      for (int i = 0; i < _checkedList.length && i < items.length; i++) {
        if (_checkedList[i]) {
          final item = items[i];
          final minutes = item['minutes'];
          if (minutes is int) {
            completedMinutes += minutes;
          } else if (minutes is num) {
            completedMinutes += minutes.toInt();
          }
        }
      }
      return completedMinutes;
    } catch (e) {
      return 0;
    }
  }

  // 获取饮食记录计数
  int _getRecordedMealsCount() {
    var count = 0;
    if (_breakfastController.text.trim().isNotEmpty) count++;
    if (_lunchController.text.trim().isNotEmpty) count++;
    if (_dinnerController.text.trim().isNotEmpty) count++;
    if (_snackController.text.trim().isNotEmpty) count++;
    return count;
  }

  // 获取上次生成时间
  String _getLastRecipeTime() {
    if (_suggestedRecipeData == null) return '未生成';
    // 这里可以从数据中提取时间，暂时返回当前时间
    final now = DateTime.now();
    return '${_formatTwoDigits(now.hour)}:${_formatTwoDigits(now.minute)}';
  }

  // 获取训练感受状态文本
  String _getFeedbackStatus() {
    if (_selectedFeedback.isNotEmpty) {
      switch (_selectedFeedback) {
        case 'too_hard': return '太难';
        case 'just_right': return '正好';
        case 'too_easy': return '太简单';
        default: return '正好';
      }
    }
    return _trainingFeedbackController.text.isNotEmpty ? '已记录' : '未记录';
  }

  Future<void> _generateFitnessPlan() async {
    developer.log('开始生成健身计划', name: 'HomePage');
    
    final height = _storageService.getHeight();
    final weight = _storageService.getWeight();
    final birthYear = _storageService.getBirthYear();
    final gender = _storageService.getGender();
    final dsKey = _storageService.getDsKey();

    if (dsKey.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('请先在设置页填写 DeepSeek API Key'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (height <= 0 || weight <= 0 || birthYear <= 0 || gender.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('请先在设置页完善个人信息'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final existingPlan = _storageService.getPlanJson();
    final existingRecipe = _storageService.getSuggestedRecipe();
    
    if (existingPlan != null && existingRecipe != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('今日健身计划和建议食谱已存在，如需重新生成请先清空数据'),
            backgroundColor: Colors.blue,
          ),
        );
      }
      return;
    }

    final age = DateTime.now().year - birthYear;

    setState(() {
      _isLoading = true;
    });

    try {
      developer.log('调用 DeepSeek API 生成健身计划', name: 'HomePage');
      final plan = await _deepSeekService.generateFitnessPlan(
        height: height,
        weight: weight,
        age: age,
        gender: gender,
      );

      if (plan != null) {
        developer.log('计划生成成功，开始保存数据', name: 'HomePage');
        // 保存计划数据
        await _storageService.savePlanJson(jsonEncode(plan.toJson()));
        // 重置勾选状态
        final newList = List<bool>.filled(plan.items.length, false);
        await _storageService.savePlanChecked(newList);
        
        // 同时生成建议食谱
        try {
          await _generateSuggestedRecipe(height, weight, age, gender);
          developer.log('建议食谱生成成功', name: 'HomePage');
        } catch (e) {
          developer.log('建议食谱生成失败: ${e.toString()}', name: 'HomePage');
        }
        
        _loadTodayData();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已生成今日计划'),
              backgroundColor: Colors.green,
            ),
          );
        }
        developer.log('健身计划和建议食谱保存和显示完成', name: 'HomePage');
      }
    } catch (e) {
      developer.log('生成计划失败: ${e.toString()}', name: 'HomePage');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
        developer.log('生成计划操作完成，重置加载状态', name: 'HomePage');
      });
    }
  }

  // 生成建议食谱
  Future<void> _generateSuggestedRecipe(double height, double weight, int age, String gender) async {
    try {
      final recipeJson = await _deepSeekService.generateSuggestedRecipe(
        height: height,
        weight: weight,
        age: age,
        gender: gender,
      );
      
      await _storageService.saveSuggestedRecipe(recipeJson);
      _loadSuggestedRecipe();
      
      developer.log('建议食谱生成成功', name: 'HomePage');
    } catch (e) {
      developer.log('生成建议食谱失败: ${e.toString()}', name: 'HomePage');
    }
  }

  // 加载建议食谱数据
  void _loadSuggestedRecipe() {
    final recipeJson = _storageService.getSuggestedRecipe();
    if (recipeJson != null) {
      try {
        final recipeData = jsonDecode(recipeJson);
        setState(() {
          _suggestedRecipeData = recipeData;
        });
        developer.log('建议食谱数据加载成功', name: 'HomePage');
      } catch (e) {
        developer.log('解析建议食谱数据失败: ${e.toString()}', name: 'HomePage');
      }
    }
  }

  Future<void> _saveTodayWeight() async {
    if (_weightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入今日体重'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final weight = double.parse(_weightController.text);
      if (weight < 30 || weight > 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('请输入合理的体重范围（30-200kg）'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await _storageService.saveTodayWeight(weight);
      _loadTodayData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('体重保存成功！'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('请输入有效的体重数字'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 保存饮食记录
  Future<void> _saveMeal(String mealType, String mealContent) async {
    try {
      switch (mealType) {
        case 'breakfast':
          await _storageService.saveBreakfast(mealContent);
          developer.log('早餐保存成功: $mealContent', name: 'HomePage');
          break;
        case 'lunch':
          await _storageService.saveLunch(mealContent);
          developer.log('午餐保存成功: $mealContent', name: 'HomePage');
          break;
        case 'dinner':
          await _storageService.saveDinner(mealContent);
          developer.log('晚餐保存成功: $mealContent', name: 'HomePage');
          break;
        case 'snack':
          await _storageService.saveSnack(mealContent);
          developer.log('加餐保存成功: $mealContent', name: 'HomePage');
          break;
      }
    } catch (e) {
      developer.log('保存$mealType失败: ${e.toString()}', name: 'HomePage');
    }
  }

  Future<void> _toggleCheck(int index) async {
    if (_checkedList.length > index) {
      setState(() {
        _checkedList[index] = !_checkedList[index];
      });
      await _storageService.savePlanChecked(_checkedList);
      developer.log('勾选状态已自动保存', name: 'HomePage');
    }
  }

  // 保存训练感受
  Future<void> _saveTrainingFeedback() async {
    final feedback = _trainingFeedbackController.text.trim();
    
    if (feedback.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入训练感受'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (feedback.length > 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('训练感受请控制在60字以内'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await _storageService.saveTrainingFeedback(feedback);
      developer.log('训练感受保存成功: $feedback', name: 'HomePage');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('训练感受保存成功！'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('保存训练感受失败'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _getAnalysis() async {
    if (_planJson == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先生成今日健身计划'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_todayWeight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先填写今日体重'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 自动保存所有饮食记录
    await _autoSaveAllMeals();
    
    final planData = jsonDecode(_planJson!);
    final totalItems = planData['items'].length;
    final completedItems = _checkedList.where((checked) => checked).length;
    final double completionRate = totalItems > 0 ? ((completedItems / totalItems) * 100).toDouble() : 0.0;

    // 获取饮食数据
    final breakfast = _storageService.getBreakfast();
    final lunch = _storageService.getLunch();
    final dinner = _storageService.getDinner();
    final snack = _storageService.getSnack();

    // 获取上次体重（昨天）
    final lastWeight = _getLastWeight();

    setState(() {
      _isLoading = true;
    });

    try {
      final analysis = await _deepSeekService.getAnalysis(
        completionRate,
        _todayWeight,
        lastWeight,
        breakfast,
        lunch,
        dinner,
        snack,
        '',
      );

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('AI 分析建议'),
              content: Text(analysis),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('知道了'),
                ),
              ],
            );
          },
        );
      }
      developer.log('AI 分析完成', name: 'HomePage');
    } catch (e) {
      developer.log('AI 分析失败: ${e.toString()}', name: 'HomePage');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
        developer.log('分析操作完成，重置加载状态', name: 'HomePage');
      });
    }
  }

  // 自动保存所有饮食记录
  Future<void> _autoSaveAllMeals() async {
    if (_breakfastController.text.trim().isNotEmpty) {
      await _saveMeal('breakfast', _breakfastController.text.trim());
    }
    if (_lunchController.text.trim().isNotEmpty) {
      await _saveMeal('lunch', _lunchController.text.trim());
    }
    if (_dinnerController.text.trim().isNotEmpty) {
      await _saveMeal('dinner', _dinnerController.text.trim());
    }
    if (_snackController.text.trim().isNotEmpty) {
      await _saveMeal('snack', _snackController.text.trim());
    }
    
    developer.log('所有饮食记录已自动保存', name: 'HomePage');
  }

  double _getLastWeight() {
    return _todayWeight;
  }

  Map<String, dynamic>? _getPlanData() {
    if (_planJson == null) return null;
    try {
      return jsonDecode(_planJson!);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final planData = _getPlanData();
    final today = DateTime.now();
    final dateString = '${today.year}-${_formatTwoDigits(today.month)}-${_formatTwoDigits(today.day)}';
    final completionRate = _getCompletionRate();
    final completedMinutes = _getCompletedMinutes();
    final totalMinutes = _getTotalMinutes();

    return Scaffold(
      appBar: AppBar(
        title: const Text('自律星球'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.smart_toy),
            onPressed: () {
              _showAIActions();
            },
            tooltip: 'AI 功能',
          ),
        ],
      ),
      body: Stack(
        children: [
          // 主要内容
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // 顶部 Summary（粘顶）
                    _buildSummary(dateString, completionRate, completedMinutes, totalMinutes),
                    const SizedBox(height: 8),

                    // 主要内容区域 - 可滚动
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // 区块 A｜健身打卡（默认展开）
                            _buildFitnessBlock(planData),
                            const SizedBox(height: 12),

                            // 区块 B｜今日饮食（默认折叠）
                            _buildDietBlock(),
                            const SizedBox(height: 12),

                            // 区块 C｜AI 食谱（默认折叠）
                            _buildRecipeBlock(),
                            const SizedBox(height: 12),

                            // 区块 D｜训练感受（默认折叠）
                            _buildFeedbackBlock(),
                          ],
                        ),
                      ),
                    ),
                    
                    // BottomSheet 高度占位
                    const SizedBox(height: 100),
                  ],
                ),
          
          // 底部栏 - 使用 Positioned 放在底部
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomBar(),
          ),
        ],
      ),
    );
  }

  // 顶部 Summary
  Widget _buildSummary(String date, double completionRate, int completedMinutes, int totalMinutes) {
    return Container(
      color: Colors.blue[50],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '今日 · 完成 ${completionRate.toInt()}% · 体重 ${_todayWeight > 0 ? '${_todayWeight.toStringAsFixed(1)}kg' : '--'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  '计划 $totalMinutes 分钟 | 已完成 $completedMinutes 分钟',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 16),
            onPressed: () {
              _showWeightEditDialog();
            },
            color: Colors.blue,
            tooltip: '编辑体重',
          ),
        ],
      ),
    );
  }

  // 区块 A｜健身打卡
  Widget _buildFitnessBlock(Map<String, dynamic>? planData) {
    if (planData == null) {
      return _buildCollapsibleBlock(
        title: '健身打卡',
        subtitle: '暂无今日计划，点击右下角『AI』生成。',
        isExpanded: true,
        onToggle: () {},
        content: [
          const Center(
            child: Column(
              children: [
                Icon(Icons.fitness_center, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text('暂无今日健身计划'),
                Text('点击右下角『AI』生成', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      );
    }

    return _buildCollapsibleBlock(
      title: '健身打卡',
      subtitle: '今日训练清单',
      isExpanded: true,
      onToggle: () {
        // 健身打卡默认展开，不提供折叠功能
      },
      content: [
        _buildPlanListSection(planData),
      ],
    );
  }

  // 区块 B｜今日饮食
  Widget _buildDietBlock() {
    final recordedCount = _getRecordedMealsCount();
    return _buildCollapsibleBlock(
      title: '今日饮食',
      subtitle: '已记录 $recordedCount/4 餐',
      isExpanded: _isDietExpanded,
      onToggle: () {
        setState(() {
          _isDietExpanded = !_isDietExpanded;
        });
      },
      content: [
        _buildDietContent(),
      ],
    );
  }

  // 区块 C｜AI 食谱
  Widget _buildRecipeBlock() {
    final lastTime = _getLastRecipeTime();
    return _buildCollapsibleBlock(
      title: 'AI 食谱',
      subtitle: '上次 $lastTime',
      isExpanded: _isRecipeExpanded,
      onToggle: () {
        setState(() {
          _isRecipeExpanded = !_isRecipeExpanded;
        });
      },
      content: [
        _buildRecipeContent(),
      ],
    );
  }

  // 区块 D｜训练感受
  Widget _buildFeedbackBlock() {
    final status = _getFeedbackStatus();
    return _buildCollapsibleBlock(
      title: '训练感受',
      subtitle: '$status（可更改）',
      isExpanded: _isFeedbackExpanded,
      onToggle: () {
        setState(() {
          _isFeedbackExpanded = !_isFeedbackExpanded;
        });
      },
      content: [
        _buildFeedbackContent(),
      ],
    );
  }

  // 通用可折叠区块
  Widget _buildCollapsibleBlock({
    required String title,
    required String subtitle,
    required bool isExpanded,
    required VoidCallback onToggle,
    required List<Widget> content,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          InkWell(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          
          // 展开内容
          if (isExpanded) ...content,
        ],
      ),
    );
  }

  // 健身计划列表
  Widget _buildPlanListSection(Map<String, dynamic> planData) {
    final items = planData['items'] as List;
    final totalMinutes = planData['total_minutes'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, size: 16),
              const SizedBox(width: 4),
              Text(
                '总时长: $totalMinutes 分钟',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              if (index >= _checkedList.length) {
                _checkedList.add(false);
              }

              final item = items[index];
              final title = item['title'] ?? '';
              final minutes = item['minutes'] ?? 0;
              final note = item['note'] ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 2),
                child: CheckboxListTile(
                  value: _checkedList[index],
                  onChanged: (bool? value) {
                    _toggleCheck(index);
                  },
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$minutes 分钟'),
                      if (note.isNotEmpty) Text(note, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  secondary: Text('$minutes分钟'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 饮食内容
  Widget _buildDietContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMealInput('早餐', '例如：面包+鸡蛋+牛奶', _breakfastController, 'breakfast'),
          const SizedBox(height: 8),
          _buildMealInput('午餐', '例如：米饭+鸡肉+蔬菜', _lunchController, 'lunch'),
          const SizedBox(height: 8),
          _buildMealInput('晚餐', '例如：面条+鱼肉+沙拉', _dinnerController, 'dinner'),
          const SizedBox(height: 8),
          _buildMealInput('加餐', '例如：水果+坚果', _snackController, 'snack'),
        ],
      ),
    );
  }

  // 食谱内容
  Widget _buildRecipeContent() {
    if (_suggestedRecipeData == null) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          '暂无建议食谱，点击右下角『AI』生成计划时会同时生成食谱。',
          style: TextStyle(color: Colors.orange),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_suggestedRecipeData['total_calories'] != null)
            Row(
              children: [
                const Icon(Icons.local_dining, size: 16, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  '总热量: ${_suggestedRecipeData['total_calories']} kcal',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          const SizedBox(height: 8),
          if (_suggestedRecipeData['meals'] != null)
            Column(
              children: [
                ..._buildMealItems(_suggestedRecipeData['meals']),
                const SizedBox(height: 8),
                if (_suggestedRecipeData['notes'] != null)
                  Text(
                    _suggestedRecipeData['notes'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  // 训练感受内容
  Widget _buildFeedbackContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '训练强度感受：',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildFeedbackButton('太难', 'too_hard'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFeedbackButton('正好', 'just_right'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFeedbackButton('太简单', 'too_easy'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _trainingFeedbackController,
            decoration: const InputDecoration(
              hintText: '可选：简单描述感受或建议',
              prefixIcon: Icon(Icons.edit_note),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            maxLines: 2,
            maxLength: 60,
            keyboardType: TextInputType.multiline,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Spacer(),
              Text(
                '${_trainingFeedbackController.text.length}/60',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Spacer(),
              ElevatedButton(
                onPressed: _saveTrainingFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('保存感受'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 训练感受按钮
  Widget _buildFeedbackButton(String label, String value) {
    final bool isSelected = _selectedFeedback == value;
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _selectedFeedback = isSelected ? '' : value;
        });
      },
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: isSelected ? Colors.red : Colors.grey,
          width: 1.5,
        ),
        backgroundColor: isSelected ? Colors.red.withOpacity(0.1) : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.red : Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMealInput(String mealName, String hintText, TextEditingController controller, String mealType) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: mealName,
              hintText: hintText,
              prefixIcon: mealType == 'breakfast' 
                  ? Icon(Icons.free_breakfast)
                  : mealType == 'lunch'
                      ? Icon(Icons.lunch_dining)
                      : mealType == 'dinner'
                          ? Icon(Icons.dinner_dining)
                          : Icon(Icons.local_cafe),
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            maxLines: 1,
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            _saveMeal(mealType, controller.text);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$mealName 记录保存成功！'),
                backgroundColor: Colors.green,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16),
          ),
          child: const Text('保存'),
        ),
      ],
    );
  }

  List<Widget> _buildMealItems(List meals) {
    final List<Widget> mealWidgets = [];

    for (int i = 0; i < meals.length; i++) {
      final meal = meals[i];
      final mealType = meal['type'] ?? '';
      final mealName = meal['name'] ?? '';
      final description = meal['description'] ?? '';
      final calories = meal['calories'] ?? 0;
      final time = meal['time'] ?? '';

      // 根据餐次显示不同图标和颜色
      IconData icon;
      Color color;
      String displayType;

      switch (mealType) {
        case 'breakfast':
          icon = Icons.free_breakfast;
          color = Colors.brown;
          displayType = '🍳 早餐';
          break;
        case 'lunch':
          icon = Icons.lunch_dining;
          color = Colors.green;
          displayType = '🍱 午餐';
          break;
        case 'dinner':
          icon = Icons.dinner_dining;
          color = Colors.blue;
          displayType = '🍝 晚餐';
          break;
        case 'snack':
          icon = Icons.local_cafe;
          color = Colors.purple;
          displayType = '☕ 加餐';
          break;
        default:
          icon = Icons.restaurant;
          color = Colors.grey;
          displayType = '🍽️ 餐食';
      }

      mealWidgets.add(
        Card(
          color: color.withOpacity(0.1),
          margin: const EdgeInsets.symmetric(vertical: 2),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 餐次和时间
                      Row(
                        children: [
                          Text(
                            displayType,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (time.isNotEmpty)
                            Text(
                              '($time)',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),

                      // 餐食名称
                      Text(
                        mealName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),

                      // 描述
                      Text(
                        description,
                        style: const TextStyle(fontSize: 11),
                      ),
                      const SizedBox(height: 2),

                      // 热量
                      if (calories > 0)
                        Text(
                          '$calories kcal',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // 如果不是最后一项，添加分隔线
      if (i < meals.length - 1) {
        mealWidgets.add(const Divider(height: 4, thickness: 1));
      }
    }

    return mealWidgets;
  }

  // 显示体重编辑对话框
  void _showWeightEditDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('编辑今日体重'),
          content: TextField(
            controller: _weightController,
            decoration: const InputDecoration(
              hintText: '输入体重(kg)',
              suffixText: 'kg',
              prefixIcon: Icon(Icons.monitor_weight),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                _saveTodayWeight();
                Navigator.of(context).pop();
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  // 显示 AI 功能面板
  void _showAIActions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'AI 功能',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '选择要执行的 AI 操作',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _generateFitnessPlan();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      minimumSize: const Size(double.infinity, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '生成今日计划',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '生成健身计划和建议食谱',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _getAnalysis();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      minimumSize: const Size(double.infinity, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '分析今日运动',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '基于完成情况给出建议',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('取消'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTwoDigits(int number) {
    return number.toString().padLeft(2, '0');
  }

  // 底部栏
  Widget _buildBottomBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 生成今日计划按钮
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: _generateFitnessPlan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                child: const Text(
                  '生成今日计划',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          
          // 分析今日运动按钮
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: _getAnalysis,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '分析今日运动',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
