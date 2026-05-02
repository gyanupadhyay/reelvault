import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:reelvault/main.dart';

void main() {
  testWidgets('ReelVaultApp builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const ReelVaultApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
