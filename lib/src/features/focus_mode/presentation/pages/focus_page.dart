import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:volume_controller/volume_controller.dart';
import '../../../../domain/entities/task.dart';
import '../../../../domain/entities/focus_record.dart';
import '../../../../infrastructure/repositories/task_repository_impl.dart';
import '../../../../infrastructure/repositories/focus_record_repository_impl.dart';
import '../../../../core/database/database_helper.dart';

/// 专注模式页面
class FocusPage extends ConsumerStatefulWidget {
  final int? taskId;
  
  const FocusPage({super.key, this.taskId});
  
  @override
  ConsumerState<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends ConsumerState<FocusPage> with TickerProviderStateMixin {
  Timer? _timer;
  int _totalMinutes = 25; // 默认25分钟
  int _remainingSeconds = 25 * 60; // 剩余秒数
  bool _isRunning = false;
  bool _isPaused = false;
  bool _showSettings = true; // 是否显示设置界面
  int _currentSession = 1; // 当前番茄钟次数
  int _totalFocusTime = 0; // 今日总专注时长（分钟）
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // 任务相关
  Task? _currentTask;
  late TaskRepositoryImpl _taskRepository;
  late FocusRecordRepositoryImpl _focusRecordRepository;
  bool _isLoadingTask = false;
  DateTime? _sessionStartTime;
  
  // 屏幕常亮和静音相关
  double? _originalVolume;
  bool _wasMuted = false;
  
  @override
  void initState() {
    super.initState();
    _remainingSeconds = _totalMinutes * 60;
    
    // 初始化脉冲动画
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // 模拟今日专注统计数据
    _totalFocusTime = 150; // 2.5小时
    
    // 初始化任务仓库
    _taskRepository = TaskRepositoryImpl(DatabaseHelper.instance);
    _focusRecordRepository = FocusRecordRepositoryImpl(DatabaseHelper.instance);
    
    // 加载任务信息
    if (widget.taskId != null) {
      _loadTaskInfo();
    }
    
    // 启用屏幕常亮和静音模式
    _enableFocusMode();
  }

  /// 显示专注完成对话框，包含任务进度更新功能
  void _showCompletionDialog() {
    if (_currentTask == null) {
      // 如果没有关联任务，显示简单的完成对话框
      _showSimpleCompletionDialog();
      return;
    }

    // 计算新的进度（默认增加10%）
    int newProgress = (_currentTask!.progress + 10).clamp(0, 100).toInt();
    final progressController = TextEditingController(text: newProgress.toString());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Text('🎉', style: TextStyle(fontSize: 24)),
              SizedBox(width: 8),
              Text('专注完成！', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '恭喜你完成此项任务！',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(height: 8),
              Text('专注时长：$_totalMinutes 分钟'),
              const SizedBox(height: 16),
              
              // 任务进度部分
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '任务：${_currentTask!.title}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('进度：'),
                        Expanded(
                          child: TextFormField(
                            controller: progressController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                               final progress = int.tryParse(value) ?? 0;
                               if (progress >= 0 && progress <= 100) {
                                 setState(() {
                                   newProgress = progress;
                                 });
                               }
                             },
                          ),
                        ),
                        const Text(' %'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: newProgress / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        newProgress == 100 ? Colors.green : Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              const Text(
                '💡 建议你：',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              const Text('• 💧 喝点水，补充水分'),
              const Text('• 🧘 休息一下，放松身心'),
              const Text('• 🤸 舒展身体，活动筋骨'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await _updateTaskProgress(newProgress);
                Navigator.pop(context);
                context.go('/'); // 返回首页
              },
              child: const Text('返回首页'),
            ),
            TextButton(
              onPressed: () async {
                await _updateTaskProgress(newProgress);
                Navigator.pop(context);
                _resetTimer();
              },
              child: const Text('再来一轮'),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示简单的完成对话框（无关联任务时）
  void _showSimpleCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Text('🎉', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text('专注完成！', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '恭喜你完成专注！',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 8),
            Text('专注时长：$_totalMinutes 分钟'),
            const SizedBox(height: 16),
            const Text(
              '💡 建议你：',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text('• 💧 喝点水，补充水分'),
            const Text('• 🧘 休息一下，放松身心'),
            const Text('• 🤸 舒展身体，活动筋骨'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/'); // 返回首页
            },
            child: const Text('返回首页'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetTimer();
            },
            child: const Text('再来一轮'),
          ),
        ],
      ),
    );
  }

  /// 更新任务进度
  Future<void> _updateTaskProgress(int newProgress) async {
    if (_currentTask == null) return;

    try {
      final now = DateTime.now();
      final updatedTask = _currentTask!.copyWith(
        progress: newProgress / 100.0, // 将百分比转换为0-1之间的小数
        status: newProgress == 100 ? TaskStatus.completed : _currentTask!.status,
        completedAt: newProgress == 100 ? now : _currentTask!.completedAt,
        updatedAt: now,
      );
      
      await _taskRepository.updateTask(updatedTask);
      
      // 更新本地任务状态
      setState(() {
        _currentTask = updatedTask;
      });
      
      debugPrint('任务进度已更新：${updatedTask.progress}%');
    } catch (e) {
      debugPrint('更新任务进度失败: $e');
    }
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    
    // 恢复原始状态
    _disableFocusMode();
    
    super.dispose();
  }
  
  /// 启用专注模式（屏幕常亮 + 静音）
  Future<void> _enableFocusMode() async {
    try {
      // 启用屏幕常亮
      await WakelockPlus.enable();
      
      // 保存当前音量并设置静音
       _originalVolume = await VolumeController().getVolume();
       VolumeController().setVolume(0.0);
      _wasMuted = true;
      
      debugPrint('专注模式已启用：屏幕常亮 + 静音');
    } catch (e) {
      debugPrint('启用专注模式失败: $e');
    }
  }
  
  /// 禁用专注模式（恢复原始状态）
  Future<void> _disableFocusMode() async {
    try {
      // 禁用屏幕常亮
      await WakelockPlus.disable();
      
      // 恢复原始音量
       if (_originalVolume != null && _wasMuted) {
         VolumeController().setVolume(_originalVolume!);
         _wasMuted = false;
       }
      
      debugPrint('专注模式已禁用：恢复原始状态');
    } catch (e) {
      debugPrint('禁用专注模式失败: $e');
    }
  }
  
  /// 加载任务信息
  Future<void> _loadTaskInfo() async {
    if (widget.taskId == null) return;
    
    setState(() {
      _isLoadingTask = true;
    });
    
    try {
      final task = await _taskRepository.getTaskById(widget.taskId!);
      setState(() {
        _currentTask = task;
        _isLoadingTask = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingTask = false;
      });
      // 可以在这里添加错误处理
    }
  }
  
  void _startTimer() {
    if (_showSettings) {
      setState(() {
        _showSettings = false;
        _isRunning = true;
        _sessionStartTime = DateTime.now(); // 记录开始时间
      });
    } else {
      setState(() {
        _isRunning = true;
        _isPaused = false;
      });
    }
    
    _pulseController.repeat(reverse: true);
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _completeSession();
        }
      });
    });
  }
  
  void _pauseTimer() {
    setState(() {
      _isRunning = false;
      _isPaused = true;
    });
    _timer?.cancel();
    _pulseController.stop();
  }
  
  void _stopTimer() {
    _timer?.cancel();
    _pulseController.stop();
    
    // 显示确认对话框
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认停止'),
        content: const Text('确定要停止当前专注吗？进度将会保存为中断记录。'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startTimer(); // 继续专注
            },
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // 保存中断记录
              await _saveFocusRecord(FocusSessionStatus.interrupted);
              // 恢复原始状态
              await _disableFocusMode();
              context.go('/'); // 返回首页
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
  
  void _completeSession() async {
    _timer?.cancel();
    _pulseController.stop();
    
    // 保存专注记录到数据库
    await _saveFocusRecord(FocusSessionStatus.completed);
    
    // 恢复原始状态
    await _disableFocusMode();
    
    setState(() {
      _currentSession++;
      _totalFocusTime += _totalMinutes;
      _isRunning = false;
      _isPaused = false;
    });
    
    // 显示完成对话框
    _showCompletionDialog();
  }
  
  /// 保存专注记录到数据库
  Future<void> _saveFocusRecord(FocusSessionStatus status) async {
    if (_sessionStartTime == null) return;
    
    final now = DateTime.now();
    final actualMinutes = status == FocusSessionStatus.completed 
        ? _totalMinutes 
        : (_totalMinutes * 60 - _remainingSeconds) ~/ 60;
    
    final focusRecord = FocusRecord(
      taskId: widget.taskId,
      taskTitle: _currentTask?.title,
      modeType: FocusModeType.pomodoro,
      plannedMinutes: _totalMinutes,
      actualMinutes: actualMinutes,
      status: status,
      startTime: _sessionStartTime!,
      endTime: now,
      createdAt: now,
    );
    
    try {
      // 保存专注记录
      await _focusRecordRepository.createRecord(focusRecord);
      
      // 如果有关联任务且专注完成，更新任务的实际用时
      if (widget.taskId != null && _currentTask != null && status == FocusSessionStatus.completed) {
        final updatedTask = _currentTask!.copyWith(
          actualMinutes: _currentTask!.actualMinutes + actualMinutes,
          updatedAt: now,
        );
        await _taskRepository.updateTask(updatedTask);
      }
    } catch (e) {
      // 可以在这里添加错误处理，比如显示错误提示
      debugPrint('保存专注记录失败: $e');
    }
  }
  
  void _resetTimer() {
    setState(() {
      _remainingSeconds = _totalMinutes * 60;
      _isRunning = false;
      _isPaused = false;
      _showSettings = true;
      _sessionStartTime = null; // 重置开始时间
    });
  }
  
  void _updateDuration(int minutes) {
    setState(() {
      _totalMinutes = minutes;
      _remainingSeconds = minutes * 60;
    });
  }
  
  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      body: SafeArea(
        child: _showSettings ? _buildSettingsView() : _buildFocusView(),
      ),
    );
  }
  
  Widget _buildSettingsView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // 顶部标题
          Row(
            children: [
              IconButton(
                onPressed: () => context.go('/'),
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
              ),
              const Expanded(
                child: Text(
                  '专注设置',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 48), // 平衡左侧按钮
            ],
          ),
          
          const SizedBox(height: 60),
          
          // 时长选择
          const Text(
            '选择专注时长',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 40),
          
          // 时长选项
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [15, 25, 30, 45, 60].map((minutes) {
              final isSelected = _totalMinutes == minutes;
              return GestureDetector(
                onTap: () => _updateDuration(minutes),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Center(
                    child: Text(
                      '${minutes}分',
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF2C3E50) : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 40),
          
          // 自定义时长输入
          const Text(
            '或自定义时长',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // 自定义输入框
          Container(
            width: 200,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '输入分钟数',
                      hintStyle: TextStyle(
                        color: Colors.white54,
                        fontSize: 16,
                      ),
                    ),
                    onChanged: (value) {
                      final minutes = int.tryParse(value);
                      if (minutes != null && minutes > 0 && minutes <= 180) {
                        _updateDuration(minutes);
                      }
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Text(
                    '分钟',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 10),
          
          // 提示文字
          Text(
            '范围：1-180分钟',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
          
          const Spacer(),
          
          // 开始按钮
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _startTimer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2C3E50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: const Text(
                '开始专注',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFocusView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // 顶部任务标题
          _isLoadingTask
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  _currentTask != null 
                      ? '正在专注: ${_currentTask!.title}'
                      : '正在专注: 番茄钟专注时间',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
          
          const SizedBox(height: 40),
          
          // 主计时器
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isRunning ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _formatTime(_remainingSeconds),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 40),
          
          // 工作时间提示
          Text(
            '工作时间 • 还剩 ${(_remainingSeconds / 60).floor()} 分 ${_remainingSeconds % 60} 秒',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 16,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // 任务详情
          if (_currentTask != null && _currentTask!.description != null && _currentTask!.description!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '任务详情',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentTask!.description!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 20),
          
          // 专注提示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                const Text(
                  '专注期间通知已静音',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '🌟 专注是成功的关键',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Text(
                  '保持专注，你可以的！ 💪',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const Text(
                  '每一分钟的专注都在让你变得更强 ✨',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          
          // 控制按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 暂停/继续按钮
              GestureDetector(
                onTap: _isRunning ? _pauseTimer : _startTimer,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _isRunning ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              
              // 停止按钮
              GestureDetector(
                onTap: _stopTimer,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.stop,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // 按钮标签
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                _isRunning ? '暂停' : (_isPaused ? '继续' : '暂停'),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              Text(
                '停止',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}