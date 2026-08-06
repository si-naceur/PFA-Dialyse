import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pfa_dialyse/features/auth/presentation/login_page.dart';

void main() {
  testWidgets('Login page renders the main title', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    expect(find.text('PFA Dialyse'), findsOneWidget);
  });
}
