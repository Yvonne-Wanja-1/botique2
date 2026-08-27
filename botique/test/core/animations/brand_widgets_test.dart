import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:botique/core/animations/animated_counter.dart';
import 'package:botique/core/animations/press_scale.dart';
import 'package:botique/core/animations/stagger_reveal.dart';

void main() {
  testWidgets('StaggerReveal reveals its child', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: StaggerReveal(child: Text('revealed'))),
    ));
    expect(find.text('revealed'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('revealed'), findsOneWidget);
  });

  testWidgets('PressScale fires onTap and scales on press', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PressScale(
          onTap: () => tapped = true,
          child: const SizedBox(width: 100, height: 100),
        ),
      ),
    ));
    await tester.tap(find.byType(PressScale));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('AnimatedCounter renders formatted final value', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: AnimatedCounter(
          value: 48290,
          format: _ksh,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('KSh 48,290'), findsOneWidget);
  });
}

String _ksh(double value) {
  final s = value.toStringAsFixed(0);
  return 'KSh ${s.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}';
}
