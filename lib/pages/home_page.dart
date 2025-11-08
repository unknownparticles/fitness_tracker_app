import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fitness_tracker_app/services/storage_service.dart';
import 'package:fitness_tracker_app/services/deepseek_service.dart';
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
  final _snackTimeController = TextEditingController();
  final _trainingFeedbackController = TextEditingController();

  // 建议食谱状态 - 默认展开
  bool _isRecipeExpanded = true;
  dynamic _suggestedRecipeData;
  
  // 其他模块的展开状态
  bool _isPlanExpanded = true;
  bool _isDietExpanded = true;
  bool _isWeightExpanded = true;
  bool _isFeedbackExpanded = true;

  @override
  void initState() {
    super.initState();
    developer.log('HomePage initState', name: 'HomePage');
    _initData();
  }

  Future<void> _initData() async {
    developer.log('开始初始化主页数据', name: 'HomePage');
    _storageService = await StorageService.getInstance();
    _deepSeekService = DeepSeekService(_storageService);
    
    _loadTodayData();
    developer.log('主页数据初始化完成', name: 'HomePage');
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
      final snackTime = _storageService.getSnackTime();
      
      _breakfastController.text = breakfast;
      _lunchController.text = lunch;
      _dinnerController.text = dinner;
      _snackController.text = snack;
      _snackTimeController.text = snackTime;
      
      // 加载训练感受数据
      final feedback = _storageService.getTrainingFeedback();
      _trainingFeedbackController.text = feedback;
    });
    _loadSuggestedRecipe();
    developer.log('今日数据加载完成: 计划JSON=${_planJson != null ? '存在' : '无'}, 勾选数=${_checkedList.length}, 体重=$_todayWeight', name: 'HomePage');
  }

  Future<void> _generateFitnessPlan() async {
    developer.log('开始生成健身计划', name: 'HomePage');
    
    final height = _storageService.getHeight();
    final weight = _storageService.getWeight();
    final birthYear = _storageService.getBirthYear();
    final gender = _storageService.getGender();
    final dsKey = _storageService.getDsKey();

    developer.log('用户信息: 身高=$height, 体重=$weight, 出生年份=$birthYear, 性别=$gender, API Key长度=${dsKey.length}', name: 'HomePage');

    if (dsKey.isEmpty) {
      developer.log('API Key 为空，显示错误提示', name: 'HomePage');
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
      developer.log('用户信息不完整，显示错误提示', name: 'HomePage');
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

    // 检查是否已有今日计划和建议食谱
    final existingPlan = _storageService.getPlanJson();
    final existingRecipe = _storageService.getSuggestedRecipe();
    
    // 检查每日建议食谱是否为空，不为空就打印出来
    if (existingRecipe != null) {
      developer.log('现有建议食谱内容: $existingRecipe', name: 'HomePage');
    } else {
      developer.log('当前无建议食谱数据', name: 'HomePage');
    }
    
    if (existingPlan != null && existingRecipe != null) {
      developer.log('已有今日计划和建议食谱，显示提示', name: 'HomePage');
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
    developer.log('计算年龄: $age', name: 'HomePage');

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
          // 食谱生成失败不影响计划生成，只记录日志
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('建议食谱生成失败，但健身计划已生成成功'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
        
        _loadTodayData();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('今日健身计划和建议食谱生成成功！'),
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
      developer.log('开始生成建议食谱', name: 'HomePage');
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
      // 食谱生成失败不影响计划生成，只记录日志
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

  Future<void> _saveSnackTime() async {
    if (_snackTimeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入加餐时间'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await _storageService.saveSnackTime(_snackTimeController.text);
      developer.log('加餐时间保存成功: ${_snackTimeController.text}', name: 'HomePage');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('加餐时间保存成功！'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('保存加餐时间失败'),
          backgroundColor: Colors.red,
        ),
      );
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

    if (feedback.length > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('训练感受请控制在100字以内'),
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
    final snackTime = _storageService.getSnackTime();

    // 获取上次体重（昨天）
    final lastWeight = _getLastWeight();

    setState(() {
      _isLoading = true;
    });

    try {
      developer.log('调用 AI 分析，饮食数据: 早餐=$breakfast, 午餐=$lunch, 晚餐=$dinner, 加餐=$snack, 加餐时间=$snackTime', name: 'HomePage');
      
      final analysis = await _deepSeekService.getAnalysis(
        completionRate,
        _todayWeight,
        lastWeight,
        breakfast,
        lunch,
        dinner,
        snack,
        snackTime,
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
                    // 分析完成后清空当天数据
                    _clearTodayData();
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
    // 保存所有有内容的饮食记录
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
    if (_snackTimeController.text.trim().isNotEmpty) {
      await _saveSnackTime();
    }
    
    developer.log('所有饮食记录已自动保存', name: 'HomePage');
  }

  // 清空当天数据用于下一次分析
  Future<void> _clearTodayData() async {
    try {
      // 清空计划相关数据
      await _storageService.savePlanJson('');
      await _storageService.savePlanChecked([]);
      
      // 清空饮食记录
      await _storageService.saveBreakfast('');
      await _storageService.saveLunch('');
      await _storageService.saveDinner('');
      await _storageService.saveSnack('');
      await _storageService.saveSnackTime('');
      
      // 清空训练感受
      await _storageService.saveTrainingFeedback('');
      
      developer.log('今日数据已清空，准备下一次分析', name: 'HomePage');
      
      // 重新加载数据
      _loadTodayData();
    } catch (e) {
      developer.log('清空数据失败: ${e.toString()}', name: 'HomePage');
    }
  }

  double _getLastWeight() {
    // 简单实现：返回当前体重作为上次体重（实际可以扩展为获取历史数据）
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('DeepSeek AI 健身计划'),
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
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 主要内容区域 - 可滚动
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // 日期显示
                        Card(
                          color: Colors.blue[50],
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                dateString,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 今日计划区域
                        planData == null
                            ? _buildEmptyPlanState()
                            : _buildPlanListSection(planData),
                        const SizedBox(height: 16),

                        // 建议食谱区域
                        _buildSuggestedRecipeSection(),
                        const SizedBox(height: 16),

                        // 饮食记录区域
                        _buildDietSection(),
                        const SizedBox(height: 16),

                        // 今日体重输入
                        _buildWeightSection(),
                        const SizedBox(height: 16),

                        // 训练感受输入
                        _buildTrainingFeedbackSection(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                
                // 底部固定操作区域
                _buildActionButtons(),
              ],
            ),
    );
  }


  Widget _buildDietSection() {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题和展开/收起按钮
            Row(
              children: [
                const Icon(Icons.restaurant, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '饮食记录',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isDietExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.green,
                  ),
                  onPressed: () {
                    setState(() {
                      _isDietExpanded = !_isDietExpanded;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 展开状态下显示饮食记录内容
            if (_isDietExpanded) ...[
              const SizedBox(height: 12),

              // 早餐
              _buildMealInput('早餐', '例如：面包+鸡蛋+牛奶', _breakfastController, 'breakfast'),

              // 午餐
              _buildMealInput('午餐', '例如：米饭+鸡肉+蔬菜', _lunchController, 'lunch'),

              // 晚餐
              _buildMealInput('晚餐', '例如：面条+鱼肉+沙拉', _dinnerController, 'dinner'),

              // 加餐
              _buildMealInput('加餐', '例如：水果+坚果', _snackController, 'snack'),

              // 加餐时间
              const SizedBox(height: 8),
              const Text(
                '加餐时间',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _snackTimeController,
                      decoration: const InputDecoration(
                        hintText: '例如：15:30',
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      keyboardType: TextInputType.datetime,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saveSnackTime,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('保存'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMealInput(String mealName, String hintText, TextEditingController controller, String mealType) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          mealName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hintText,
                  prefixIcon: mealType == 'breakfast' 
                      ? Icon(Icons.free_breakfast)
                      : mealType == 'lunch'
                          ? Icon(Icons.lunch_dining)
                          : mealType == 'dinner'
                              ? Icon(Icons.dinner_dining)
                              : Icon(Icons.local_cafe),
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
        ),
      ],
    );
  }

  Widget _buildWeightSection() {
    return Card(
      color: Colors.purple[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题和展开/收起按钮
            Row(
              children: [
                const Icon(Icons.scale, color: Colors.purple),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '体重记录',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isWeightExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.purple,
                  ),
                  onPressed: () {
                    setState(() {
                      _isWeightExpanded = !_isWeightExpanded;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 展开状态下显示体重记录内容
            if (_isWeightExpanded) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    '今日体重',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _weightController,
                      decoration: const InputDecoration(
                        hintText: '输入体重(kg)',
                        suffixText: 'kg',
                        prefixIcon: Icon(Icons.monitor_weight),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saveTodayWeight,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('保存'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.build, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  '操作',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _generateFitnessPlan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('生成/刷新\n今日计划'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _getAnalysis,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('一键AI\n分析'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPlanState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.fitness_center, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            '暂无今日健身计划',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            '点击下方按钮生成计划',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanListSection(Map<String, dynamic> planData) {
    final items = planData['items'] as List;
    final totalMinutes = planData['total_minutes'] ?? 0;

    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题和展开/收起按钮
            Row(
              children: [
                const Icon(Icons.fitness_center, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '今日健身计划',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isPlanExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.blue,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPlanExpanded = !_isPlanExpanded;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 展开状态下显示计划内容
            if (_isPlanExpanded) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.schedule, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    '总时长: ${totalMinutes}分钟',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
                    margin: const EdgeInsets.symmetric(vertical: 4),
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
          ],
        ),
      ),
    );
  }

  Widget _buildPlanList(Map<String, dynamic> planData) {
    final items = planData['items'] as List;
    final totalMinutes = planData['total_minutes'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.schedule, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              '总时长: ${totalMinutes}分钟',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
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
              margin: const EdgeInsets.symmetric(vertical: 4),
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
    );
  }

  String _formatTwoDigits(int number) {
    return number.toString().padLeft(2, '0');
  }

  Widget _buildSuggestedRecipeSection() {
    return Card(
      color: Colors.yellow[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题和展开/收起按钮
            Row(
              children: [
                const Icon(Icons.restaurant_menu, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '今日建议食谱',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isRecipeExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.orange,
                  ),
                  onPressed: () {
                    setState(() {
                      _isRecipeExpanded = !_isRecipeExpanded;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 如果没有食谱数据，显示提示
            if (_suggestedRecipeData == null)
              const Text(
                '点击上方"生成/刷新今日计划"按钮获取个性化建议食谱',
                style: TextStyle(fontSize: 14, color: Colors.orange),
              ),

            // 展开状态下显示食谱内容
            if (_isRecipeExpanded && _suggestedRecipeData != null) ...[
              const SizedBox(height: 12),

              // 总热量显示
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

              const SizedBox(height: 12),

              // 食谱列表
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
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingFeedbackSection() {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题和展开/收起按钮
            Row(
              children: [
                const Icon(Icons.feedback, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '训练感受',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isFeedbackExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.red,
                  ),
                  onPressed: () {
                    setState(() {
                      _isFeedbackExpanded = !_isFeedbackExpanded;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 展开状态下显示训练感受内容
            if (_isFeedbackExpanded) ...[
              const SizedBox(height: 12),
              const Text(
                '完成训练后，请分享你的感受（100字以内）',
                style: TextStyle(fontSize: 12, color: Colors.red),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _trainingFeedbackController,
                decoration: const InputDecoration(
                  hintText: '例如：今天感觉很充实，动作都完成了，就是俯卧撑有点吃力，下次可以减少组数',
                  prefixIcon: Icon(Icons.edit_note),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                maxLines: 3,
                maxLength: 100,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Spacer(),
                  Text(
                    '${_trainingFeedbackController.text.length}/100',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
          ],
        ),
      ),
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
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 12),
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
                          const SizedBox(width: 8),
                          if (time.isNotEmpty)
                            Text(
                              '($time)',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // 餐食名称
                      Text(
                        mealName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // 描述
                      Text(
                        description,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),

                      // 热量
                      if (calories > 0)
                        Text(
                          '$calories kcal',
                          style: const TextStyle(
                            fontSize: 12,
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
        mealWidgets.add(const Divider(height: 8, thickness: 1));
      }
    }

    return mealWidgets;
  }
}
