import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drink_app/main.dart';

void main() {
  testWidgets('App khởi động, hiển thị 3 tab và xử lý lỗi tải menu',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // MenuScreen gọi API ngay trong initState. Trong môi trường test, mọi HTTP
    // request bị chặn và trả về 400, nên app phải hiện trạng thái lỗi thay vì
    // crash. Pump vài frame để FutureBuilder hoàn tất.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.text('Thử lại').evaluate().isNotEmpty) break;
    }

    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.textContaining('Không tải được menu'), findsOneWidget);

    // Ba tab chính đều render.
    expect(find.text('Menu'), findsWidgets);
    expect(find.text('Giỏ'), findsWidgets);
    expect(find.text('Đơn'), findsWidgets);

    // Tab Giỏ: chuyển tab thật sự (IndexedStack giữ tab khác offstage).
    await tester.tap(find.text('Giỏ').last);
    await tester.pump();
    expect(
      tester.widget<IndexedStack>(find.byType(IndexedStack).first).index,
      1,
    );
    expect(find.text('Giỏ hàng trống'), findsOneWidget);

    // Tab Đơn: chưa có đơn nào trong phiên nên hiện hướng dẫn.
    await tester.tap(find.text('Đơn').last);
    await tester.pump();
    expect(
      tester.widget<IndexedStack>(find.byType(IndexedStack).first).index,
      2,
    );
    expect(find.textContaining('Chưa có đơn hàng nào'), findsOneWidget);

    // Gỡ widget để Timer 15s của MenuScreen được huỷ trong dispose(),
    // tránh lỗi "A Timer is still pending" khi kết thúc test.
    await tester.pumpWidget(const SizedBox());
  });
}
