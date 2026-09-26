import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medisync/core/design_system/components/section_header.dart';

void main() {
  group('SectionHeader Widget Tests', () {
    testWidgets('renders properly with bounded constraints', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SectionHeader(
                  title: 'Bounded Title',
                  trailing: Text('Action'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Bounded Title'), findsOneWidget);
      expect(find.text('Action'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'renders properly with unbounded horizontal constraints (inside a Row)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                SectionHeader(
                  title: 'Unbounded Title',
                  trailing: Text('Action'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Unbounded Title'), findsOneWidget);
      expect(find.text('Action'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders properly without trailing widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SectionHeader(
                  title: 'Simple Title',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Simple Title'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
