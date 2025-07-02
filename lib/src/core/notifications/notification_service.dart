import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

/// 通知服务类 - 管理本地通知功能
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// 初始化通知服务
  static Future<void> initialize() async {
    // 初始化时区数据
    tz.initializeTimeZones();

    // Android初始化设置
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS初始化设置
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // 综合初始化设置
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // 初始化插件
    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 请求权限（Android 13+）
    await _requestPermissions();
  }

  /// 请求通知权限
  static Future<void> _requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// 处理通知点击事件
  static void _onNotificationTapped(NotificationResponse response) {
    // 处理通知点击逻辑
    final payload = response.payload;
    if (payload != null) {
      // 根据payload导航到相应页面
      _handleNotificationNavigation(payload);
    }
  }

  /// 处理通知导航
  static void _handleNotificationNavigation(String payload) {
    // 解析payload并导航到相应页面
    // 例如：{"type": "task_reminder", "taskId": "123"}
    // 这里可以使用路由服务进行页面跳转
  }

  /// 显示即时通知
  static Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'instant_notifications',
      '即时通知',
      channelDescription: '用于显示即时通知消息',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// 安排定时通知
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'scheduled_notifications',
      '定时通知',
      channelDescription: '用于任务提醒等定时通知',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails,
      payload: payload,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// 安排周期性通知
  static Future<void> schedulePeriodicNotification({
    required int id,
    required String title,
    required String body,
    required RepeatInterval repeatInterval,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'periodic_notifications',
      '周期通知',
      channelDescription: '用于健康提醒等周期性通知',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.periodicallyShow(
      id,
      title,
      body,
      repeatInterval,
      notificationDetails,
      payload: payload,
    );
  }

  /// 取消指定通知
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// 取消所有通知
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// 获取待处理的通知列表
  static Future<List<PendingNotificationRequest>>
      getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// 专注模式开始通知
  static Future<void> showFocusStartNotification({
    required String taskTitle,
    required int duration,
  }) async {
    await showInstantNotification(
      id: 1001,
      title: '专注模式已开始',
      body: '正在专注于：$taskTitle（${duration}分钟）',
      payload: '{"type": "focus_start"}',
    );
  }

  /// 专注模式结束通知
  static Future<void> showFocusEndNotification({
    required String taskTitle,
    required int actualDuration,
  }) async {
    await showInstantNotification(
      id: 1002,
      title: '专注完成！',
      body: '任务「$taskTitle」专注了${actualDuration}分钟',
      payload: '{"type": "focus_end"}',
    );
  }

  /// 任务提醒通知
  static Future<void> scheduleTaskReminder({
    required int taskId,
    required String taskTitle,
    required DateTime reminderTime,
  }) async {
    await scheduleNotification(
      id: 2000 + taskId,
      title: '任务提醒',
      body: '别忘了完成任务：$taskTitle',
      scheduledTime: reminderTime,
      payload: '{"type": "task_reminder", "taskId": "$taskId"}',
    );
  }

  /// 健康提醒通知
  static Future<void> scheduleHealthReminder() async {
    await schedulePeriodicNotification(
      id: 3001,
      title: '健康提醒',
      body: '该休息一下了，记得喝水和活动身体哦！',
      repeatInterval: RepeatInterval.hourly,
      payload: '{"type": "health_reminder"}',
    );
  }

  /// 取消任务提醒
  static Future<void> cancelTaskReminder(int taskId) async {
    await cancelNotification(2000 + taskId);
  }
}