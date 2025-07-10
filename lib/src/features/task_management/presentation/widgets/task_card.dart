import 'package:flutter/material.dart';
import '../../../../domain/entities/task.dart';

/// 任务卡片组件，根据UI原型重新设计
class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onStartFocus;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleComplete;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onEdit,
    this.onStartFocus,
    this.onDelete,
    this.onToggleComplete,
  });

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent:
      case TaskPriority.high:
        return const Color(0xFFe74c3c);
      case TaskPriority.medium:
        return const Color(0xFFf39c12);
      case TaskPriority.low:
        return const Color(0xFF27ae60);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.status == TaskStatus.completed;
    return GestureDetector(
      onTap: isCompleted ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        margin: const EdgeInsets.only(bottom: 12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              spreadRadius: 0,
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 优先级指示器
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: _getPriorityColor(task.priority),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // 任务复选框
            _buildTaskCheckbox(),
            const SizedBox(width: 12),
            // 任务内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isCompleted ? const Color(0xFF7f8c8d) : const Color(0xFF2c3e50),
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      decorationColor: isCompleted ? const Color(0xFF7f8c8d) : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '优先级: ${task.priorityText}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7f8c8d),
                    ),
                  ),
                ],
              ),
            ),
            // 完成度显示
            _buildCompletionBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCheckbox() {
    final isCompleted = task.status == TaskStatus.completed;
    return GestureDetector(
      onTap: onToggleComplete,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: isCompleted ? const Color(0xFF2ecc71) : Colors.white,
          border: Border.all(
            color: isCompleted ? const Color(0xFF2ecc71) : const Color(0xFFbdc3c7),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(10),
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

  Widget _buildCompletionBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: task.status == TaskStatus.completed 
            ? const Color(0xFF27ae60) 
            : const Color(0xFF3498db),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${(task.progress * 100).round()}%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}