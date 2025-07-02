import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 主导航组件 - 包含底部导航栏
class MainNavigation extends StatelessWidget {
  final Widget child;
  
  const MainNavigation({super.key, required this.child});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }
  
  Widget _buildBottomNavigationBar(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.path;
    
    // 确定当前选中的索引
    int currentIndex = 0;
    switch (currentLocation) {
      case '/':
      case '/tasks':
        currentIndex = 0;
        break;
      case '/focus':
        currentIndex = 1;
        break;
      case '/statistics':
        currentIndex = 2;
        break;
      case '/settings':
        currentIndex = 3;
        break;
      default:
        // 对于子页面，根据父路径确定索引
        if (currentLocation.startsWith('/tasks')) {
          currentIndex = 0;
        } else if (currentLocation.startsWith('/focus')) {
          currentIndex = 1;
        } else if (currentLocation.startsWith('/statistics')) {
          currentIndex = 2;
        } else if (currentLocation.startsWith('/settings')) {
          currentIndex = 3;
        }
        break;
    }
    
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: (index) => _onTabTapped(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.task_alt),
          label: '任务',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.timer),
          label: '专注',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics),
          label: '统计',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: '设置',
        ),
      ],
    );
  }
  
  void _onTabTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/focus');
        break;
      case 2:
        context.go('/statistics');
        break;
      case 3:
        context.go('/settings');
        break;
    }
  }
}