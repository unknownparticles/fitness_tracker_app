import 'package:flutter/material.dart';
import 'package:self_discipline_planet/services/storage_service.dart';
import 'help_page.dart';
import 'dart:developer' as developer;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _birthYearController = TextEditingController();
  final _dsKeyController = TextEditingController();

  String _selectedGender = 'male';
  late StorageService _storageService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    developer.log('SettingsPage initState', name: 'SettingsPage');
    _initData();
  }

  Future<void> _initData() async {
    developer.log('开始初始化设置页面数据', name: 'SettingsPage');
    _storageService = await StorageService.getInstance();
    
    // 加载已保存的数据
    final height = _storageService.getHeight();
    final weight = _storageService.getWeight();
    final birthYear = _storageService.getBirthYear();
    final gender = _storageService.getGender();
    final dsKey = _storageService.getDsKey();
    
    _heightController.text = height.toStringAsFixed(1);
    _weightController.text = weight.toStringAsFixed(1);
    _birthYearController.text = birthYear.toString();
    _dsKeyController.text = dsKey;
    _selectedGender = gender.isNotEmpty ? gender : 'male';
    
    developer.log('设置页面数据加载完成: 身高=$height, 体重=$weight, 出生年份=$birthYear, 性别=$gender, API Key长度=${dsKey.length}', name: 'SettingsPage');
    
    setState(() {});
  }

  int _calculateAge() {
    final birthYear = int.tryParse(_birthYearController.text) ?? 0;
    if (birthYear > 0) {
      return DateTime.now().year - birthYear;
    }
    return 0;
  }

  Future<void> _saveSettings() async {
    developer.log('开始保存设置', name: 'SettingsPage');
    
    if (!_formKey.currentState!.validate()) {
      developer.log('表单验证失败', name: 'SettingsPage');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 安全解析数值，避免异常
      final heightText = _heightController.text.trim();
      final weightText = _weightController.text.trim();
      final birthYearText = _birthYearController.text.trim();
      final dsKeyText = _dsKeyController.text.trim();

      developer.log('解析表单数据: 身高="$heightText", 体重="$weightText", 出生年份="$birthYearText", API Key长度=${dsKeyText.length}', name: 'SettingsPage');

      if (heightText.isEmpty || weightText.isEmpty || birthYearText.isEmpty) {
        developer.log('验证失败: 必填字段为空', name: 'SettingsPage');
        throw Exception('请填写完整信息');
      }

      final height = double.tryParse(heightText);
      final weight = double.tryParse(weightText);
      final birthYear = int.tryParse(birthYearText);

      developer.log('数值解析结果: 身高=$height, 体重=$weight, 出生年份=$birthYear', name: 'SettingsPage');

      if (height == null || weight == null || birthYear == null) {
        developer.log('验证失败: 数值格式无效', name: 'SettingsPage');
        throw Exception('请输入有效的数字格式');
      }

      // 保存数据
      developer.log('开始保存数据到存储服务', name: 'SettingsPage');
      await _storageService.saveHeight(height);
      await _storageService.saveWeight(weight);
      await _storageService.saveBirthYear(birthYear);
      await _storageService.saveGender(_selectedGender);
      await _storageService.saveDsKey(dsKeyText);
      developer.log('所有数据保存完成', name: 'SettingsPage');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('设置保存成功！'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      developer.log('保存成功，显示成功提示', name: 'SettingsPage');
    } catch (e) {
      developer.log('保存失败: ${e.toString()}', name: 'SettingsPage');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
        developer.log('保存操作完成，重置加载状态', name: 'SettingsPage');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: '使用帮助',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpPage()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // 当前年龄显示
                    Card(
                      color: Colors.blue[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              '当前年龄: ${_calculateAge()} 岁',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 身高
                    TextFormField(
                      controller: _heightController,
                      decoration: const InputDecoration(
                        labelText: '身高 (cm)',
                        hintText: '请输入身高，如 175',
                        prefixIcon: Icon(Icons.height),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入身高';
                        }
                        final height = double.tryParse(value);
                        if (height == null || height <= 0) {
                          return '请输入有效的身高';
                        }
                        if (height < 100 || height > 250) {
                          return '身高应在 100-250 cm 之间';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 体重
                    TextFormField(
                      controller: _weightController,
                      decoration: const InputDecoration(
                        labelText: '体重 (kg)',
                        hintText: '请输入体重，如 70.5',
                        prefixIcon: Icon(Icons.scale),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入体重';
                        }
                        final weight = double.tryParse(value);
                        if (weight == null || weight <= 0) {
                          return '请输入有效的体重';
                        }
                        if (weight < 30 || weight > 200) {
                          return '体重应在 30-200 kg 之间';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 出生年份
                    TextFormField(
                      controller: _birthYearController,
                      decoration: const InputDecoration(
                        labelText: '出生年份',
                        hintText: '请输入出生年份，如 1990',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入出生年份';
                        }
                        final birthYear = int.tryParse(value);
                        if (birthYear == null) {
                          return '请输入有效的年份';
                        }
                        final currentYear = DateTime.now().year;
                        if (birthYear < currentYear - 100 || birthYear > currentYear) {
                          return '请输入合理的年份';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 性别选择
                    const Text(
                      '性别',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile(
                            title: const Text('男'),
                            value: 'male',
                            groupValue: _selectedGender,
                            onChanged: (value) {
                              setState(() {
                                _selectedGender = 'male';
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile(
                            title: const Text('女'),
                            value: 'female',
                            groupValue: _selectedGender,
                            onChanged: (value) {
                              setState(() {
                                _selectedGender = 'female';
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile(
                            title: const Text('其他'),
                            value: 'other',
                            groupValue: _selectedGender,
                            onChanged: (value) {
                              setState(() {
                                _selectedGender = 'other';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // DeepSeek API Key
                    StatefulBuilder(
                      builder: (BuildContext context, StateSetter setStateInField) {
                        bool _isObscured = true;
                        return TextFormField(
                          controller: _dsKeyController,
                          decoration: InputDecoration(
                            labelText: 'DeepSeek API Key',
                            hintText: '请输入您的 API Key',
                            prefixIcon: Icon(Icons.key),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 显示/隐藏切换按钮
                                IconButton(
                                  icon: Icon(
                                    _isObscured ? Icons.visibility_off : Icons.visibility,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    setStateInField(() {
                                      _isObscured = !_isObscured;
                                    });
                                  },
                                ),
                                // 清除按钮
                                if (_dsKeyController.text.isNotEmpty)
                                  IconButton(
                                    icon: Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _dsKeyController.clear();
                                      setState(() {});
                                    },
                                  ),
                              ],
                            ),
                          ),
                          obscureText: _isObscured, // 默认隐藏，用户可切换
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请输入 API Key';
                            }
                            return null;
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // 保存按钮
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '保存设置',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
