import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

/// 本地存储服务，负责管理所有 SharedPreferences 操作
class StorageService {
  static const String _heightKey = 'profile.height_cm';
  static const String _weightKey = 'profile.weight_kg';
  static const String _birthYearKey = 'profile.birth_year';
  static const String _genderKey = 'profile.gender';
  static const String _dsKeyKey = 'profile.ds_key';

  final SharedPreferences _prefs;

  StorageService._internal(this._prefs) {
    developer.log('StorageService 初始化完成', name: 'StorageService');
  }

  /// 工厂构造函数，确保单例模式
  static StorageService? _instance;

  static Future<StorageService> getInstance() async {
    if (_instance == null) {
      developer.log('初始化 StorageService 单例', name: 'StorageService');
      final prefs = await SharedPreferences.getInstance();
      _instance = StorageService._internal(prefs);
      developer.log('SharedPreferences 初始化完成', name: 'StorageService');
    } else {
      developer.log('使用现有的 StorageService 实例', name: 'StorageService');
    }
    return _instance!;
  }

  // 用户资料相关
  Future<void> saveHeight(double height) async {
    developer.log('保存身高: $height cm', name: 'StorageService');
    await _prefs.setDouble(_heightKey, height);
    developer.log('身高保存成功', name: 'StorageService');
  }

  double getHeight() {
    final height = _prefs.getDouble(_heightKey) ?? 0.0;
    developer.log('读取身高: $height cm', name: 'StorageService');
    return height;
  }

  Future<void> saveWeight(double weight) async {
    developer.log('保存体重: $weight kg', name: 'StorageService');
    await _prefs.setDouble(_weightKey, weight);
    developer.log('体重保存成功', name: 'StorageService');
  }

  double getWeight() {
    final weight = _prefs.getDouble(_weightKey) ?? 0.0;
    developer.log('读取体重: $weight kg', name: 'StorageService');
    return weight;
  }

  Future<void> saveBirthYear(int birthYear) async {
    developer.log('保存出生年份: $birthYear', name: 'StorageService');
    await _prefs.setInt(_birthYearKey, birthYear);
    developer.log('出生年份保存成功', name: 'StorageService');
  }

  int getBirthYear() {
    final birthYear = _prefs.getInt(_birthYearKey) ?? 0;
    developer.log('读取出生年份: $birthYear', name: 'StorageService');
    return birthYear;
  }

  Future<void> saveGender(String gender) async {
    developer.log('保存性别: $gender', name: 'StorageService');
    await _prefs.setString(_genderKey, gender);
    developer.log('性别保存成功', name: 'StorageService');
  }

  String getGender() {
    final gender = _prefs.getString(_genderKey) ?? '';
    developer.log('读取性别: $gender', name: 'StorageService');
    return gender;
  }

  Future<void> saveDsKey(String key) async {
    final trimmedKey = key.trim();
    final keyLength = trimmedKey.isNotEmpty ? trimmedKey.length : 0;
    developer.log('保存 API Key (长度: $keyLength)', name: 'StorageService');
    await _prefs.setString(_dsKeyKey, trimmedKey);
    developer.log('API Key 保存成功', name: 'StorageService');
  }

  String getDsKey() {
    final key = _prefs.getString(_dsKeyKey) ?? '';
    final trimmedKey = key.trim();
    final keyLength = trimmedKey.isNotEmpty ? trimmedKey.length : 0;
    developer.log('读取 API Key (长度: $keyLength)', name: 'StorageService');
    return trimmedKey;
  }

  // 今日体重相关（按日期隔离）
  String _getTodayWeightKey() {
    final today = DateTime.now();
    final key = 'today.weight_${today.year}${_formatTwoDigits(today.month)}${_formatTwoDigits(today.day)}';
    developer.log('生成今日体重键: $key', name: 'StorageService');
    return key;
  }

  Future<void> saveTodayWeight(double weight) async {
    final key = _getTodayWeightKey();
    developer.log('保存今日体重: $weight kg 到键: $key', name: 'StorageService');
    await _prefs.setDouble(key, weight);
    developer.log('今日体重保存成功', name: 'StorageService');
  }

  double getTodayWeight() {
    final key = _getTodayWeightKey();
    final weight = _prefs.getDouble(key) ?? 0.0;
    developer.log('从键: $key 读取今日体重: $weight kg', name: 'StorageService');
    return weight;
  }

  // 计划相关（按日期隔离）
  String _getPlanJsonKey() {
    final today = DateTime.now();
    final key = 'plan.json_${today.year}${_formatTwoDigits(today.month)}${_formatTwoDigits(today.day)}';
    developer.log('生成计划JSON键: $key', name: 'StorageService');
    return key;
  }

  String _getPlanCheckedKey() {
    final today = DateTime.now();
    final key = 'plan.checked_${today.year}${_formatTwoDigits(today.month)}${_formatTwoDigits(today.day)}';
    developer.log('生成计划勾选键: $key', name: 'StorageService');
    return key;
  }

  Future<void> savePlanJson(String json) async {
    final key = _getPlanJsonKey();
    developer.log('保存计划JSON到键: $key', name: 'StorageService');
    developer.log('JSON内容长度: ${json.length} 字符', name: 'StorageService');
    await _prefs.setString(key, json);
    developer.log('计划JSON保存成功', name: 'StorageService');
  }

  String? getPlanJson() {
    final key = _getPlanJsonKey();
    developer.log('从键: $key 读取计划JSON', name: 'StorageService');
    final json = _prefs.getString(key);
    if (json != null) {
      developer.log('读取到JSON内容长度: ${json.length} 字符', name: 'StorageService');
    } else {
      developer.log('未找到计划JSON', name: 'StorageService');
    }
    return json;
  }

  Future<void> savePlanChecked(List<bool> checkedList) async {
    final key = _getPlanCheckedKey();
    final checkedString = checkedList.map((e) => e ? '1' : '0').join(',');
    developer.log('保存计划勾选状态: $checkedString 到键: $key', name: 'StorageService');
    await _prefs.setString(key, checkedString);
    developer.log('计划勾选状态保存成功', name: 'StorageService');
  }

  List<bool> getPlanChecked() {
    final key = _getPlanCheckedKey();
    developer.log('从键: $key 读取计划勾选状态', name: 'StorageService');
    final checkedString = _prefs.getString(key) ?? '';
    if (checkedString.isEmpty) {
      developer.log('勾选状态为空，返回空列表', name: 'StorageService');
      return [];
    }
    final checkedList = checkedString.split(',').map((e) => e == '1').toList();
    developer.log('读取到勾选状态: $checkedString', name: 'StorageService');
    return checkedList;
  }

  /// 格式化数字为两位数字符串
  String _formatTwoDigits(int number) {
    return number.toString().padLeft(2, '0');
  }

  // 饮食记录相关（按日期隔离）
  String _getBreakfastKey() {
    final today = DateTime.now();
    final key = 'diet.breakfast_${today.year}${_formatTwoDigits(today.month)}${_formatTwoDigits(today.day)}';
    developer.log('生成早餐键: $key', name: 'StorageService');
    return key;
  }

  String _getLunchKey() {
    final today = DateTime.now();
    final key = 'diet.lunch_${today.year}${_formatTwoDigits(today.month)}${_formatTwoDigits(today.day)}';
    developer.log('生成午餐键: $key', name: 'StorageService');
    return key;
  }

  String _getDinnerKey() {
    final today = DateTime.now();
    final key = 'diet.dinner_${today.year}${_formatTwoDigits(today.month)}${_formatTwoDigits(today.day)}';
    developer.log('生成晚餐键: $key', name: 'StorageService');
    return key;
  }

  String _getSnackKey() {
    final today = DateTime.now();
    final key = 'diet.snack_${today.year}${_formatTwoDigits(today.month)}${_formatTwoDigits(today.day)}';
    developer.log('生成加餐键: $key', name: 'StorageService');
    return key;
  }

  String _getSnackTimeKey() {
    final today = DateTime.now();
    final key = 'diet.snack_time_${today.year}${_formatTwoDigits(today.month)}${_formatTwoDigits(today.day)}';
    developer.log('生成加餐时间键: $key', name: 'StorageService');
    return key;
  }

  Future<void> saveBreakfast(String meal) async {
    final key = _getBreakfastKey();
    developer.log('保存早餐: $meal 到键: $key', name: 'StorageService');
    await _prefs.setString(key, meal);
    developer.log('早餐保存成功', name: 'StorageService');
  }

  Future<void> saveLunch(String meal) async {
    final key = _getLunchKey();
    developer.log('保存午餐: $meal 到键: $key', name: 'StorageService');
    await _prefs.setString(key, meal);
    developer.log('午餐保存成功', name: 'StorageService');
  }

  Future<void> saveDinner(String meal) async {
    final key = _getDinnerKey();
    developer.log('保存晚餐: $meal 到键: $key', name: 'StorageService');
    await _prefs.setString(key, meal);
    developer.log('晚餐保存成功', name: 'StorageService');
  }

  Future<void> saveSnack(String snack) async {
    final key = _getSnackKey();
    developer.log('保存加餐: $snack 到键: $key', name: 'StorageService');
    await _prefs.setString(key, snack);
    developer.log('加餐保存成功', name: 'StorageService');
  }

  Future<void> saveSnackTime(String time) async {
    final key = _getSnackTimeKey();
    developer.log('保存加餐时间: $time 到键: $key', name: 'StorageService');
    await _prefs.setString(key, time);
    developer.log('加餐时间保存成功', name: 'StorageService');
  }

  String getBreakfast() {
    final key = _getBreakfastKey();
    final meal = _prefs.getString(key) ?? '';
    developer.log('从键: $key 读取早餐: $meal', name: 'StorageService');
    return meal;
  }

  String getLunch() {
    final key = _getLunchKey();
    final meal = _prefs.getString(key) ?? '';
    developer.log('从键: $key 读取午餐: $meal', name: 'StorageService');
    return meal;
  }

  String getDinner() {
    final key = _getDinnerKey();
    final meal = _prefs.getString(key) ?? '';
    developer.log('从键: $key 读取晚餐: $meal', name: 'StorageService');
    return meal;
  }

  String getSnack() {
    final key = _getSnackKey();
    final snack = _prefs.getString(key) ?? '';
    developer.log('从键: $key 读取加餐: $snack', name: 'StorageService');
    return snack;
  }

  String getSnackTime() {
    final key = _getSnackTimeKey();
    final time = _prefs.getString(key) ?? '';
    developer.log('从键: $key 读取加餐时间: $time', name: 'StorageService');
    return time;
  }

  // 建议食谱相关（按日期隔离）
  String _getSuggestedRecipeKey() {
    final today = DateTime.now();
    final key = 'recipe.suggested_${today.year}${_formatTwoDigits(today.month)}${_formatTwoDigits(today.day)}';
    developer.log('生成建议食谱键: $key', name: 'StorageService');
    return key;
  }

  Future<void> saveSuggestedRecipe(String recipe) async {
    final key = _getSuggestedRecipeKey();
    developer.log('保存建议食谱到键: $key', name: 'StorageService');
    await _prefs.setString(key, recipe);
    developer.log('建议食谱保存成功', name: 'StorageService');
  }

  String? getSuggestedRecipe() {
    final key = _getSuggestedRecipeKey();
    developer.log('从键: $key 读取建议食谱', name: 'StorageService');
    final recipe = _prefs.getString(key);
    if (recipe != null) {
      developer.log('读取到建议食谱内容长度: ${recipe.length} 字符', name: 'StorageService');
    } else {
      developer.log('未找到建议食谱', name: 'StorageService');
    }
    return recipe;
  }

  // 训练感受相关（按日期隔离）
  String _getTrainingFeedbackKey() {
    final today = DateTime.now();
    final key = 'feedback.training_${today.year}${_formatTwoDigits(today.month)}${_formatTwoDigits(today.day)}';
    developer.log('生成训练感受键: $key', name: 'StorageService');
    return key;
  }

  Future<void> saveTrainingFeedback(String feedback) async {
    final key = _getTrainingFeedbackKey();
    developer.log('保存训练感受到键: $key', name: 'StorageService');
    await _prefs.setString(key, feedback);
    developer.log('训练感受保存成功', name: 'StorageService');
  }

  String getTrainingFeedback() {
    final key = _getTrainingFeedbackKey();
    final feedback = _prefs.getString(key) ?? '';
    developer.log('从键: $key 读取训练感受: $feedback', name: 'StorageService');
    return feedback;
  }

  /// 清除所有数据（用于测试）
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
