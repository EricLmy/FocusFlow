import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 设置页面
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});
  
  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  Widget _buildAboutSection() {
    return Center(
      child: Column(
        children: [
          SvgPicture.asset(
            'assets/logo.svg',
            width: 100,
            height: 100,
          ),
          const SizedBox(height: 16),
          const Text(
            'FocusFlow',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Version 1.0.0'),
        ],
      ),
    );
  }

  Widget _buildSettingsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '通用设置',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SwitchListTile(
          title: const Text('深色模式'),
          value: false, // 这里需要替换为实际的主题状态
          onChanged: (value) {
            // 这里需要实现切换主题的逻辑
          },
        ),
        ListTile(
          title: const Text('通知设置'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            // 导航到通知设置页面
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildAboutSection(),
          const SizedBox(height: 24),
          _buildSettingsList(),
        ],
      ),
    );
  }
}