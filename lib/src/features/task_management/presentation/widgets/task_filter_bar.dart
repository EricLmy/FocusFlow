import 'package:flutter/material.dart';
import '../../../../domain/entities/task.dart';

/// 任务筛选栏组件
class TaskFilterBar extends StatelessWidget {
  final TaskStatus? selectedStatus;
  final TaskPriority? selectedPriority;
  final String? selectedCategory;
  final ValueChanged<TaskStatus?>? onStatusChanged;
  final ValueChanged<TaskPriority?>? onPriorityChanged;
  final ValueChanged<String?>? onCategoryChanged;
  final VoidCallback? onClearFilters;
  
  const TaskFilterBar({
    super.key,
    this.selectedStatus,
    this.selectedPriority,
    this.selectedCategory,
    this.onStatusChanged,
    this.onPriorityChanged,
    this.onCategoryChanged,
    this.onClearFilters,
  });
  
  @override
  Widget build(BuildContext context) {
    final hasFilters = selectedStatus != null || 
                      selectedPriority != null || 
                      selectedCategory != null;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // 状态筛选
            _buildStatusFilter(context),
            const SizedBox(width: 8),
            // 优先级筛选
            _buildPriorityFilter(context),
            const SizedBox(width: 8),
            // 分类筛选
            _buildCategoryFilter(context),
            if (hasFilters) ...[
              const SizedBox(width: 8),
              // 清除筛选
              _buildClearButton(context),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusFilter(BuildContext context) {
    return PopupMenuButton<TaskStatus?>(
      initialValue: selectedStatus,
      onSelected: onStatusChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: selectedStatus != null 
                ? Theme.of(context).primaryColor 
                : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(20),
          color: selectedStatus != null 
              ? Theme.of(context).primaryColor.withAlpha((255 * 0.1).round())
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list,
              size: 16,
              color: selectedStatus != null 
                  ? Theme.of(context).primaryColor 
                  : Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              selectedStatus?.name ?? '状态',
              style: TextStyle(
                color: selectedStatus != null 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: null,
          child: Text('全部状态'),
        ),
        ...TaskStatus.values.map(
          (status) => PopupMenuItem(
            value: status,
            child: Text(_getStatusText(status)),
          ),
        ),
      ],
    );
  }
  
  Widget _buildPriorityFilter(BuildContext context) {
    return PopupMenuButton<TaskPriority?>(
      initialValue: selectedPriority,
      onSelected: onPriorityChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: selectedPriority != null 
                ? Theme.of(context).primaryColor 
                : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(20),
          color: selectedPriority != null 
              ? Theme.of(context).primaryColor.withAlpha((255 * 0.1).round())
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.priority_high,
              size: 16,
              color: selectedPriority != null 
                  ? Theme.of(context).primaryColor 
                  : Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              selectedPriority?.name ?? '优先级',
              style: TextStyle(
                color: selectedPriority != null 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: null,
          child: Text('全部优先级'),
        ),
        ...TaskPriority.values.map(
          (priority) => PopupMenuItem(
            value: priority,
            child: Text(_getPriorityText(priority)),
          ),
        ),
      ],
    );
  }
  
  Widget _buildCategoryFilter(BuildContext context) {
    return PopupMenuButton<String?>(
      initialValue: selectedCategory,
      onSelected: onCategoryChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: selectedCategory != null 
                ? Theme.of(context).primaryColor 
                : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(20),
          color: selectedCategory != null 
              ? Theme.of(context).primaryColor.withAlpha((255 * 0.1).round())
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.category,
              size: 16,
              color: selectedCategory != null 
                  ? Theme.of(context).primaryColor 
                  : Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              selectedCategory ?? '分类',
              style: TextStyle(
                color: selectedCategory != null 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: null,
          child: Text('全部分类'),
        ),
        const PopupMenuItem(
          value: '工作',
          child: Text('工作'),
        ),
        const PopupMenuItem(
          value: '学习',
          child: Text('学习'),
        ),
        const PopupMenuItem(
          value: '生活',
          child: Text('生活'),
        ),
        const PopupMenuItem(
          value: '其他',
          child: Text('其他'),
        ),
      ],
    );
  }
  
  Widget _buildClearButton(BuildContext context) {
    return GestureDetector(
      onTap: onClearFilters,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.clear,
              size: 16,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              '清除',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return '待处理';
      case TaskStatus.inProgress:
        return '进行中';
      case TaskStatus.completed:
        return '已完成';
      case TaskStatus.cancelled:
        return '已取消';
    }
  }
  
  String _getPriorityText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent:
        return '紧急';
      case TaskPriority.high:
        return '高';
      case TaskPriority.medium:
        return '中';
      case TaskPriority.low:
        return '低';
    }
  }
}