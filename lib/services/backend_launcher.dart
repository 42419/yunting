import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// 负责拉起/看护内嵌的 go-music-api 后端进程。
///
/// 后端二进制在构建时被伪装成了 android/app/src/main/jniLibs/arm64-v8a/libgma.so
/// 打进了 APK(这是绕开 Android 10+ 对私有目录可执行文件 W^X 限制的常见做法，
/// nativeLibraryDir 是系统专门豁免出来允许执行的目录)。启动时通过原生侧的
/// MethodChannel 拿到这个目录，再用 dart:io 的 Process.start 直接执行它，
/// 全程走 127.0.0.1 回环地址，不需要用户自己找服务器部署。
class BackendLauncher {
  BackendLauncher._();
  static final BackendLauncher instance = BackendLauncher._();

  static const _channel = MethodChannel('top.yunov.yunting/native_lib');
  static const _binaryName = 'libgma.so';
  static const port = 8080;
  static const baseUrl = 'http://127.0.0.1:$port';

  Process? _process;
  Completer<void>? _ready;

  bool get isRunning => _process != null;

  /// 启动后端进程并等待它开始正常响应请求。
  /// 如果已经在运行/启动中，直接复用同一个 Future，避免重复拉起。
  Future<void> ensureStarted({
    void Function(String line)? onLog,
  }) {
    if (_ready != null) return _ready!.future;

    final completer = Completer<void>();
    _ready = completer;
    _start(onLog: onLog).then((_) {
      if (!completer.isCompleted) completer.complete();
    }).catchError((Object e, StackTrace s) {
      _ready = null;
      if (!completer.isCompleted) completer.completeError(e, s);
    });
    return completer.future;
  }

  Future<void> _start({void Function(String line)? onLog}) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('内嵌后端目前只打包了 android/arm64 的可执行文件，暂不支持当前平台');
    }

    final String nativeLibDir =
        await _channel.invokeMethod<String>('getNativeLibraryDir') ?? '';
    if (nativeLibDir.isEmpty) {
      throw StateError('拿不到 nativeLibraryDir，无法定位内嵌后端可执行文件');
    }

    final binaryPath = '$nativeLibDir/$_binaryName';
    if (!await File(binaryPath).exists()) {
      throw StateError(
        '找不到内嵌后端二进制: $binaryPath\n'
        '(当前设备可能不是 arm64-v8a 架构，暂时只交叉编译了这一个架构)',
      );
    }

    // 给后端一个稳定的、App 私有的可写目录当工作目录，cookies.json 等运行期
    // 产生的文件就落在这里，不会写去只读的 nativeLibraryDir，也不会因为
    // App 更新/重装而随意丢失或残留。
    final supportDir = await getApplicationSupportDirectory();
    final workDir = Directory('${supportDir.path}/gma_server');
    if (!await workDir.exists()) {
      await workDir.create(recursive: true);
    }

    onLog?.call('启动内嵌后端: $binaryPath (workdir: ${workDir.path})');

    final process = await Process.start(
      binaryPath,
      const [],
      workingDirectory: workDir.path,
      runInShell: false,
    );
    _process = process;

    process.stdout
        .transform(const SystemEncoding().decoder)
        .listen((line) => onLog?.call('[后端] $line'));
    process.stderr
        .transform(const SystemEncoding().decoder)
        .listen((line) => onLog?.call('[后端][err] $line'));

    unawaited(process.exitCode.then((code) {
      onLog?.call('内嵌后端进程退出，code=$code');
      _process = null;
      _ready = null;
    }));

    await _waitUntilHealthy();
  }

  Future<void> _waitUntilHealthy({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      try {
        // 随便挑一个轻量、无副作用的接口探活即可。
        final resp = await http
            .get(Uri.parse('$baseUrl/api/v1/system/cookies'))
            .timeout(const Duration(milliseconds: 800));
        if (resp.statusCode > 0) return; // 只要服务端有响应就算活了
      } catch (_) {
        // 进程可能还没起来，忽略，继续轮询
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }
    throw TimeoutException('等待内嵌后端就绪超时');
  }

  /// App 退出/切后台清理时调用，避免留下孤儿进程占用端口。
  void stop() {
    _process?.kill();
    _process = null;
    _ready = null;
  }
}
