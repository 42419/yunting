plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "top.yunov.yunting"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "top.yunov.yunting"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // 内嵌的 go-music-api 后端目前只交叉编译了 arm64-v8a 一份(伪装成 libgma.so 放进
        // jniLibs，这样才能绕过 Android 10+ 对私有目录可执行文件的 W^X 限制)。
        // 限定只打包这个架构，顺便减小 APK 体积；以后要支持其他架构需要用 Android NDK
        // 重新交叉编译一份对应的 libgma.so 放到 jniLibs/<abi>/ 下，再把这行删掉或加回对应 abi。
        ndk {
            abiFilters += "arm64-v8a"
        }
    }

    packaging {
        jniLibs {
            // 保证 libgma.so 不被压缩进 APK，运行时可以直接以文件形式执行
            useLegacyPackaging = true
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
