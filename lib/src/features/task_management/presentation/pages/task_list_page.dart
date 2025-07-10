import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../domain/entities/task.dart';
import '../../../../core/database/database_service.dart';
import '../widgets/task_edit_dialog.dart';
import '../providers/task_provider.dart';
import 'dart:math' as math;

/// 任务列表页面
class TaskListPage extends ConsumerStatefulWidget {
  const TaskListPage({super.key});
  
  @override
  ConsumerState<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends ConsumerState<TaskListPage> {
  String _selectedStatus = 'all';
  String _selectedPriority = 'all';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isListView = true;
  bool _isInitialized = false;
  String _selectedTimeRange = 'thisWeek'; // 'today', 'thisWeek', 'thisMonth', 'custom'
  
  @override
  void initState() {
    super.initState();
    _initializeData();
  }
  
  Future<void> _initializeData() async {
    try {
      // 确保数据库服务已初始化
      await DatabaseService.instance.initialize();
      
      // 设置本周时间范围
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      
      setState(() {
        _startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        _endDate = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day);
        _isInitialized = true;
      });
      
      // 加载本周任务
      await ref.read(taskListProvider.notifier).loadThisWeekTasks();
    } catch (e) {
      print('初始化数据失败: $e');
      setState(() {
        _isInitialized = true;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('任务列表'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddTaskDialog,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF667eea), Color(0xFFf8f9fa)],
            stops: [0.0, 0.3],
          ),
        ),
        child: Column(
          children: [
            _buildFilterSection(),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 20),
                decoration: const BoxDecoration(
                  color: Color(0xFFf8f9fa),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: RefreshIndicator(
                  onRefresh: _refreshTasks,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildSectionHeader(),
                          const SizedBox(height: 16),
                          _buildTaskList(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          _buildTimeRangeSelector(),
          const SizedBox(height: 12),
          _buildFilterBar(),
          const SizedBox(height: 12),
          _buildStatsCards(),
        ],
      ),
    );
  }
  
  Widget _buildFilterBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildCompactFilter(
              label: '状态',
              value: _getStatusLabel(_selectedStatus),
              onTap: () => _showStatusPicker(),
            ),
            const SizedBox(width: 12),
            _buildCompactFilter(
              label: '优先级',
              value: _getPriorityLabel(_selectedPriority),
              onTap: () => _showPriorityPicker(),
            ),
            const SizedBox(width: 12),
            _buildCompactFilter(
              label: '开始',
              value: _startDate != null 
                  ? '${_startDate!.month}/${_startDate!.day}'
                  : '选择',
              onTap: () => _selectDate(true),
            ),
            const SizedBox(width: 12),
            _buildCompactFilter(
              label: '结束',
              value: _endDate != null 
                  ? '${_endDate!.month}/${_endDate!.day}'
                  : '选择',
              onTap: () => _selectDate(false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactFilter({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFE9ECEF),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF6C757D),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF2c3e50),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending': return '待办';
      case 'inProgress': return '进行中';
      case 'completed': return '已完成';
      default: return '全部';
    }
  }

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'high': return '高';
      case 'medium': return '中';
      case 'low': return '低';
      default: return '全部';
    }
  }

  void _showStatusPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('选择状态', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ...[
              {'value': 'all', 'label': '全部'},
              {'value': 'pending', 'label': '待办'},
              {'value': 'inProgress', 'label': '进行中'},
              {'value': 'completed', 'label': '已完成'},
            ].map((item) => ListTile(
              title: Text(item['label']!),
              onTap: () {
                setState(() {
                  _selectedStatus = item['value']!;
                });
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showPriorityPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('选择优先级', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ...[
              {'value': 'all', 'label': '全部'},
              {'value': 'high', 'label': '高优先级'},
              {'value': 'medium', 'label': '中优先级'},
              {'value': 'low', 'label': '低优先级'},
            ].map((item) => ListTile(
              title: Text(item['label']!),
              onTap: () {
                setState(() {
                  _selectedPriority = item['value']!;
                });
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '时间范围',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2c3e50),
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final buttonWidth = (constraints.maxWidth - 24) / 3; // 3个按钮，2个间距
              return Row(
                children: [
                  SizedBox(
                    width: buttonWidth,
                    child: _buildTimeRangeButton('今日', 'today'),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: buttonWidth,
                    child: _buildTimeRangeButton('本周', 'thisWeek'),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: buttonWidth,
                    child: _buildTimeRangeButton('本月', 'thisMonth'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeButton(String label, String value) {
    final isSelected = _selectedTimeRange == value;
    return GestureDetector(
      onTap: () => _selectTimeRange(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF667eea) : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF667eea) : const Color(0xFFE9ECEF),
            width: 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF2c3e50),
          ),
        ),
      ),
    );
  }

  void _selectTimeRange(String range) {
    setState(() {
      _selectedTimeRange = range;
    });
    
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;
    
    switch (range) {
      case 'today':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'thisWeek':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        endDate = startDate.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        break;
      case 'thisMonth':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      default:
        return;
    }
    
    setState(() {
      _startDate = startDate;
      _endDate = endDate;
    });
    
    _loadTasksBasedOnDateRange();
  }

  Future<void> _refreshTasks() async {
    await ref.read(taskListProvider.notifier).refreshTasks();
    _loadTasksBasedOnDateRange();
  }


  
  Widget _buildStatsCards() {
    final filters = {
      'status': _selectedStatus,
      'priority': _selectedPriority,
      'startDate': _startDate,
      'endDate': _endDate,
    };
    final filteredTasks = ref.watch(filteredTasksProvider(filters));
    final totalTasks = filteredTasks.length;
    final pendingTasks = filteredTasks.where((task) => task.status == TaskStatus.pending).length;
    final completedTasks = filteredTasks.where((task) => task.status == TaskStatus.completed).length;
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(totalTasks.toString(), '总任务'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(pendingTasks.toString(), '待办'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(completedTasks.toString(), '已完成'),
        ),
      ],
    );
  }
  
  Widget _buildStatCard(String number, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            number,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '任务管理',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2c3e50),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFecf0f1),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(2),
          child: Row(
            children: [
              _buildToggleButton('列表', _isListView, () {
                setState(() {
                  _isListView = true;
                });
              }),
              _buildToggleButton('网格', !_isListView, () {
                setState(() {
                  _isListView = false;
                });
              }),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildToggleButton(String text, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? const Color(0xFF667eea) : const Color(0xFF7f8c8d),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTaskList() {
    if (!_isInitialized) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    final taskListState = ref.watch(taskListProvider);
    
    if (taskListState.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (taskListState.error != null) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              taskListState.error!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(taskListProvider.notifier).clearError();
                _loadTasksBasedOnDateRange();
              },
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
    
    final filters = {
      'status': _selectedStatus,
      'priority': _selectedPriority,
      'startDate': _startDate,
      'endDate': _endDate,
    };
    final filteredTasks = ref.watch(filteredTasksProvider(filters));
    
    if (filteredTasks.isEmpty) {
      return _buildEmptyState();
    }
    
    if (_isListView) {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filteredTasks.length,
        itemBuilder: (context, index) {
          return _buildTaskItem(filteredTasks[index]);
        },
      );
    } else {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: filteredTasks.length,
        itemBuilder: (context, index) {
          return _buildTaskGridItem(filteredTasks[index]);
        },
      );
    }
  }
  
  Widget _buildTaskItem(Task task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
        border: Border(
          left: BorderSide(
            color: _getPriorityColor(task.priority),
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildTaskCheckbox(task),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2c3e50),
                    decoration: task.status == TaskStatus.completed
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTaskTime(task),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildPriorityBadge(task.priority),
                  ],
                ),
              ],
            ),
          ),
          _buildTaskActions(task),
        ],
      ),
    );
  }
  
  Widget _buildTaskCheckbox(Task task) {
    final isCompleted = task.status == TaskStatus.completed;
    return GestureDetector(
      onTap: () => _toggleTaskStatus(task.id!),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: isCompleted ? const Color(0xFF2ecc71) : Colors.transparent,
          border: Border.all(
            color: isCompleted ? const Color(0xFF2ecc71) : const Color(0xFFbdc3c7),
            width: 2,
          ),
          shape: BoxShape.circle,
        ),
        child: isCompleted
            ? const Icon(
                Icons.check,
                size: 12,
                color: Colors.white,
              )
            : null,
      ),
    );
  }
  
  Widget _buildPriorityBadge(TaskPriority priority) {
    final config = _getPriorityConfig(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: config['bgColor'],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        config['text'],
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: config['textColor'],
        ),
      ),
    );
  }
  
  Widget _buildTaskActions(Task task) {
    return Row(
      children: [
        _buildActionButton(
          icon: Icons.edit,
          color: const Color(0xFF2196f3),
          onTap: () => _editTask(task),
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.delete,
          color: const Color(0xFFf44336),
          onTap: () => _deleteTask(task),
        ),
      ],
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 14,
          color: color,
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(60),
      child: Column(
        children: [
          Icon(
             Icons.task_alt,
             size: 48,
             color: Colors.grey[400],
           ),
          const SizedBox(height: 16),
          Text(
            '暂无任务',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右上角 + 号创建第一个任务',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
  
  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => TaskEditDialog(
        onTaskSaved: (task) async {
          await ref.read(taskListProvider.notifier).createTask(task);
        },
      ),
    );
  }

  void _toggleTaskStatus(int taskId) async {
    final taskListState = ref.read(taskListProvider);
    final task = taskListState.tasks.firstWhere((task) => task.id == taskId);
    
    TaskStatus newStatus;
    switch (task.status) {
      case TaskStatus.pending:
        newStatus = TaskStatus.inProgress;
        break;
      case TaskStatus.inProgress:
        newStatus = TaskStatus.completed;
        break;
      case TaskStatus.completed:
        newStatus = TaskStatus.pending;
        break;
      case TaskStatus.cancelled:
        newStatus = TaskStatus.pending;
        break;
    }
    
    await ref.read(taskListProvider.notifier).toggleTaskStatus(taskId, newStatus);
  }

  void _editTask(Task task) {
    showDialog(
      context: context,
      builder: (context) => TaskEditDialog(
        task: task,
        onTaskSaved: (updatedTask) async {
          await ref.read(taskListProvider.notifier).updateTask(updatedTask);
        },
      ),
    );
  }

  void _deleteTask(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFE74C3C),
              size: 28,
            ),
            SizedBox(width: 12),
            Text(
              '确认删除',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2c3e50),
              ),
            ),
          ],
        ),
        content: Text(
          '确定要删除任务「${task.title}」吗？\n此操作无法撤销。',
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF7f8c8d),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '取消',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF7f8c8d),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              await ref.read(taskListProvider.notifier).deleteTask(task.id!);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('任务「${task.title}」已删除'),
                    backgroundColor: const Color(0xFF2ECC71),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              '删除',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
       ),
     );
  }
  
  void _loadTasksBasedOnDateRange() {
    if (_startDate != null && _endDate != null) {
      ref.read(taskListProvider.notifier).loadTasksByDateRange(_startDate!, _endDate!);
    } else {
      ref.read(taskListProvider.notifier).loadAllTasks();
    }
  }
 
    
  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
      case TaskPriority.urgent:
        return const Color(0xFFe74c3c);
      case TaskPriority.medium:
        return const Color(0xFFf39c12);
      case TaskPriority.low:
        return const Color(0xFF2ecc71);
    }
  }
  
  Map<String, dynamic> _getPriorityConfig(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
      case TaskPriority.urgent:
        return {
          'text': '高优先级',
          'bgColor': const Color(0xFFfee),
          'textColor': const Color(0xFFe74c3c),
        };
      case TaskPriority.medium:
        return {
          'text': '中优先级',
          'bgColor': const Color(0xFFfef9e7),
          'textColor': const Color(0xFFf39c12),
        };
      case TaskPriority.low:
        return {
          'text': '低优先级',
          'bgColor': const Color(0xFFeafaf1),
          'textColor': const Color(0xFF2ecc71),
        };
    }
  }
  
  String _formatTaskTime(Task task) {
    final now = DateTime.now();
    final createdAt = task.createdAt;
    
    final timeFormat = '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    if (createdAt.day == now.day && createdAt.month == now.month && createdAt.year == now.year) {
      return '今日 $timeFormat';
    } else {
      return '${createdAt.month.toString().padLeft(2, '0')}/${createdAt.day.toString().padLeft(2, '0')} $timeFormat';
    }
  }
  
  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      setState(() {
        _selectedTimeRange = 'custom';
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
      
      // 重新加载任务数据
      _loadTasksBasedOnDateRange();
    }
  }

  Widget _buildTaskGridItem(Task task) {
    return Container(
      padding: const EdgeInsets.all(12),
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
        border: Border(
          left: BorderSide(
            color: _getPriorityColor(task.priority),
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildTaskCheckbox(task),
              const Spacer(),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  size: 16,
                  color: Color(0xFF7f8c8d),
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    _editTask(task);
                  } else if (value == 'delete') {
                    _deleteTask(task);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('编辑'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('删除', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2c3e50),
                    decoration: task.status == TaskStatus.completed
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                if (task.description != null && task.description!.isNotEmpty)
                  Text(
                    task.description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 10,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _formatTaskTime(task),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _buildPriorityBadge(task.priority),
              ],
            ),
          ),
        ],
      ),
    );
  }
}