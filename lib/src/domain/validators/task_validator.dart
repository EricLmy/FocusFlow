import '../entities/task.dart';
import '../../core/utils/result.dart';

/// 任务验证器
/// 集中处理任务数据验证逻辑
class TaskValidator {
  /// 验证任务创建数据
  static Result<void, String> validateForCreation(Task task) {
    // 验证标题
    final titleValidation = _validateTitle(task.title);
    if (titleValidation.isFailure) {
      return titleValidation;
    }
    
    // 验证描述长度
    final descriptionValidation = _validateDescription(task.description);
    if (descriptionValidation.isFailure) {
      return descriptionValidation;
    }
    
    // 验证预估时间
    final estimatedTimeValidation = _validateEstimatedTime(task.estimatedMinutes);
    if (estimatedTimeValidation.isFailure) {
      return estimatedTimeValidation;
    }
    
    // 验证进度值
    final progressValidation = validateProgress(task.progress);
    if (progressValidation.isFailure) {
      return progressValidation;
    }
    
    // 验证状态和进度的一致性
    final consistencyValidation = _validateStatusProgressConsistency(task);
    if (consistencyValidation.isFailure) {
      return consistencyValidation;
    }
    
    return Success(null);
  }
  
  /// 验证任务更新数据
  static Result<void, String> validateForUpdate(Task task) {
    // 更新时需要验证ID
    if (task.id == null || task.id! <= 0) {
      return Failure('Task ID is required for update');
    }
    
    // 其他验证与创建相同
    return validateForCreation(task);
  }
  
  /// 验证任务标题
  static Result<void, String> _validateTitle(String title) {
    final trimmedTitle = title.trim();
    
    if (trimmedTitle.isEmpty) {
      return Failure('任务标题不能为空');
    }
    
    if (trimmedTitle.length > 100) {
      return Failure('任务标题不能超过100个字符');
    }
    
    // 检查是否包含非法字符
    if (trimmedTitle.contains(RegExp(r'[<>"/\\]'))) {
      return Failure('任务标题包含非法字符');
    }
    
    return Success(null);
  }
  
  /// 验证任务描述
  static Result<void, String> _validateDescription(String? description) {
    if (description == null) {
      return Success(null);
    }
    
    if (description.length > 1000) {
      return Failure('任务描述不能超过1000个字符');
    }
    
    return Success(null);
  }
  
  /// 验证预估时间
  static Result<void, String> _validateEstimatedTime(int estimatedMinutes) {
    if (estimatedMinutes <= 0) {
      return Failure('预估时间必须大于0分钟');
    }
    
    if (estimatedMinutes > 24 * 60) { // 24小时
      return Failure('预估时间不能超过24小时');
    }
    
    return Success(null);
  }
  
  /// 验证实际用时
  static Result<void, String> _validateActualTime(int actualMinutes) {
    if (actualMinutes < 0) {
      return Failure('实际用时不能为负数');
    }
    
    if (actualMinutes > 48 * 60) { // 48小时
      return Failure('实际用时不能超过48小时');
    }
    
    return Success(null);
  }
  
  /// 验证进度值
  static Result<void, String> validateProgress(double progress) {
    if (progress < 0.0 || progress > 1.0) {
      return Failure('进度值必须在0.0到1.0之间');
    }
    
    return Success(null);
  }
  
  /// 验证状态和进度的一致性
  static Result<void, String> _validateStatusProgressConsistency(Task task) {
    switch (task.status) {
      case TaskStatus.pending:
        if (task.progress != 0.0) {
          return Failure('待办状态的任务进度必须为0%');
        }
        break;
        
      case TaskStatus.inProgress:
        if (task.progress <= 0.0 || task.progress >= 1.0) {
          return Failure('进行中状态的任务进度必须在0%到100%之间');
        }
        break;
        
      case TaskStatus.completed:
        if (task.progress != 1.0) {
          return Failure('已完成状态的任务进度必须为100%');
        }
        if (task.completedAt == null) {
          return Failure('已完成状态的任务必须有完成时间');
        }
        break;
        
      case TaskStatus.cancelled:
        // 取消状态可以有任意进度
        break;
    }
    
    return Success(null);
  }
  
  /// 验证截止日期
  static Result<void, String> validateDueDate(DateTime? dueDate) {
    if (dueDate == null) {
      return Success(null);
    }
    
    final now = DateTime.now();
    final oneYearFromNow = now.add(const Duration(days: 365));
    
    if (dueDate.isBefore(now.subtract(const Duration(days: 1)))) {
      return Failure('截止日期不能早于昨天');
    }
    
    if (dueDate.isAfter(oneYearFromNow)) {
      return Failure('截止日期不能超过一年');
    }
    
    return Success(null);
  }
  
  /// 验证标签
  static Result<void, String> validateTags(List<String> tags) {
    if (tags.length > 10) {
      return Failure('标签数量不能超过10个');
    }
    
    for (final tag in tags) {
      if (tag.trim().isEmpty) {
        return Failure('标签不能为空');
      }
      
      if (tag.length > 20) {
        return Failure('单个标签不能超过20个字符');
      }
      
      if (tag.contains(RegExp(r'[<>"/\\,]'))) {
        return Failure('标签包含非法字符');
      }
    }
    
    // 检查重复标签
    final uniqueTags = tags.toSet();
    if (uniqueTags.length != tags.length) {
      return Failure('标签不能重复');
    }
    
    return Success(null);
  }
  
  /// 验证任务优先级变更
  static Result<void, String> validatePriorityChange(
    TaskPriority currentPriority,
    TaskPriority newPriority,
    TaskStatus status,
  ) {
    // 已完成的任务不能修改优先级
    if (status == TaskStatus.completed) {
      return Failure('已完成的任务不能修改优先级');
    }
    
    // 已取消的任务不能修改优先级
    if (status == TaskStatus.cancelled) {
      return Failure('已取消的任务不能修改优先级');
    }
    
    return Success(null);
  }
  
  /// 批量验证任务
  static Result<void, String> validateBatch(List<Task> tasks) {
    if (tasks.isEmpty) {
      return Failure('任务列表不能为空');
    }
    
    if (tasks.length > 100) {
      return Failure('批量操作的任务数量不能超过100个');
    }
    
    for (int i = 0; i < tasks.length; i++) {
      final validation = TaskValidator.validateForCreation(tasks[i]);
      if (validation.isFailure) {
        return Failure('第${i + 1}个任务验证失败: ${validation.errorOrNull}');
      }
    }
    
    return Success(null);
  }
}