import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 统一的封面图组件：有图显示图，没图/加载失败显示一个带音符的占位方块，
/// 全 App 保持同一种风格，不会一处是灰圆圈一处是彩色图标乱七八糟。
class SongCover extends StatelessWidget {
  const SongCover({
    super.key,
    required this.url,
    required this.size,
    this.radius = 10,
  });

  final String url;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: url.isEmpty
            ? _placeholder()
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholder(),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return _placeholder();
                },
              ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.surfaceHigh,
      alignment: Alignment.center,
      child: Icon(
        Icons.graphic_eq_rounded,
        color: AppColors.textFaint,
        size: size * 0.42,
      ),
    );
  }
}
