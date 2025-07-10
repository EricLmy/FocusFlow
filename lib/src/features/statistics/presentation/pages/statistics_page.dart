import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../providers/statistics_provider.dart';
import '../../../../domain/entities/focus_record.dart';
import '../../../../domain/entities/task.dart';
import '../../../../utils/performance_formatter.dart';
import '../../../task_management/presentation/providers/task_provider.dart';

/// 统计页面
class StatisticsPage extends ConsumerStatefulWidget {
  const StatisticsPage({super.key});
  
  @override
  ConsumerState<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends ConsumerState<StatisticsPage> {
  String selectedPeriod = 'today';
  
  @override
  Widget build(BuildContext context) {
    final statisticsState = ref.watch(statisticsProvider);
    // 监听任务数据变化，当任务数据更新时自动刷新统计数据
    ref.listen(taskListProvider, (previous, next) {
      if (previous?.lastUpdated != next.lastUpdated) {
        // 任务数据发生变化，刷新统计数据
        Future.microtask(() => ref.read(statisticsProvider.notifier).refresh());
      }
    });
    
    return Scaffold(
      body: statisticsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : statisticsState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        statisticsState.error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.read(statisticsProvider.notifier).refresh(),
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(statisticsProvider.notifier).refresh(),
                  child: CustomScrollView(
                    slivers: [
                      _buildHeader(),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              _buildTaskCompletionSection(),
                              const SizedBox(height: 20),
                              _buildFocusTimeSection(),
                              const SizedBox(height: 20),
                              _buildTodayTasksSection(),
                              const SizedBox(height: 20),
                              _buildFocusSessionsSection(),
                              const SizedBox(height: 100), // 底部留白
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
   }
  
  Widget _buildTaskCompletionSection() {
    final statisticsState = ref.watch(statisticsProvider);
    final taskStatsAsync = ref.watch(taskStatsByPeriodProvider(selectedPeriod));
    
    return _buildStatsSection(
      title: '✅ 任务完成情况',
      child: taskStatsAsync.when(
        data: (taskStats) {
          final completedTasks = taskStats['completedTasks'] ?? 0;
          final totalTasks = taskStats['totalTasks'] ?? 0;
          final completionRate = taskStats['completionRate'] ?? 0.0;
          final inProgressTasks = totalTasks - completedTasks;
          
          return Column(
            children: [
              SizedBox(
                height: 200,
                child: Center(
                  child: _buildProgressRing((completionRate * 100).clamp(0, 100)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem('$completedTasks', '已完成'),
                  ),
                  Expanded(
                    child: _buildStatItem('$inProgressTasks', '进行中'),
                  ),
                  Expanded(
                    child: _buildStatItem('$totalTasks', '总任务'),
                  ),
                ],
              ),
            ],
          );
        },
        loading: () => const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => SizedBox(
          height: 200,
          child: Center(
            child: Text(
              '加载失败: $error',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildFocusTimeSection() {
    final chartDataAsync = ref.watch(chartDataProvider(selectedPeriod));
    final todayFocusAsync = ref.watch(focusStatsByPeriodProvider('today'));
    final weekFocusAsync = ref.watch(focusStatsByPeriodProvider('week'));
    
    return _buildStatsSection(
      title: '🍅 专注时长统计',
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: chartDataAsync.when(
              data: (chartData) => chartData.isEmpty
                  ? const Center(
                      child: Text(
                        '暂无数据',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : _buildWeeklyChart(),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  '加载图表数据失败: $error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: todayFocusAsync.when(
                  data: (stats) => _buildStatItem(
                    _formatFocusTime(stats.totalFocusMinutes),
                    '今日专注',
                  ),
                  loading: () => _buildStatItem('--', '今日专注'),
                  error: (_, __) => _buildStatItem('--', '今日专注'),
                ),
              ),
              Expanded(
                child: weekFocusAsync.when(
                  data: (stats) => _buildStatItem(
                    _formatFocusTime(stats.totalFocusMinutes),
                    '本周专注',
                  ),
                  loading: () => _buildStatItem('--', '本周专注'),
                  error: (_, __) => _buildStatItem('--', '本周专注'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTodayTasksSection() {
    final statisticsState = ref.watch(statisticsProvider);
    final todayTasks = statisticsState.todayTasks;

    return _buildStatsSection(
      title: '今日任务',
      child: todayTasks.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  '今日暂无任务',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          : Column(
              children: todayTasks.take(4).map((task) => _buildTaskItemWithStatus(task)).toList(),
            ),
    );
  }

  /// 获取任务显示状态
  bool _getTaskDisplayStatus(Task task) {
    // 根据进度和状态判断任务是否完成
    return task.progress >= 1.0 && task.status == TaskStatus.completed;
  }

  String _formatTaskTime(Task task) {
    // 使用性能优化的格式化器
    if (task.completedAt != null) {
      return performanceFormatter.formatDateTime(task.completedAt!, format: 'HH:mm');
    } else if (task.dueDate != null) {
      return '预计 ${performanceFormatter.formatDateTime(task.dueDate!, format: 'HH:mm')}';
    } else {
      return '创建于 ${performanceFormatter.formatDateTime(task.createdAt, format: 'HH:mm')}';
    }
  }
  
  Widget _buildFocusSessionsSection() {
    final focusSessionsAsync = ref.watch(focusSessionsByPeriodProvider(selectedPeriod));

    return _buildStatsSection(
      title: '⏱️ 专注会话记录',
      child: focusSessionsAsync.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  '暂无专注记录',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }
          return Column(
            children: sessions.take(5).map((session) => _buildSessionItem(
              _getSessionIcon(session.modeType),
              _getSessionTitle(session),
              _formatSessionTime(session),
              _formatFocusTime(session.actualMinutes),
            )).toList(),
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              '加载专注记录失败: $error',
              style: const TextStyle(
                color: Colors.red,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getSessionTitle(FocusRecord session) {
    if (session.taskId != null) {
      // 如果有关联任务，可以从任务列表中查找任务标题
      final statisticsState = ref.read(statisticsProvider);
      final task = statisticsState.todayTasks.firstWhere(
        (task) => task.id == session.taskId,
        orElse: () => Task(
          id: 0,
          title: '未知任务',
          description: '',
          priority: TaskPriority.medium,
          status: TaskStatus.pending,
          estimatedMinutes: 0,
          actualMinutes: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isArchived: false,
          sortOrder: 0,
          progress: 0,
        ),
      );
      return '专注任务 - ${task.title}';
    } else {
      return '自由专注 - ${_getFocusModeText(session.modeType)}';
    }
  }

  String _getFocusModeText(FocusModeType modeType) {
    switch (modeType) {
      case FocusModeType.pomodoro:
        return '番茄钟';
      case FocusModeType.custom:
        return '自定义';
      case FocusModeType.freeform:
        return '自由模式';
      default:
        return '未知模式';
    }
  }
  
  String _getSessionIcon(FocusModeType modeType) {
    switch (modeType) {
      case FocusModeType.pomodoro:
        return '🍅';
      case FocusModeType.custom:
        return '⚙️';
      case FocusModeType.freeform:
        return '🎯';
      default:
        return '⏱️';
    }
  }
  
  String _formatSessionTime(FocusRecord session) {
    // 使用性能优化的格式化器
    final startTime = performanceFormatter.formatDateTime(session.startTime, format: 'HH:mm');
    if (session.endTime != null) {
      final endTime = performanceFormatter.formatDateTime(session.endTime!, format: 'HH:mm');
      return '$startTime - $endTime';
    } else {
      return '$startTime - 进行中';
    }
  }
  
  String _getSessionQuality(FocusRecord session) {
    // 使用FocusRecord的qualityScore属性
    final score = session.qualityScore;
    if (score >= 0.8) {
      return '优秀';
    } else if (score >= 0.6) {
      return '良好';
    } else if (score >= 0.4) {
      return '一般';
    } else {
      return '较差';
    }
  }
  
  /// 格式化专注时长显示，避免溢出问题
  String _formatFocusTime(int minutes) {
    // 使用性能优化的格式化器
    return performanceFormatter.formatDuration(Duration(minutes: minutes));
  }
  
  /// 格式化专注时长显示（简短版本，用于头部概览）
  String _formatFocusTimeShort(int minutes) {
    // 使用性能优化的格式化器，并进行简化处理
    final duration = Duration(minutes: minutes);
    final formatted = performanceFormatter.formatDuration(duration);
    
    // 将中文格式转换为简短英文格式
    if (minutes < 60) {
      return '${minutes}m';
    } else if (minutes < 1440) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}.${(remainingMinutes / 60 * 10).round()}h';
      }
    } else {
      final days = minutes ~/ 1440;
      final remainingHours = (minutes % 1440) ~/ 60;
      if (remainingHours == 0) {
        return '${days}d';
      } else {
        return '${days}d${remainingHours}h';
      }
    }
  }
  
  Widget _buildStatsSection({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2c3e50),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
  
  Widget _buildProgressRing(double percentage) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: percentage / 100,
              strokeWidth: 8,
              backgroundColor: const Color(0xFFecf0f1),
              valueColor: const AlwaysStoppedAnimation<Color>(const Color(0xFF667eea)),
            ),
          ),
          Positioned.fill(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${percentage.toInt()}%',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF667eea),
                    ),
                  ),
                  const Text(
                    '完成率',
                    style: TextStyle(
                      fontSize: 10,
                      color: const Color(0xFF7f8c8d),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWeeklyChart() {
    final chartDataAsync = ref.watch(chartDataProvider(selectedPeriod));
    
    return chartDataAsync.when(
      data: (chartData) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFf8f9fa),
          borderRadius: BorderRadius.circular(12),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: chartData.map((data) {
              final minutes = data['value'] as int;
              final double height = (data['height'] as num).toDouble().clamp(10.0, 120.0); // 限制最大高度避免溢出
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      constraints: const BoxConstraints(minWidth: 40),
                      child: Text(
                        data['displayValue'] ?? _formatFocusTime(minutes),
                        style: const TextStyle(
                          fontSize: 10,
                          color: const Color(0xFF7f8c8d),
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 32,
                      height: height,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [const Color(0xFF667eea), const Color(0xFF764ba2)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(minWidth: 40),
                      child: Text(
                        data['label'] as String,
                        style: const TextStyle(
                          fontSize: 10,
                          color: const Color(0xFF7f8c8d),
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text(
          '加载图表失败: $error',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFf8f9fa),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2c3e50),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: const Color(0xFF7f8c8d),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTaskItem(String name, String time, bool isCompleted) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: const Color(0xFFecf0f1), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isCompleted ? const Color(0xFF27ae60) : const Color(0xFFecf0f1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.radio_button_unchecked,
              size: 12,
              color: isCompleted ? Colors.white : const Color(0xFF7f8c8d),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF2c3e50),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF7f8c8d),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建带有详细状态的任务项
  Widget _buildTaskItemWithStatus(Task task) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    // 根据进度和状态确定显示样式
    if (task.progress >= 1.0 && task.status == TaskStatus.completed) {
      statusColor = const Color(0xFF27ae60);
      statusIcon = Icons.check_circle;
      statusText = '已完成';
    } else if (task.progress > 0.0 && task.progress < 1.0) {
      statusColor = const Color(0xFF3498db);
      statusIcon = Icons.play_circle_outline;
      statusText = '进行中 ${(task.progress * 100).round()}%';
    } else {
      statusColor = const Color(0xFF95a5a6);
      statusIcon = Icons.radio_button_unchecked;
      statusText = '未开始';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: const Color(0xFFecf0f1), width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            statusIcon,
            size: 20,
            color: statusColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF2c3e50),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      _formatTaskTime(task),
                      style: const TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF7f8c8d),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 10,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSessionItem(String icon, String title, String time, String duration) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFf8f9fa),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: const Color(0xFF667eea),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF2c3e50),
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF7f8c8d),
                  ),
                ),
              ],
            ),
          ),
          Text(
            duration,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF667eea),
            ),
          ),
        ],
      ),
    );
  }
  
  Map<String, dynamic> _getStatsForPeriod(String period) {
    final statisticsState = ref.read(statisticsProvider);
    
    // 使用Provider获取对应时间段的统计数据
    final focusStatsAsync = ref.read(focusStatsByPeriodProvider(period));
    final taskStatsAsync = ref.read(taskStatsByPeriodProvider(period));
    
    return focusStatsAsync.when(
      data: (focusStats) {
        return taskStatsAsync.when(
          data: (taskStats) => {
            'completedTasks': taskStats['completedTasks'] ?? 0,
            'focusTime': (focusStats.totalFocusMinutes / 60.0),
            'pomodoroCount': focusStats.totalSessions,
            'completionRate': taskStats['completionRate'] ?? 0.0,
          },
          loading: () => {
            'completedTasks': 0,
            'focusTime': 0.0,
            'pomodoroCount': 0,
            'completionRate': 0.0,
          },
          error: (_, __) => {
            'completedTasks': 0,
            'focusTime': 0.0,
            'pomodoroCount': 0,
            'completionRate': 0.0,
          },
        );
      },
      loading: () => {
        'completedTasks': 0,
        'focusTime': 0.0,
        'pomodoroCount': 0,
        'completionRate': 0.0,
      },
      error: (_, __) => {
        'completedTasks': 0,
        'focusTime': 0.0,
        'pomodoroCount': 0,
        'completionRate': 0.0,
      },
    );
  }
  
  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 240,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF667eea), const Color(0xFF764ba2)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: Text(
                          '数据统计',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      _buildDateSelector(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: _buildStatsOverview(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButton<String>(
        value: selectedPeriod,
        dropdownColor: const Color(0xFF667eea),
        underline: const SizedBox(),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        items: const [
          DropdownMenuItem(value: 'today', child: Text('今天')),
          DropdownMenuItem(value: 'week', child: Text('本周')),
          DropdownMenuItem(value: 'month', child: Text('本月')),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() {
              selectedPeriod = value;
            });
          }
        },
      ),
    );
  }
  
  Widget _buildStatsOverview() {
    final focusStatsAsync = ref.watch(focusStatsByPeriodProvider(selectedPeriod));
    final taskStatsAsync = ref.watch(taskStatsByPeriodProvider(selectedPeriod));
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: taskStatsAsync.when(
              data: (taskStats) => _buildOverviewCard(
                '${taskStats['completedTasks'] ?? 0}',
                '已完成任务',
              ),
              loading: () => _buildOverviewCard('--', '已完成任务'),
              error: (_, __) => _buildOverviewCard('--', '已完成任务'),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: focusStatsAsync.when(
              data: (focusStats) => _buildOverviewCard(
                _formatFocusTimeShort(focusStats.totalFocusMinutes),
                '专注时长',
              ),
              loading: () => _buildOverviewCard('--', '专注时长'),
              error: (_, __) => _buildOverviewCard('--', '专注时长'),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: focusStatsAsync.when(
              data: (focusStats) => _buildOverviewCard(
                '${focusStats.totalSessions}',
                '专注会话',
              ),
              loading: () => _buildOverviewCard('--', '专注会话'),
              error: (_, __) => _buildOverviewCard('--', '专注会话'),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOverviewCard(String number, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}