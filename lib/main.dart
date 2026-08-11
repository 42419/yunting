import 'package:flutter/material.dart';

import 'pages/home_page.dart';
import 'services/backend_launcher.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '云听',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const StartupPage(),
    );
  }
}

/// App 启动后先拉起内嵌后端、等它就绪，再进首页。
class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> with WidgetsBindingObserver {
  String _status = '正在启动内嵌后端…';
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _boot();
  }

  Future<void> _boot() async {
    try {
      await BackendLauncher.instance.ensureStarted(
        onLog: (line) => debugPrint(line),
      );
      if (!mounted) return;
      setState(() => _status = '就绪');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App 被彻底杀掉/退出时把后端进程一起收掉，避免留下孤儿进程占用端口。
    if (state == AppLifecycleState.detached) {
      BackendLauncher.instance.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_error == null) ...[
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.amberDim, width: 1.4),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.radio_rounded, color: AppColors.amber, size: 28),
                ),
                const SizedBox(height: 20),
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.amber),
                ),
                const SizedBox(height: 16),
                Text(_status, style: const TextStyle(color: AppColors.textSecondary)),
              ] else ...[
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.amber, foregroundColor: AppColors.bg),
                  onPressed: () {
                    setState(() {
                      _error = null;
                      _status = '正在重试…';
                    });
                    _boot();
                  },
                  child: const Text('重试'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
