import 'package:ass2/widgets/scratch_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('scratch gesture reveals card and controller resets it', (
    tester,
  ) async {
    final controller = ScratchCardController();
    var revealCount = 0;
    final progressValues = <double>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 200,
              child: ScratchCard(
                controller: controller,
                revealThreshold: 0.01,
                hintText: 'Scratch here',
                progressLabel: 'Revealed',
                onProgressChanged: progressValues.add,
                onRevealed: () => revealCount++,
                child: const ColoredBox(color: Colors.blue),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Revealed 0%'), findsOneWidget);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ScratchCard)),
    );
    await gesture.moveBy(const Offset(30, 0));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(revealCount, 1);
    expect(progressValues.last, greaterThan(0));

    controller.reset();
    await tester.pump();

    expect(progressValues.last, 0);
    expect(find.text('Revealed 0%'), findsOneWidget);
  });
}
