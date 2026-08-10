// 基础 smoke test：只验证 App 能正常构建出启动页，不依赖内嵌后端真的跑起来
// (单测环境不是 Android，也拉不起 libgma.so，所以这里不测后端就绪之后的流程)。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yunting/main.dart';

void main() {
  testWidgets('App 能正常渲染启动页', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // 启动阶段应该先展示"正在启动内嵌后端…"和加载动画。
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.textContaining('启动内嵌后端'), findsOneWidget);
  });
}
