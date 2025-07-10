import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 主导航组件
class MainNavigation extends StatefulWidget {
  final Widget child;
  
  const MainNavigation({super.key, required this.child});
  
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  
  // 导航项配置
  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.today,
      label: '今日',
      route: '/',
    ),
    NavigationItem(
      icon: Icons.bar_chart,
      label: '统计',
      route: '/statistics',
    ),
    NavigationItem(
      icon: Icons.list,
      label: '列表',
      route: '/tasks',
    ),
  ];
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSelectedIndex();
  }
  
  void _updateSelectedIndex() {
    final location = GoRouterState.of(context).uri.path;
    for (int i = 0; i < _navigationItems.length; i++) {
      if (location == _navigationItems[i].route || 
          (location.startsWith(_navigationItems[i].route) && _navigationItems[i].route != '/')) {
        if (_selectedIndex != i) {
          setState(() {
            _selectedIndex = i;
          });
        }
        break;
      }
    }
  }
  
  void _onTabTapped(int index) {
    if (index != _selectedIndex) {
      context.go(_navigationItems[index].route);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
  
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onTabTapped,
      items: _navigationItems.map((item) => BottomNavigationBarItem(
        icon: Icon(item.icon),
        label: item.label,
      )).toList(),
    );
  }
}

/// 导航项数据类
class NavigationItem {
  final IconData icon;
  final String label;
  final String route;
  
  const NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}