import 'package:flutter/material.dart';

/// 添加任务浮动按钮
class AddTaskFab extends StatelessWidget {
  final VoidCallback? onPressed;
  
  const AddTaskFab({
    super.key,
    this.onPressed,
  });
  
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: '添加任务',
      child: const Icon(Icons.add),
    );
  }
}