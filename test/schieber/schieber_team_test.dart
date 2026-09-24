import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jasstafel/schieber/widgets/schieber_background_z.dart';
import 'package:jasstafel/schieber/widgets/schieber_team.dart';

import '../main_test.dart' show stubWakelock, AppSize;

void main() {
  setUp(stubWakelock);

  /// The stack a team lays its name and strokes out on. Team 0 is turned
  /// around, so its own stack is the only place both teams measure alike.
  RenderBox stackOf(WidgetTester tester, int team) =>
      tester.renderObject<RenderBox>(
        find
            .descendant(
              of: find.byType(SchieberTeam).at(team),
              matching: find.byType(Stack),
            )
            .first,
      );

  /// Where [what] sits on that stack.
  Rect boxIn(WidgetTester tester, int team, Finder what) {
    final stack = stackOf(tester, team);
    final it = tester.renderObject<RenderBox>(
      find
          .descendant(of: find.byType(SchieberTeam).at(team), matching: what)
          .first,
    );
    return Rect.fromPoints(
      it.localToGlobal(Offset.zero, ancestor: stack),
      it.localToGlobal(it.size.bottomRight(Offset.zero), ancestor: stack),
    );
  }

  /// Where the row of strokes worth [points] sits within its team.
  Rect rowIn(WidgetTester tester, int team, int points) =>
      boxIn(tester, team, find.byKey(Key('add${points}_$team')));

  Future<void> check(WidgetTester tester, Size screen) async {
    tester.setScreenSize(screen);
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 48);
    await tester.pumpApp({});

    for (var team = 0; team < 2; team++) {
      final half = stackOf(tester, team).size.height;
      final first = rowIn(tester, team, 100);
      final last = rowIn(tester, team, 20);
      final name = boxIn(tester, team, find.text('Team ${team + 1}'));
      debugPrint(
        'MEASURE $screen team$team: half is $half, '
        'name ends at ${name.bottom}, rows ${first.top}..${last.bottom}',
      );
      expect(
        first.top,
        greaterThanOrEqualTo(name.bottom),
        reason: 'team $team writes its name over its first row',
      );
      expect(
        last.bottom,
        lessThanOrEqualTo(half),
        reason: 'team $team draws its last row past its half',
      );
      expect(
        half - last.bottom,
        lessThan(first.top),
        reason: 'team $team leaves more room below the strokes than above',
      );
    }
  }

  testWidgets('phone 411x914', (tester) async {
    await check(tester, const Size(411, 914));
  });

  testWidgets('tablet 1280x800', (tester) async {
    await check(tester, const Size(1280, 800));
  });

  testWidgets('small phone 411x640', (tester) async {
    await check(tester, const Size(411, 640));
  });

  testWidgets('the z lines up with the strokes it counts', (tester) async {
    tester.setScreenSize(const Size(411, 914));
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 48);
    await tester.pumpApp({'flutter.schieber_draw_Z': true});

    for (var team = 0; team < 2; team++) {
      final of = find.byType(SchieberTeam).at(team);
      // the stack the z is painted on, the rows are placed on the same one
      final stack = tester.renderObject<RenderBox>(
        find.descendant(of: of, matching: find.byType(Stack)).first,
      );
      final z =
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: of,
                      matching: find.byWidgetPredicate(
                        (w) =>
                            w is CustomPaint && w.painter is BackgroundZPainter,
                      ),
                    ),
                  )
                  .painter!
              as BackgroundZPainter;

      double middleOf(int points) {
        final row = tester.renderObject<RenderBox>(
          find.byKey(Key('add${points}_$team')),
        );
        final top = row.localToGlobal(Offset.zero, ancestor: stack).dy;
        return top + row.size.height / 2;
      }

      expect(z.margin.top, closeTo(middleOf(100), 0.01));
      expect(z.team.height - z.margin.bottom, closeTo(middleOf(20), 0.01));
    }
  });
}
