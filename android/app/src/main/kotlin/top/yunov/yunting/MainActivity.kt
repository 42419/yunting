package top.yunov.yunting

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * 除了标准的 FlutterActivity，这里额外开了一个 MethodChannel，
 * 目的是把 applicationInfo.nativeLibraryDir 这个路径传给 Dart 侧。
 *
 * 为什么需要这个：内嵌的 go-music-api 后端二进制被伪装成了
 * jniLibs/arm64-v8a/libgma.so 打进 APK。Android 在安装时会把 jniLibs
 * 下的文件解压到这个 nativeLibraryDir 目录，并且只有这个目录被系统豁免了
 * Android 10+ 对私有数据目录文件的 W^X(不可写又可执行) 限制，所以后端
 * 二进制必须从这里读路径再用 Process 拉起来，放在其他任何自己拷贝的目录
 * 都可能被 SELinux 挡掉，跑不起来。
 */
class MainActivity : FlutterActivity() {
    private val channelName = "top.yunov.yunting/native_lib"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getNativeLibraryDir" -> result.success(applicationInfo.nativeLibraryDir)
                    else -> result.notImplemented()
                }
            }
    }
}
