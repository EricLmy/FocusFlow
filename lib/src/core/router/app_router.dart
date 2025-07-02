import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/task_management/presentation/pages/task_list_page.dart';
import '../../features/focus_mode/presentation/pages/focus_page.dart';
import '../../features/statistics/presentation/pages/statistics_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../../main_navigation.dart';

/// 路由路径常量
class AppRoutes {
  static const String home = '/';
  static const String tasks = '/tasks';
  static const String focus = '/focus';
  static const String statistics = '/statistics';
  static const String settings = '/settings';
  static const String taskDetail = '/tasks/:id';
  static const String taskEdit = '/tasks/:id/edit';
  static const String taskCreate = '/tasks/create';
}

/// 路由配置
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter createRouter() {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: AppRoutes.home,
      routes: [
        // Shell路由 - 包含底部导航栏的主要页面
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) {
            return MainNavigation(child: child);
          },
          routes: [
            // 首页/任务列表
            GoRoute(
              path: AppRoutes.home,
              name: 'home',
              builder: (context, state) => const TaskListPage(),
            ),
            
            // 任务管理页面
            GoRoute(
              path: AppRoutes.tasks,
              name: 'tasks',
              builder: (context, state) => const TaskListPage(),
              routes: [
                // 创建任务
                GoRoute(
                  path: 'create',
                  name: 'task-create',
                  builder: (context, state) => const TaskEditPage(),
                ),
                // 任务详情
                GoRoute(
                  path: ':id',
                  name: 'task-detail',
                  builder: (context, state) {
                    final taskId = int.parse(state.pathParameters['id']!);
                    return TaskDetailPage(taskId: taskId);
                  },
                  routes: [
                    // 编辑任务
                    GoRoute(
                      path: 'edit',
                      name: 'task-edit',
                      builder: (context, state) {
                        final taskId = int.parse(state.pathParameters['id']!);
                        return TaskEditPage(taskId: taskId);
                      },
                    ),
                  ],
                ),
              ],
            ),
            
            // 专注模式页面
            GoRoute(
              path: AppRoutes.focus,
              name: 'focus',
              builder: (context, state) {
                final taskId = state.uri.queryParameters['taskId'];
                return FocusPage(
                  taskId: taskId != null ? int.parse(taskId) : null,
                );
              },
            ),
            
            // 统计页面
            GoRoute(
              path: AppRoutes.statistics,
              name: 'statistics',
              builder: (context, state) => const StatisticsPage(),
            ),
            
            // 设置页面
            GoRoute(
              path: AppRoutes.settings,
              name: 'settings',
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
      ],
      
      // 错误页面
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(
          title: const Text('页面未找到'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                '页面未找到',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '请检查URL是否正确',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('返回首页'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 路由扩展方法
extension AppRouterExtension on GoRouter {
  /// 导航到任务详情页
  void goToTaskDetail(int taskId) {
    go('/tasks/$taskId');
  }
  
  /// 导航到任务编辑页
  void goToTaskEdit(int taskId) {
    go('/tasks/$taskId/edit');
  }
  
  /// 导航到任务创建页
  void goToTaskCreate() {
    go('/tasks/create');
  }
  
  /// 导航到专注模式页（可选任务ID）
  void goToFocus({int? taskId}) {
    if (taskId != null) {
      go('/focus?taskId=$taskId');
    } else {
      go('/focus');
    }
  }
}

/// 路由Provider
final appRouterProvider = Provider<GoRouter>((ref) {
  return AppRouter.createRouter();
});

/// 导航辅助类
class NavigationHelper {
  static void goToTaskDetail(BuildContext context, int taskId) {
    context.go('/tasks/$taskId');
  }
  
  static void goToTaskEdit(BuildContext context, int taskId) {
    context.go('/tasks/$taskId/edit');
  }
  
  static void goToTaskCreate(BuildContext context) {
    context.go('/tasks/create');
  }
  
  static void goToFocus(BuildContext context, {int? taskId}) {
    if (taskId != null) {
      context.go('/focus?taskId=$taskId');
    } else {
      context.go('/focus');
    }
  }
  
  static void goToStatistics(BuildContext context) {
    context.go('/statistics');
  }
  
  static void goToSettings(BuildContext context) {
    context.go('/settings');
  }
  
  static void goHome(BuildContext context) {
    context.go('/');
  }
}

// 临时页面类 - 这些将在后续创建实际页面时替换
class TaskDetailPage extends StatelessWidget {
  final int taskId;
  
  const TaskDetailPage({super.key, required this.taskId});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('任务详情 #$taskId')),
      body: Center(
        child: Text('任务详情页面 - ID: $taskId'),
      ),
    );
  }
}

class TaskEditPage extends StatelessWidget {
  final int? taskId;
  
  const TaskEditPage({super.key, this.taskId});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(taskId == null ? '创建任务' : '编辑任务'),
      ),
      body: Center(
        child: Text(taskId == null ? '创建任务页面' : '编辑任务页面 - ID: $taskId'),
      ),
    );
  }
}