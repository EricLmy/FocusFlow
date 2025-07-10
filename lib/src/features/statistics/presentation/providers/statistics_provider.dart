import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_service.dart';
import '../../../../domain/entities/focus_record.dart';
import '../../../../domain/entities/task.dart';
import '../../../../domain/repositories/focus_record_repository.dart';
import '../../../../domain/repositories/task_repository.dart';

/// 专注记录仓库Provider
final focusRecordRepositoryProvider = Provider<FocusRecordRepository>((ref) {
  return DatabaseService.instance.focusRecordRepository;
});

/// 任务仓库Provider
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return DatabaseService.instance.taskRepository;
});

/// 统计数据状态类
class StatisticsState {
  final FocusStatistics? focusStats;
  final TaskStatistics? taskStats;
  final List<DailyFocusStats> dailyStats;
  final List<WeeklyFocusStats> weeklyStats;
  final List<MonthlyFocusStats> monthlyStats;
  final List<FocusRecord> recentSessions;
  final List<Task> todayTasks;
  final bool isLoading;
  final String? error;
  final DateTime lastUpdated;

  const StatisticsState({
    this.focusStats,
    this.taskStats,
    this.dailyStats = const [],
    this.weeklyStats = const [],
    this.monthlyStats = const [],
    this.recentSessions = const [],
    this.todayTasks = const [],
    this.isLoading = false,
    this.error,
    required this.lastUpdated,
  });

  StatisticsState copyWith({
    FocusStatistics? focusStats,
    TaskStatistics? taskStats,
    List<DailyFocusStats>? dailyStats,
    List<WeeklyFocusStats>? weeklyStats,
    List<MonthlyFocusStats>? monthlyStats,
    List<FocusRecord>? recentSessions,
    List<Task>? todayTasks,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return StatisticsState(
      focusStats: focusStats ?? this.focusStats,
      taskStats: taskStats ?? this.taskStats,
      dailyStats: dailyStats ?? this.dailyStats,
      weeklyStats: weeklyStats ?? this.weeklyStats,
      monthlyStats: monthlyStats ?? this.monthlyStats,
      recentSessions: recentSessions ?? this.recentSessions,
      todayTasks: todayTasks ?? this.todayTasks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// 统计数据Provider
class StatisticsNotifier extends StateNotifier<StatisticsState> {
  final FocusRecordRepository _focusRecordRepository;
  final TaskRepository _taskRepository;

  StatisticsNotifier(
    this._focusRecordRepository,
    this._taskRepository,
  ) : super(StatisticsState(lastUpdated: DateTime.now())) {
    loadAllStatistics();
  }

  /// 加载所有统计数据
  Future<void> loadAllStatistics() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // 并行加载所有数据
      final results = await Future.wait([
        _focusRecordRepository.getFocusStatistics(),
        _taskRepository.getTaskStatistics(),
        _focusRecordRepository.getDailyFocusStats(7), // 最近7天
        _focusRecordRepository.getWeeklyFocusStats(4), // 最近4周
        _focusRecordRepository.getMonthlyFocusStats(6), // 最近6个月
        _loadRecentSessions(),
        _taskRepository.getTodayTasks(),
      ]);

      state = state.copyWith(
        focusStats: results[0] as FocusStatistics,
        taskStats: results[1] as TaskStatistics,
        dailyStats: results[2] as List<DailyFocusStats>,
        weeklyStats: results[3] as List<WeeklyFocusStats>,
        monthlyStats: results[4] as List<MonthlyFocusStats>,
        recentSessions: results[5] as List<FocusRecord>,
        todayTasks: results[6] as List<Task>,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '加载统计数据失败: ${e.toString()}',
      );
    }
  }

  /// 加载最近的专注会话
  Future<List<FocusRecord>> _loadRecentSessions() async {
    return await _focusRecordRepository.getAllRecords(limit: 10);
  }

  /// 根据时间范围获取专注统计
  Future<FocusStatistics> getFocusStatsByPeriod(String period) async {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (period) {
      case 'today':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate.add(const Duration(days: 1));
        break;
      case 'week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        endDate = startDate.add(const Duration(days: 7));
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 1);
        break;
      default:
        return state.focusStats ?? const FocusStatistics(
          totalSessions: 0,
          completedSessions: 0,
          interruptedSessions: 0,
          cancelledSessions: 0,
          totalFocusMinutes: 0,
          totalPlannedMinutes: 0,
          averageSessionMinutes: 0,
          completionRate: 0,
          averageEfficiency: 0,
          averageQualityScore: 0,
          totalInterruptions: 0,
          averageInterruptionsPerSession: 0,
          longestSessionMinutes: 0,
          shortestSessionMinutes: 0,
          sessionsByModeType: {},
          minutesByModeType: {},
          streakDays: 0,
        );
    }

    return await _focusRecordRepository.getFocusStatisticsByDateRange(
      startDate,
      endDate,
    );
  }

  /// 根据时间范围获取任务统计
  Future<Map<String, dynamic>> getTaskStatsByPeriod(String period) async {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (period) {
      case 'today':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate.add(const Duration(days: 1));
        break;
      case 'week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        endDate = startDate.add(const Duration(days: 7));
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 1);
        break;
      default:
        final taskStats = state.taskStats;
        return {
          'completedTasks': taskStats?.completedTasks ?? 0,
          'totalTasks': taskStats?.totalTasks ?? 0,
          'completionRate': taskStats?.completionRate ?? 0.0,
        };
    }

    // 获取指定时间范围内的任务
    List<Task> tasks;
    if (period == 'today') {
      // 对于今日统计，获取更全面的任务列表：
      // 1. 今天创建的任务
      // 2. 今天到期的任务  
      // 3. 没有截止日期但状态为进行中的任务
      // 4. 逾期但未完成的任务
      final todayCreatedTasks = await _taskRepository.getTasksByDateRange(startDate, endDate);
      final overdueTasks = await _taskRepository.getOverdueTasks();
      final inProgressTasks = await _taskRepository.getTasksByStatus(TaskStatus.inProgress);
      
      // 合并任务列表并去重
      final taskMap = <int, Task>{};
      for (final task in todayCreatedTasks) {
        taskMap[task.id!] = task;
      }
      for (final task in overdueTasks) {
        taskMap[task.id!] = task;
      }
      for (final task in inProgressTasks) {
        if (task.dueDate == null || task.dueDate!.isBefore(endDate)) {
          taskMap[task.id!] = task;
        }
      }
      tasks = taskMap.values.toList();
    } else {
      tasks = await _taskRepository.getTasksByDateRange(startDate, endDate);
    }

    final completedTasks = tasks.where((task) => 
      task.status == TaskStatus.completed
    ).length;
    
    final totalTasks = tasks.length;
    final completionRate = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

    return {
      'completedTasks': completedTasks,
      'totalTasks': totalTasks,
      'completionRate': completionRate,
    };
  }

  /// 获取图表数据
  Future<List<Map<String, dynamic>>> getChartData(String period) async {
    switch (period) {
      case 'today':
        // 返回今天每小时的数据
        return await _getTodayHourlyData();
      case 'week':
        // 返回本周每天的数据
        return await _getWeeklyDailyData();
      case 'month':
        // 返回本月每周的数据
        return await _getMonthlyWeeklyData();
      default:
        return [];
    }
  }

  /// 获取今天每小时的数据
  Future<List<Map<String, dynamic>>> _getTodayHourlyData() async {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    // 从数据库获取今天的专注记录
    final todayRecords = await _focusRecordRepository.getRecordsByDateRange(
      todayStart, 
      todayEnd
    );

    final hourlyData = <String, int>{};
    
    for (int hour = 0; hour < 24; hour++) {
      final hourStart = todayStart.add(Duration(hours: hour));
      final hourEnd = hourStart.add(const Duration(hours: 1));
      
      final hourMinutes = todayRecords
          .where((record) => 
            record.startTime.isAfter(hourStart) && 
            record.startTime.isBefore(hourEnd) &&
            record.status == FocusSessionStatus.completed)
          .fold<int>(0, (sum, record) => sum + record.actualMinutes);
      
      hourlyData['${hour.toString().padLeft(2, '0')}:00'] = hourMinutes;
    }

    return hourlyData.entries.map((entry) => {
      'label': entry.key,
      'value': entry.value,
      'height': entry.value > 0 ? (entry.value / 60 * 100).clamp(10, 100) : 0,
    }).toList();
  }

  /// 获取本周每天的数据
  Future<List<Map<String, dynamic>>> _getWeeklyDailyData() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDay = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final weekEndDay = weekStartDay.add(const Duration(days: 7));
    
    // 从数据库获取本周的专注记录
    final weekRecords = await _focusRecordRepository.getRecordsByDateRange(
      weekStartDay, 
      weekEndDay
    );
    
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final dailyData = <String, int>{};
    
    for (int i = 0; i < 7; i++) {
      final day = weekStartDay.add(Duration(days: i));
      final dayEnd = day.add(const Duration(days: 1));
      
      final dayMinutes = weekRecords
          .where((record) => 
            record.startTime.isAfter(day) && 
            record.startTime.isBefore(dayEnd) &&
            record.status == FocusSessionStatus.completed)
          .fold<int>(0, (sum, record) => sum + record.actualMinutes);
      
      dailyData[weekdays[i]] = dayMinutes;
    }

    final maxMinutes = dailyData.values.isNotEmpty 
        ? dailyData.values.reduce((a, b) => a > b ? a : b) 
        : 1;

    return dailyData.entries.map((entry) => {
      'label': entry.key,
      'value': entry.value,
      'height': entry.value > 0 ? (entry.value / maxMinutes * 100).clamp(10, 100) : 0,
      'displayValue': '${(entry.value / 60).toStringAsFixed(1)}h',
    }).toList();
  }

  /// 获取本月每周的数据
  Future<List<Map<String, dynamic>>> _getMonthlyWeeklyData() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);
    
    // 从数据库获取本月的专注记录
    final monthRecords = await _focusRecordRepository.getRecordsByDateRange(
      monthStart, 
      monthEnd
    );
    
    final weeklyData = <String, int>{};
    
    // 计算本月的周数据
    DateTime currentWeekStart = monthStart;
    int weekNumber = 1;
    
    while (currentWeekStart.isBefore(monthEnd)) {
      final weekEnd = currentWeekStart.add(const Duration(days: 7));
      final actualWeekEnd = weekEnd.isAfter(monthEnd) ? monthEnd : weekEnd;
      
      final weekMinutes = monthRecords
          .where((record) => 
            record.startTime.isAfter(currentWeekStart) && 
            record.startTime.isBefore(actualWeekEnd) &&
            record.status == FocusSessionStatus.completed)
          .fold<int>(0, (sum, record) => sum + record.actualMinutes);
      
      weeklyData['第${weekNumber}周'] = weekMinutes;
      
      currentWeekStart = weekEnd;
      weekNumber++;
    }

    final maxMinutes = weeklyData.values.isNotEmpty 
        ? weeklyData.values.reduce((a, b) => a > b ? a : b) 
        : 1;

    return weeklyData.entries.map((entry) => {
      'label': entry.key,
      'value': entry.value,
      'height': entry.value > 0 ? (entry.value / maxMinutes * 100).clamp(10, 100) : 0,
      'displayValue': '${(entry.value / 60).toStringAsFixed(1)}h',
    }).toList();
  }

  /// 刷新数据
  Future<void> refresh() async {
    await loadAllStatistics();
  }
}

/// 统计数据Provider实例
final statisticsProvider = StateNotifierProvider<StatisticsNotifier, StatisticsState>((ref) {
  final focusRecordRepository = ref.watch(focusRecordRepositoryProvider);
  final taskRepository = ref.watch(taskRepositoryProvider);
  
  return StatisticsNotifier(focusRecordRepository, taskRepository);
});

/// 根据时间范围获取专注统计的Provider
final focusStatsByPeriodProvider = FutureProvider.family<FocusStatistics, String>((ref, period) async {
  final notifier = ref.read(statisticsProvider.notifier);
  return await notifier.getFocusStatsByPeriod(period);
});

/// 根据时间范围获取任务统计的Provider
final taskStatsByPeriodProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, period) async {
  // 监听统计数据状态变化，确保数据更新时重新计算
  ref.watch(statisticsProvider);
  final notifier = ref.read(statisticsProvider.notifier);
  return await notifier.getTaskStatsByPeriod(period);
});

/// 获取图表数据的Provider
final chartDataProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, period) async {
  final notifier = ref.read(statisticsProvider.notifier);
  return await notifier.getChartData(period);
});

/// 根据时间范围获取专注会话记录的Provider
final focusSessionsByPeriodProvider = FutureProvider.family<List<FocusRecord>, String>((ref, period) async {
  final focusRecordRepository = ref.read(focusRecordRepositoryProvider);
  final now = DateTime.now();
  DateTime startDate;
  DateTime endDate;

  switch (period) {
    case 'today':
      startDate = DateTime(now.year, now.month, now.day);
      endDate = startDate.add(const Duration(days: 1));
      break;
    case 'week':
      startDate = now.subtract(Duration(days: now.weekday - 1));
      startDate = DateTime(startDate.year, startDate.month, startDate.day);
      endDate = startDate.add(const Duration(days: 7));
      break;
    case 'month':
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 1);
      break;
    default:
      // 默认返回最近10条记录
      return await focusRecordRepository.getAllRecords(limit: 10);
  }

  return await focusRecordRepository.getRecordsByDateRange(startDate, endDate, limit: 10);
});