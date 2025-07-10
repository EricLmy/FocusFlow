import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'src/core/database/database_helper.dart';
import 'src/core/notifications/notification_service.dart';
import 'src/core/theme/app_theme.dart';
import 'src/core/router/app_router.dart';

// 全局通知插件实例
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 为不同平台设置数据库工厂
  if (kIsWeb) {
    // Web平台使用 FFI Web
    databaseFactory = databaseFactoryFfiWeb;
  } else if (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.macOS) {
    // 桌面平台使用 FFI
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // 初始化数据库
  try {
    await DatabaseHelper.instance.database;

  } catch (e) {

    // 在这里可以添加更多的错误处理逻辑，比如向用户显示一个错误消息
  }
  
  // 初始化通知服务
  try {
    await NotificationService.initialize();

  } catch (e) {

  }
  
  runApp(
    const ProviderScope(
      child: FocusFlowApp(),
    ),
  );
}

class FocusFlowApp extends ConsumerWidget {
  const FocusFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    
    return MaterialApp.router(
      title: 'FocusFlow 专注流',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
