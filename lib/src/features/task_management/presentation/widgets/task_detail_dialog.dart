import 'package:flutter/material.dart';

import '../../../../domain/entities/task.dart';
import '../../../../core/router/app_router.dart';

/// 任务详情弹窗组件
/// 显示任务详细信息，允许修改进度，支持开始专注功能
class TaskDetailDialog extends StatefulWidget {
  final Task task;
  final Function(Task)? onTaskUpdated;

  const TaskDetailDialog({
    super.key,
    required this.task,
    this.onTaskUpdated,
  });

  @override
  State<TaskDetailDialog> createState() => _TaskDetailDialogState();
}

class _TaskDetailDialogState extends State<TaskDetailDialog> {
  late double _currentProgress;
  late Task _updatedTask;

  @override
  void initState() {
    super.initState();
    _currentProgress = widget.task.progress;
    _updatedTask = widget.task;
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent:
      case TaskPriority.high:
        return const Color(0xFFE74C3C);
      case TaskPriority.medium:
        return const Color(0xFF3498DB);
      case TaskPriority.low:
        return const Color(0xFF2ECC71);
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((255 * 0.3).round()),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTaskNameAndPrioritySection(),
                    const SizedBox(height: 20),
                    _buildProgressSection(),
                    const SizedBox(height: 20),
                    _buildDescriptionSection(),
                    const SizedBox(height: 20),
                    _buildTimeSection(),
                  ],
                ),
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          const Text(
            '任务详情',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2c3e50),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              color: Color(0xFF7f8c8d),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskNameAndPrioritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '任务名称',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7f8c8d),
              ),
            ),
            const Spacer(),
            Container(
               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
               decoration: BoxDecoration(
                 color: _getPriorityColor(widget.task.priority),
                 borderRadius: BorderRadius.circular(20),
                 boxShadow: [
                   BoxShadow(
                     color: _getPriorityColor(widget.task.priority).withAlpha((255 * 0.3).round()),
                     blurRadius: 8,
                     offset: const Offset(0, 2),
                   ),
                 ],
               ),
               child: Text(
                 _getPriorityText(widget.task.priority),
                 style: TextStyle(
                   color: Colors.white,
                   fontSize: 14,
                   fontWeight: FontWeight.w700,
                   letterSpacing: 0.5,
                 ),
               ),
             ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Color(0xFFECF0F1),
              width: 1,
            ),
          ),
          child: Text(
            widget.task.title,
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF2c3e50),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }



  Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '完成进度',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF7f8c8d),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _currentProgress = (_currentProgress - 0.1).clamp(0.0, 1.0);
                  // 根据进度自动更新任务状态
                  TaskStatus newStatus;
                  DateTime? completedAt = _updatedTask.completedAt;
                  
                  if (_currentProgress <= 0.0) {
                    // 进度为0%时，状态为未开始
                    newStatus = TaskStatus.pending;
                    completedAt = null;
                  } else if (_currentProgress >= 1.0) {
                    // 进度为100%时，状态为已完成
                    newStatus = TaskStatus.completed;
                    if (_updatedTask.status != TaskStatus.completed) {
                      completedAt = DateTime.now();
                    }
                  } else {
                    // 进度在0%-100%之间时，状态为进行中
                    newStatus = TaskStatus.inProgress;
                    completedAt = null;
                  }
                  
                  _updatedTask = _updatedTask.copyWith(
                    progress: _currentProgress,
                    status: newStatus,
                    completedAt: completedAt,
                    updatedAt: DateTime.now(),
                  );
                });
              },
              icon: Icon(
                Icons.remove_circle_outline,
                color: Color(0xFF667eea),
                size: 32,
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    '${(_currentProgress * 100).round()}%',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2c3e50),
                    ),
                  ),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _currentProgress,
                    backgroundColor: Color(0xFFECF0F1),
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
                    minHeight: 8,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _currentProgress = (_currentProgress + 0.1).clamp(0.0, 1.0);
                  // 根据进度自动更新任务状态
                  TaskStatus newStatus;
                  DateTime? completedAt = _updatedTask.completedAt;
                  
                  if (_currentProgress <= 0.0) {
                    // 进度为0%时，状态为未开始
                    newStatus = TaskStatus.pending;
                    completedAt = null;
                  } else if (_currentProgress >= 1.0) {
                    // 进度为100%时，状态为已完成
                    newStatus = TaskStatus.completed;
                    if (_updatedTask.status != TaskStatus.completed) {
                      completedAt = DateTime.now();
                    }
                  } else {
                    // 进度在0%-100%之间时，状态为进行中
                    newStatus = TaskStatus.inProgress;
                    completedAt = null;
                  }
                  
                  _updatedTask = _updatedTask.copyWith(
                    progress: _currentProgress,
                    status: newStatus,
                    completedAt: completedAt,
                    updatedAt: DateTime.now(),
                  );
                });
              },
              icon: Icon(
                Icons.add_circle_outline,
                color: Color(0xFF667eea),
                size: 32,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '时间信息',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF7f8c8d),
          ),
        ),
        const SizedBox(height: 12),
        _buildTimeItem('创建时间', _formatDateTime(widget.task.createdAt)),
        const SizedBox(height: 12),
        // 开始时间
        _buildTimeItem(
          '开始时间', 
          (widget.task.status == TaskStatus.inProgress || widget.task.status == TaskStatus.completed)
              ? (widget.task.updatedAt != null 
                  ? _formatDateTime(widget.task.updatedAt!) 
                  : '未开始')
              : '未开始'
        ),
        const SizedBox(height: 12),
        // 完成时间
        _buildTimeItem(
          '完成时间', 
          widget.task.status == TaskStatus.completed
              ? (widget.task.updatedAt != null 
                  ? _formatDateTime(widget.task.updatedAt!) 
                  : '未完成')
              : '未完成'
        ),
        if (widget.task.completedAt != null) ...[
          const SizedBox(height: 12),
          _buildTimeItem('实际完成时间', _formatDateTime(widget.task.completedAt!)),
        ],
      ],
    );
  }

  Widget _buildTimeItem(String label, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF7f8c8d),
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Color(0xFFECF0F1),
              width: 1,
            ),
          ),
          child: Text(
            time,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF2c3e50),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '任务详情',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF7f8c8d),
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Color(0xFFECF0F1),
              width: 1,
            ),
          ),
          child: Text(
            widget.task.description?.isNotEmpty == true 
                ? widget.task.description! 
                : '暂无任务详情描述',
            style: TextStyle(
              fontSize: 16,
              color: widget.task.description?.isNotEmpty == true 
                  ? Color(0xFF2c3e50) 
                  : Color(0xFF95a5a6),
              height: 1.5,
              fontStyle: widget.task.description?.isNotEmpty == true 
                  ? FontStyle.normal 
                  : FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Color(0xFFECF0F1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () {
                // 保存进度更新
                if (widget.onTaskUpdated != null) {
                  widget.onTaskUpdated!(_updatedTask);
                }
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(
                    color: Color(0xFF2ECC71),
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.save,
                    color: Color(0xFF2ECC71),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '保存',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2ECC71),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // 保存进度更新
                if (widget.onTaskUpdated != null) {
                  widget.onTaskUpdated!(_updatedTask);
                }
                Navigator.of(context).pop();
                // 跳转到专注页面
                NavigationHelper.goToFocus(context, taskId: widget.task.id);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF667eea),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.play_circle_filled,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '开始专注',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
}