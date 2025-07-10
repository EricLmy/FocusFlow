import 'package:flutter/material.dart';
import '../../../../domain/entities/task.dart';

/// 任务状态显示组件
/// 提供统一的任务状态视觉表示
class TaskStatusWidget extends StatelessWidget {
  final Task task;
  final TaskStatusStyle style;
  final bool showProgress;
  final bool showText;

  const TaskStatusWidget({
    super.key,
    required this.task,
    this.style = TaskStatusStyle.chip,
    this.showProgress = false,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return switch (style) {
      TaskStatusStyle.chip => _buildChipStyle(context),
      TaskStatusStyle.icon => _buildIconStyle(context),
      TaskStatusStyle.badge => _buildBadgeStyle(context),
      TaskStatusStyle.indicator => _buildIndicatorStyle(context),
    };
  }

  Widget _buildChipStyle(BuildContext context) {
    final statusInfo = _getStatusInfo();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusInfo.color.withAlpha((255 * 0.1).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusInfo.color.withAlpha((255 * 0.3).round())),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusInfo.icon,
            size: 14,
            color: statusInfo.color,
          ),
          if (showText) ...[
            const SizedBox(width: 4),
            Text(
              showProgress ? _getStatusTextWithProgress() : statusInfo.text,
              style: TextStyle(
                color: statusInfo.color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIconStyle(BuildContext context) {
    final statusInfo = _getStatusInfo();
    
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: statusInfo.color,
        shape: BoxShape.circle,
      ),
      child: Icon(
        statusInfo.icon,
        size: 14,
        color: Colors.white,
      ),
    );
  }

  Widget _buildBadgeStyle(BuildContext context) {
    final statusInfo = _getStatusInfo();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: statusInfo.color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        showProgress ? _getStatusTextWithProgress() : statusInfo.text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildIndicatorStyle(BuildContext context) {
    final statusInfo = _getStatusInfo();
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: statusInfo.color,
            shape: BoxShape.circle,
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 6),
          Text(
            showProgress ? _getStatusTextWithProgress() : statusInfo.text,
            style: TextStyle(
              color: statusInfo.color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ]
      ],
    );
  }

  TaskStatusInfo _getStatusInfo() {
    switch (task.status) {
      case TaskStatus.pending:
        return TaskStatusInfo(
          text: '未开始',
          color: Colors.grey,
          icon: Icons.radio_button_unchecked,
        );
      case TaskStatus.inProgress:
        return TaskStatusInfo(
          text: '进行中',
          color: Colors.blue,
          icon: Icons.play_circle_outline,
        );
      case TaskStatus.completed:
        return TaskStatusInfo(
          text: '已完成',
          color: Colors.green,
          icon: Icons.check_circle,
        );
      case TaskStatus.cancelled:
        return TaskStatusInfo(
          text: '已取消',
          color: Colors.red,
          icon: Icons.cancel,
        );
    }
  }

  String _getStatusTextWithProgress() {
    final statusInfo = _getStatusInfo();
    if (task.status == TaskStatus.inProgress && task.progress > 0) {
      final percentage = (task.progress * 100).round();
      return '${statusInfo.text} $percentage%';
    }
    return statusInfo.text;
  }
}

/// 任务进度显示组件
class TaskProgressWidget extends StatelessWidget {
  final Task task;
  final double? width;
  final double height;
  final bool showPercentage;
  final ProgressStyle style;

  const TaskProgressWidget({
    super.key,
    required this.task,
    this.width,
    this.height = 6,
    this.showPercentage = false,
    this.style = ProgressStyle.linear,
  });

  @override
  Widget build(BuildContext context) {
    return switch (style) {
      ProgressStyle.linear => _buildLinearProgress(context),
      ProgressStyle.circular => _buildCircularProgress(context),
      ProgressStyle.arc => _buildArcProgress(context),
    };
  }

  Widget _buildLinearProgress(BuildContext context) {
    final progress = task.progress.clamp(0.0, 1.0);
    final statusInfo = _getStatusInfo();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: statusInfo.color,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          ),
        ),
        if (showPercentage) ...[
          const SizedBox(height: 4),
          Text(
            '${(progress * 100).round()}%',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCircularProgress(BuildContext context) {
    final progress = task.progress.clamp(0.0, 1.0);
    final statusInfo = _getStatusInfo();
    
    return SizedBox(
      width: width ?? 40,
      height: width ?? 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(statusInfo.color),
            strokeWidth: 3,
          ),
          if (showPercentage)
            Text(
              '${(progress * 100).round()}%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: statusInfo.color,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildArcProgress(BuildContext context) {
    final progress = task.progress.clamp(0.0, 1.0);
    final statusInfo = _getStatusInfo();
    
    return CustomPaint(
      size: Size(width ?? 60, (width ?? 60) / 2),
      painter: ArcProgressPainter(
        progress: progress,
        color: statusInfo.color,
        backgroundColor: Colors.grey.shade200,
      ),
      child: showPercentage
          ? Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  '${(progress * 100).round()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusInfo.color,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  TaskStatusInfo _getStatusInfo() {
    switch (task.status) {
      case TaskStatus.pending:
        return TaskStatusInfo(
          text: '未开始',
          color: Colors.grey,
          icon: Icons.radio_button_unchecked,
        );
      case TaskStatus.inProgress:
        return TaskStatusInfo(
          text: '进行中',
          color: Colors.blue,
          icon: Icons.play_circle_outline,
        );
      case TaskStatus.completed:
        return TaskStatusInfo(
          text: '已完成',
          color: Colors.green,
          icon: Icons.check_circle,
        );
      case TaskStatus.cancelled:
        return TaskStatusInfo(
          text: '已取消',
          color: Colors.red,
          icon: Icons.cancel,
        );
    }
  }
}

/// 弧形进度条画笔
class ArcProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  ArcProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    this.strokeWidth = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - strokeWidth / 2;
    
    // 绘制背景弧
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14, // 180度开始
      3.14, // 180度弧长
      false,
      backgroundPaint,
    );
    
    // 绘制进度弧
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14, // 180度开始
      3.14 * progress, // 根据进度计算弧长
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! ArcProgressPainter ||
        oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

/// 任务状态信息
class TaskStatusInfo {
  final String text;
  final Color color;
  final IconData icon;

  const TaskStatusInfo({
    required this.text,
    required this.color,
    required this.icon,
  });
}

/// 任务状态显示样式
enum TaskStatusStyle {
  chip,      // 芯片样式
  icon,      // 图标样式
  badge,     // 徽章样式
  indicator, // 指示器样式
}

/// 进度条样式
enum ProgressStyle {
  linear,   // 线性进度条
  circular, // 圆形进度条
  arc,      // 弧形进度条
}