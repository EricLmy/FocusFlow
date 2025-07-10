import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../domain/entities/task.dart';
import '../../../../domain/entities/focus_record.dart';
import '../../../../core/database/database_service.dart';
import '../widgets/task_card.dart';
import '../widgets/quick_task_dialog.dart';
import '../widgets/task_detail_dialog.dart';

/// 主页 - 今日任务概览
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with WidgetsBindingObserver {
  List<Task> _tasks = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _todayFocusMinutes = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeDatabase();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 当应用从后台返回前台时刷新数据
    if (state == AppLifecycleState.resumed) {
      _loadTodayTasks();
      _loadTodayFocusTime();
    }
  }
  
  /// 初始化数据库并加载今日任务
  Future<void> _initializeDatabase() async {
    try {
      // 初始化数据库服务
      await DatabaseService.instance.initialize();
      
      // 加载今日任务和专注时长
      await Future.wait([
        _loadTodayTasks(),
        _loadTodayFocusTime(),
      ]);
    } catch (e) {
      setState(() {
        _errorMessage = '数据库初始化失败: $e';
        _isLoading = false;
      });
    }
  }
  
  /// 加载今日任务
  Future<void> _loadTodayTasks() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      final taskRepository = DatabaseService.instance.taskRepository;
      final todayTasks = await taskRepository.getTodayTasks();
      
      setState(() {
        // 自定义排序：未完成任务按优先级排序在前，已完成任务按优先级排序在后
        _tasks = _sortTasksByCompletionAndPriority(todayTasks);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载任务失败: $e';
        _isLoading = false;
      });
    }
  }

  /// 加载今日专注时长
  Future<void> _loadTodayFocusTime() async {
    try {
      final focusRecordRepository = DatabaseService.instance.focusRecordRepository;
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      
      final todayRecords = await focusRecordRepository.getRecordsByDateRange(todayStart, todayEnd);
      
      // 计算今日实际专注时长（只统计已完成的专注记录）
      final totalMinutes = todayRecords
          .where((record) => record.status == FocusSessionStatus.completed)
          .fold<int>(0, (sum, record) => sum + record.actualMinutes);
      
      setState(() {
        _todayFocusMinutes = totalMinutes;
      });
    } catch (e) {
      debugPrint('加载今日专注时长失败: $e');
    }
  }

  /// 自定义排序：未完成任务按优先级排序在前，已完成任务按优先级排序在后
  List<Task> _sortTasksByCompletionAndPriority(List<Task> tasks) {
    final List<Task> sortedTasks = List<Task>.from(tasks);
    
    sortedTasks.sort((a, b) {
      // 首先按完成状态排序：未完成的在前，已完成的在后
      final aCompleted = a.status == TaskStatus.completed;
      final bCompleted = b.status == TaskStatus.completed;
      
      if (aCompleted != bCompleted) {
        return aCompleted ? 1 : -1; // 未完成的排在前面
      }
      
      // 如果完成状态相同，则按优先级排序（紧急 > 高 > 中 > 低）
      return b.priority.index.compareTo(a.priority.index);
    });
    
    return sortedTasks;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummarySection(),
                _buildTaskListSection(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: const Color(0xFF7B61FF),
      expandedHeight: 120.0,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: const Text(
          'FocusFlow',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white),
        ),
        background: Container(
          color: const Color(0xFF7B61FF),
        ),
      ),
      // 暂时隐藏右上角按钮
      // actions: [
      //   IconButton(
      //     icon: const Icon(Icons.check_circle_outline, color: Colors.white),
      //     onPressed: () {},
      //   ),
      //   IconButton(
      //     icon: const Icon(Icons.notifications_none, color: Colors.white),
      //     onPressed: () {},
      //   ),
      //   const SizedBox(width: 8),
      // ],
    );
  }

  Widget _buildSummarySection() {
    // 计算今日任务统计
    final completedTasks = _tasks.where((task) => task.status == TaskStatus.completed).length;
    final totalTasks = _tasks.length;
    final taskProgress = totalTasks > 0 ? '$completedTasks/$totalTasks' : '0/0';
    
    // 计算今日专注时长（基于实际专注记录）
    final focusHours = _todayFocusMinutes > 0 
        ? '${(_todayFocusMinutes / 60).toStringAsFixed(1)}h' 
        : '0h';
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      decoration: const BoxDecoration(
        color: const Color(0xFF7B61FF),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          _buildSummaryCard('今日任务', taskProgress),
          const SizedBox(width: 16),
          _buildSummaryCard('专注时长', focusHours),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskListSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.list_alt, color: Colors.black87),
              const SizedBox(width: 8),
              Text(
                '今日任务',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  _loadTodayTasks();
                  _loadTodayFocusTime();
                },
                icon: const Icon(Icons.refresh, color: Colors.grey),
                tooltip: '刷新数据',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_errorMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _loadTodayTasks,
                    child: const Text('重试'),
                  ),
                ],
              ),
            )
          else if (_tasks.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.task_alt,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '今日暂无任务',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '点击右下角按钮创建新任务',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                return TaskCard(
                  task: _tasks[index],
                  onTap: () => _showTaskDetail(_tasks[index], index),
                  onToggleComplete: () => _toggleTaskCompletion(_tasks[index]),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () async {
        final result = await showDialog<Task>(
          context: context,
          builder: (context) => const QuickTaskDialog(),
        );
        
        if (result != null) {
          // QuickTaskDialog已经保存了任务到数据库，这里只需要刷新列表
          await _loadTodayTasks();
        }
      },
      backgroundColor: const Color(0xFF7B61FF),
      child: const Icon(Icons.add, color: Colors.white),
      elevation: 2.0,
    );
  }
  
  /// 创建新任务
  Future<void> _createTask(Task task) async {
    try {
      final taskRepository = DatabaseService.instance.taskRepository;
      final createdTask = await taskRepository.createTask(task);
      
      // 重新加载今日任务列表
      await _loadTodayTasks();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('任务「${createdTask.title}」创建成功'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('创建任务失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 显示任务详情弹窗
  void _showTaskDetail(Task task, int index) async {
    await showDialog(
      context: context,
      builder: (context) => TaskDetailDialog(
        task: task,
        onTaskUpdated: (updatedTask) async {
          // 更新数据库中的任务
          await _updateTask(updatedTask);
        },
      ),
    );
  }
  
  /// 更新任务
  Future<void> _updateTask(Task task) async {
    try {
      final taskRepository = DatabaseService.instance.taskRepository;
      await taskRepository.updateTask(task);
      
      // 重新加载今日任务列表
      await _loadTodayTasks();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('任务「${task.title}」更新成功'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新任务失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 切换任务完成状态
  Future<void> _toggleTaskCompletion(Task task) async {
    try {
      final taskRepository = DatabaseService.instance.taskRepository;
      
      // 切换任务状态
      final updatedTask = task.status == TaskStatus.completed
          ? task.copyWith(
              status: TaskStatus.pending,
              progress: 0.0, // 重置进度为0%
              updatedAt: DateTime.now(),
              completedAt: null,
            )
          : task.markAsCompleted(); // markAsCompleted方法已经会设置进度为100%
      
      await taskRepository.updateTask(updatedTask);
      
      // 重新加载并排序任务列表
      await _loadTodayTasks();
      
      if (mounted) {
        final statusText = updatedTask.status == TaskStatus.completed ? '已完成' : '未完成';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('任务「${task.title}」标记为$statusText'),
            backgroundColor: updatedTask.status == TaskStatus.completed ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新任务状态失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

}