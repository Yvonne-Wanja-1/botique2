import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:botique/admin/admin_shell.dart';
import 'package:botique/data/mock/mock_report_repository.dart';
import 'package:botique/data/repositories/report_repository.dart';
import 'package:botique/models/user.dart';
import 'package:botique/services/auth_service.dart';

void main() {
  testWidgets('admin shell lays out the navigation rail and default section',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final auth = AuthService(storage: InMemoryTokenStorage());
    await auth.loginAs(DemoAccounts.accounts
        .firstWhere((account) => account.role == Role.superAdmin));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: auth),
          Provider<ReportRepository>.value(value: MockReportRepository()),
        ],
        child: const MaterialApp(home: AdminShell()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Products'), findsOneWidget);
    expect(find.text('Customers'), findsOneWidget);
  });
}