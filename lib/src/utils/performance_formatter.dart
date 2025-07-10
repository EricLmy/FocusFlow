import '../core/cache/cache_manager.dart';
import '../domain/entities/task.dart';

/// 性能优化的格式化工具类
/// 使用缓存来提高频繁调用的格式化方法的性能
class PerformanceFormatter with CacheMixin {
  static final _instance = PerformanceFormatter._internal();
  factory PerformanceFormatter() => _instance;
  PerformanceFormatter._internal();

  /// 格式化任务时间（带缓存）
  String formatTaskTime(Task task) {
    final cacheKey = 'task_time_${task.id}_${task.status}_${task.actualMinutes}_${task.estimatedMinutes}';
    
    return cached(cacheKey, () {
      return _formatTaskTimeInternal(task);
    }, ttl: const Duration(minutes: 10));
  }

  /// 内部格式化任务时间方法
  String _formatTaskTimeInternal(Task task) {
    if (task.status == TaskStatus.completed && task.actualMinutes > 0) {
      return _formatDuration(Duration(minutes: task.actualMinutes));
    } else if (task.estimatedMinutes > 0) {
      return _formatDuration(Duration(minutes: task.estimatedMinutes));
    }
    return '--';
  }

  /// 格式化持续时间（带缓存）
  String formatDuration(Duration duration) {
    final cacheKey = 'duration_${duration.inMinutes}';
    
    return cached(cacheKey, () {
      return _formatDuration(duration);
    }, ttl: const Duration(hours: 1));
  }

  /// 内部格式化持续时间方法
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}分钟';
    }
  }

  /// 格式化任务状态（带缓存）
  String formatTaskStatus(TaskStatus status) {
    final cacheKey = 'status_${status.name}';
    
    return cached(cacheKey, () {
      return _formatTaskStatus(status);
    }, ttl: const Duration(hours: 24));
  }

  /// 内部格式化任务状态方法
  String _formatTaskStatus(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return '待开始';
      case TaskStatus.inProgress:
        return '进行中';
      case TaskStatus.completed:
        return '已完成';
      case TaskStatus.cancelled:
        return '已取消';
    }
  }

  /// 格式化任务优先级（带缓存）
  String formatTaskPriority(TaskPriority priority) {
    final cacheKey = 'priority_${priority.name}';
    
    return cached(cacheKey, () {
      return _formatTaskPriority(priority);
    }, ttl: const Duration(hours: 24));
  }

  /// 内部格式化任务优先级方法
  String _formatTaskPriority(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return '低';
      case TaskPriority.medium:
        return '中';
      case TaskPriority.high:
        return '高';
      case TaskPriority.urgent:
        return '紧急';
    }
  }

  /// 格式化日期时间（带缓存）
  String formatDateTime(DateTime dateTime, {String format = 'yyyy-MM-dd HH:mm'}) {
    final cacheKey = 'datetime_${dateTime.millisecondsSinceEpoch}_$format';
    
    return cached(cacheKey, () {
      return _formatDateTime(dateTime, format);
    }, ttl: const Duration(hours: 1));
  }

  /// 内部格式化日期时间方法
  String _formatDateTime(DateTime dateTime, String format) {
    // 简单的日期格式化实现
    final year = dateTime.year.toString();
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return format
        .replaceAll('yyyy', year)
        .replaceAll('MM', month)
        .replaceAll('dd', day)
        .replaceAll('HH', hour)
        .replaceAll('mm', minute);
  }

  /// 格式化相对时间（带缓存）
  String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final cacheKey = 'relative_${dateTime.millisecondsSinceEpoch}_${now.day}_${now.hour}';
    
    return cached(cacheKey, () {
      return _formatRelativeTime(dateTime, now);
    }, ttl: const Duration(minutes: 30));
  }

  /// 内部格式化相对时间方法
  String _formatRelativeTime(DateTime dateTime, DateTime now) {
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  /// 格式化进度百分比（带缓存）
  String formatProgress(double progress) {
    final cacheKey = 'progress_$progress';
    
    return cached(cacheKey, () {
      final percentage = (progress * 100).round();
      return '$percentage%';
    }, ttl: const Duration(hours: 1));
  }

  /// 格式化文件大小（带缓存）
  String formatFileSize(int bytes) {
    final cacheKey = 'filesize_$bytes';
    
    return cached(cacheKey, () {
      return _formatFileSize(bytes);
    }, ttl: const Duration(hours: 24));
  }

  /// 内部格式化文件大小方法
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
    }
  }

  /// 格式化数字（带缓存）
  String formatNumber(num number, {int? decimalPlaces}) {
    final cacheKey = 'number_${number}_$decimalPlaces';
    
    return cached(cacheKey, () {
      if (decimalPlaces != null) {
        return number.toStringAsFixed(decimalPlaces);
      }
      return number.toString();
    }, ttl: const Duration(hours: 1));
  }

  /// 格式化任务标签列表（带缓存）
  String formatTaskTags(List<String> tags) {
    final cacheKey = 'tags_${tags.join('_')}';
    
    return cached(cacheKey, () {
      if (tags.isEmpty) {
        return '无标签';
      }
      return tags.join(', ');
    }, ttl: const Duration(hours: 1));
  }

  /// 格式化任务完成率（带缓存）
  String formatCompletionRate(int completed, int total) {
    final cacheKey = 'completion_${completed}_$total';
    
    return cached(cacheKey, () {
      if (total == 0) {
        return '0%';
      }
      final rate = (completed / total * 100).round();
      return '$rate%';
    }, ttl: const Duration(minutes: 30));
  }

  /// 批量格式化任务时间
  Map<String, String> formatTaskTimesBatch(List<Task> tasks) {
    final result = <String, String>{};
    for (final task in tasks) {
      result[task.id.toString()] = formatTaskTime(task);
    }
    return result;
  }

  /// 预热缓存 - 预先计算常用的格式化结果
  void warmupCache() {
    // 预热状态格式化
    for (final status in TaskStatus.values) {
      formatTaskStatus(status);
    }
    
    // 预热优先级格式化
    for (final priority in TaskPriority.values) {
      formatTaskPriority(priority);
    }
    
    // 预热进度格式化
    for (int i = 0; i <= 100; i += 10) {
      formatProgress(i / 100.0);
    }
    
    // 预热常用持续时间
    final commonDurations = [
      const Duration(minutes: 15),
      const Duration(minutes: 30),
      const Duration(hours: 1),
      const Duration(hours: 2),
      const Duration(hours: 4),
      const Duration(hours: 8),
    ];
    
    for (final duration in commonDurations) {
      formatDuration(duration);
    }
  }

  /// 获取缓存统计信息
  Map<String, dynamic> getCacheStats() {
    return {
      'cache_stats': 'Cache statistics not available',
      'cache_size': 0,
    };
  }

  /// 清理过期缓存
  void cleanupCache() {
    clearCache();
  }
}

/// 全局格式化器实例
final performanceFormatter = PerformanceFormatter();

/// 格式化器扩展方法
extension TaskFormatterExtension on Task {
  /// 获取格式化的任务时间
  String get formattedTime => performanceFormatter.formatTaskTime(this);
  
  /// 获取格式化的任务状态
  String get formattedStatus => performanceFormatter.formatTaskStatus(status);
  
  /// 获取格式化的任务优先级
  String get formattedPriority => performanceFormatter.formatTaskPriority(priority);
  
  /// 获取格式化的进度
  String get formattedProgress => performanceFormatter.formatProgress(progress);
  
  /// 获取格式化的标签
  String get formattedTags => performanceFormatter.formatTaskTags(tags);
}

/// 日期时间格式化扩展
extension DateTimeFormatterExtension on DateTime {
  /// 获取格式化的日期时间
  String get formatted => performanceFormatter.formatDateTime(this);
  
  /// 获取相对时间
  String get relativeTime => performanceFormatter.formatRelativeTime(this);
}

/// 数字格式化扩展
extension NumberFormatterExtension on num {
  /// 获取格式化的数字
  String formatted({int? decimalPlaces}) => 
      performanceFormatter.formatNumber(this, decimalPlaces: decimalPlaces);
}