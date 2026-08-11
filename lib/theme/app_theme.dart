import 'package:flutter/material.dart';

/// 云听的视觉基调：深夜电台。
///
/// 不用默认 Material 种子色生成的那种到处都是同一种紫的配色，自己定一套:
/// 暗色基底 + 暖金色高亮(调频指针的颜色)，源筛选做成电台预设按钮的样子。
class AppColors {
  AppColors._();

  // 基底：偏暖的近黑，不是纯黑，长时间盯着不刺眼
  static const bg = Color(0xFF121016);
  static const surface = Color(0xFF1C1920);
  static const surfaceHigh = Color(0xFF262230);
  static const surfaceLine = Color(0xFF322D3A);

  // 高亮：调频指针的暖金色，全局唯一的强调色，别的地方尽量不用饱和色抢它风头
  static const amber = Color(0xFFE8A33D);
  static const amberDim = Color(0xFF9A7233);

  // 极少量点缀用的冷色，仅用于"正在播放"之类的活跃态提示，出现频率要低
  static const teal = Color(0xFF4FD6C0);

  static const textPrimary = Color(0xFFF3EFE7);
  static const textSecondary = Color(0xFFA79C8D);
  static const textFaint = Color(0xFF6E6558);

  static const error = Color(0xFFE8735F);
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    final colorScheme = const ColorScheme.dark().copyWith(
      brightness: Brightness.dark,
      surface: AppColors.bg,
      primary: AppColors.amber,
      onPrimary: AppColors.bg,
      secondary: AppColors.teal,
      onSecondary: AppColors.bg,
      error: AppColors.error,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceHigh,
      outline: AppColors.surfaceLine,
    );

    final textTheme = base.textTheme
        .apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        )
        .copyWith(
          // 播放页的曲名：大、紧凑字距，压得住整页
          headlineSmall: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            height: 1.25,
          ),
          // 列表里的曲名
          titleMedium: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
          // 歌手/来源这类次要信息，字距拉开一点，感觉更像"标签"而不是正文
          bodySmall: TextStyle(
            fontSize: 12.5,
            color: AppColors.textSecondary,
            letterSpacing: 0.1,
          ),
          // 频道预设 chip 上的小字，全大写间距更开，像调频面板上的刻度字
          labelSmall: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.bg,
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(color: AppColors.textFaint),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: AppColors.amber, width: 1.4),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.amber,
        inactiveTrackColor: AppColors.surfaceLine,
        thumbColor: AppColors.amber,
        overlayColor: AppColors.amber.withValues(alpha: 0.15),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.amber,
        linearTrackColor: AppColors.surfaceLine,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.surfaceLine,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
    );
  }
}
