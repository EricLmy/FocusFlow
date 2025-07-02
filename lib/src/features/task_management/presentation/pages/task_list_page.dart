import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../domain/entities/task.dart';
import '../widgets/task_card.dart';
import '../widgets/task_filter_bar.dart';
import '../widgets/task_search_bar.dart';
import '../widgets/add_task_fab.dart';

/// 任务列表页面
class TaskListPage extends ConsumerStatefulWidget {
  const TaskListPage({super.key});
  
  @override
  ConsumerState<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends ConsumerState<TaskListPage> 
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  TaskStatus? _filterStatus;
  TaskPriority? _filterPriority;
  String? _filterCategory;
  
  // Mock数据开关 - 在实际开发中这应该从配置文件或环境变量读取
  static const bool _useMockData = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          TaskSearchBar(
            onSearchChanged: (query) {
              setState(() {
                _searchQuery = query;
              });
            },
          ),
          TaskFilterBar(
            selectedStatus: _filterStatus,
            selectedPriority: _filterPriority,
            selectedCategory: _filterCategory,
            onStatusChanged: (status) {
              setState(() {
                _filterStatus = status;
              });
            },
            onPriorityChanged: (priority) {
              setState(() {
                _filterPriority = priority;
              });
            },
            onCategoryChanged: (category) {
              setState(() {
                _filterCategory = category;
              });
            },
            onClearFilters: () {
              setState(() {
                _filterStatus = null;
                _filterPriority = null;
                _filterCategory = null;
              });
            },
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTaskList(TaskStatus.pending),
                _buildTaskList(TaskStatus.inProgress),
                _buildTaskList(TaskStatus.completed),
                _buildAllTasksList(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: const AddTaskFab(),
    );
  }
  
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('任务管理'),
      actions: [
        IconButton(
          icon: const Icon(Icons.sort),
          onPressed: _showSortOptions,
          tooltip: '排序',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'export',
              child: ListTile(
                leading: Icon(Icons.download),
                title: Text('导出任务'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'import',
              child: ListTile(
                leading: Icon(Icons.upload),
                title: Text('导入任务'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'archive',
              child: ListTile(
                leading: Icon(Icons.archive),
                title: Text('查看归档'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: ListTile(
                leading: Icon(Icons.settings),
                title: Text('设置'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: '待开始', icon: Icon(Icons.pending_actions)),
          Tab(text: '进行中', icon: Icon(Icons.play_circle)),
          Tab(text: '已完成', icon: Icon(Icons.check_circle)),
          Tab(text: '全部', icon: Icon(Icons.list)),
        ],
      ),
    );
  }
  
  Widget _buildTaskList(TaskStatus status) {
    final tasks = _getFilteredTasks().where((task) => task.status == status).toList();
    
    if (tasks.isEmpty) {
      return _buildEmptyState(status);
    }
    
    return RefreshIndicator(
      onRefresh: _refreshTasks,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TaskCard(
              task: task,
              onTap: () => _navigateToTaskDetail(task),
              onStatusChanged: (newStatus) => _updateTaskStatus(task, newStatus),
              onPriorityChanged: (newPriority) => _updateTaskPriority(task, newPriority),
              onEdit: () => _navigateToTaskEdit(task),
              onDelete: () => _deleteTask(task),
              onStartFocus: () => _startFocusSession(task),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildAllTasksList() {
    final tasks = _getFilteredTasks();
    
    if (tasks.isEmpty) {
      return _buildEmptyState(null);
    }
    
    // 按状态分组显示
    final groupedTasks = <TaskStatus, List<Task>>{};
    for (final task in tasks) {
      groupedTasks.putIfAbsent(task.status, () => []).add(task);
    }
    
    return RefreshIndicator(
      onRefresh: _refreshTasks,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: groupedTasks.length,
        itemBuilder: (context, index) {
          final status = groupedTasks.keys.elementAt(index);
          final statusTasks = groupedTasks[status]!;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '${status.name} (${statusTasks.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...statusTasks.map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TaskCard(
                  task: task,
                  onTap: () => _navigateToTaskDetail(task),
                  onStatusChanged: (newStatus) => _updateTaskStatus(task, newStatus),
                  onPriorityChanged: (newPriority) => _updateTaskPriority(task, newPriority),
                  onEdit: () => _navigateToTaskEdit(task),
                  onDelete: () => _deleteTask(task),
                  onStartFocus: () => _startFocusSession(task),
                ),
              )),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildEmptyState(TaskStatus? status) {
    String message;
    IconData icon;
    
    switch (status) {
      case TaskStatus.pending:
        message = '暂无待开始的任务\n点击右下角按钮创建新任务';
        icon = Icons.pending_actions;
        break;
      case TaskStatus.inProgress:
        message = '暂无进行中的任务\n开始一个任务来专注工作';
        icon = Icons.play_circle_outline;
        break;
      case TaskStatus.completed:
        message = '暂无已完成的任务\n完成任务后会显示在这里';
        icon = Icons.check_circle_outline;
        break;
      default:
        message = '暂无任务\n点击右下角按钮创建第一个任务';
        icon = Icons.task_alt;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          if (status == null || status == TaskStatus.pending) ..[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/tasks/create'),
              icon: const Icon(Icons.add),
              label: const Text('创建任务'),
            ),
          ],
        ],
      ),
    );
  }
  
  List<Task> _getFilteredTasks() {
    List<Task> tasks = _useMockData ? _getMockTasks() : [];
    
    // 应用搜索过滤
    if (_searchQuery.isNotEmpty) {
      tasks = tasks.search(_searchQuery);
    }
    
    // 应用状态过滤
    if (_filterStatus != null) {
      tasks = tasks.where((task) => task.status == _filterStatus).toList();
    }
    
    // 应用优先级过滤
    if (_filterPriority != null) {
      tasks = tasks.where((task) => task.priority == _filterPriority).toList();
    }
    
    // 应用分类过滤
    if (_filterCategory != null) {
      tasks = tasks.where((task) => task.category == _filterCategory).toList();
    }
    
    return tasks;
  }
  
  List<Task> _getMockTasks() {
    final now = DateTime.now();
    return [
      Task(
        id: 1,
        title: '完成项目文档',
        description: '编写项目的技术文档和用户手册',
        priority: TaskPriority.high,
        status: TaskStatus.inProgress,
        estimatedMinutes: 120,
        actualMinutes: 45,
        createdAt: now.subtract(const Duration(days: 2)),
        dueDate: now.add(const Duration(days: 1)),
        tags: ['文档', '项目'],
        category: '工作',
      ),
      Task(
        id: 2,
        title: '学习Flutter状态管理',
        description: '深入学习Riverpod状态管理框架',
        priority: TaskPriority.medium,
        status: TaskStatus.pending,
        estimatedMinutes: 90,
        actualMinutes: 0,
        createdAt: now.subtract(const Duration(days: 1)),
        tags: ['学习', 'Flutter'],
        category: '学习',
      ),
      Task(
        id: 3,
        title: '健身锻炼',
        description: '每日30分钟有氧运动',
        priority: TaskPriority.medium,
        status: TaskStatus.completed,
        estimatedMinutes: 30,
        actualMinutes: 35,
        createdAt: now.subtract(const Duration(days: 1)),
        tags: ['健康', '运动'],
        category: '生活',
      ),
      Task(
        id: 4,
        title: '准备会议材料',
        description: '为明天的项目评审会议准备演示材料',
        priority: TaskPriority.urgent,
        status: TaskStatus.pending,
        estimatedMinutes: 60,
        actualMinutes: 0,
        createdAt: now,
        dueDate: now.add(const Duration(hours: 8)),
        tags: ['会议', '演示'],
        category: '工作',
      ),
      Task(
        id: 5,
        title: '阅读技术书籍',
        description: '阅读《Clean Architecture》第3-5章',
        priority: TaskPriority.low,
        status: TaskStatus.inProgress,
        estimatedMinutes: 75,
        actualMinutes: 25,
        createdAt: now.subtract(const Duration(days: 3)),
        tags: ['阅读', '技术'],
        category: '学习',
      ),
    ];
  }
  
  Future<void> _refreshTasks() async {
    // 模拟刷新延迟
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      setState(() {
        // 在实际应用中，这里会重新加载数据
      });
    }
  }
  
  void _navigateToTaskDetail(Task task) {
    context.go('/tasks/${task.id}');
  }
  
  void _navigateToTaskEdit(Task task) {
    context.go('/tasks/${task.id}/edit');
  }
  
  void _updateTaskStatus(Task task, TaskStatus newStatus) {
    // 在实际应用中，这里会调用业务逻辑层更新任务状态
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('任务"${task.title}"状态已更新为${newStatus.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  void _updateTaskPriority(Task task, TaskPriority newPriority) {
    // 在实际应用中，这里会调用业务逻辑层更新任务优先级
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('任务"${task.title}"优先级已更新为${newPriority.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  void _deleteTask(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除任务'),
        content: Text('确定要删除任务"${task.title}"吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 在实际应用中，这里会调用业务逻辑层删除任务
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('任务"${task.title}"已删除'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
  
  void _startFocusSession(Task task) {
    context.go('/focus?taskId=${task.id}');
  }
  
  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '排序方式',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.priority_high),
              title: const Text('按优先级'),
              onTap: () {
                Navigator.of(context).pop();
                // 实现按优先级排序
              },
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('按创建时间'),
              onTap: () {
                Navigator.of(context).pop();
                // 实现按创建时间排序
              },
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('按截止时间'),
              onTap: () {
                Navigator.of(context).pop();
                // 实现按截止时间排序
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort),
              title: const Text('自定义排序'),
              onTap: () {
                Navigator.of(context).pop();
                // 实现自定义排序
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _exportTasks();
        break;
      case 'import':
        _importTasks();
        break;
      case 'archive':
        _viewArchivedTasks();
        break;
      case 'settings':
        context.go('/settings');
        break;
    }
  }
  
  void _exportTasks() {
    // 实现任务导出功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('任务导出功能开发中...'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  void _importTasks() {
    // 实现任务导入功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('任务导入功能开发中...'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  void _viewArchivedTasks() {
    // 实现查看归档任务功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('归档任务查看功能开发中...'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}