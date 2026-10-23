import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jasstafel/coiffeur/data/coiffeur_score.dart';
import 'package:jasstafel/common/sync/merge.dart';
import 'package:jasstafel/schieber/data/schieber_score.dart';

/// The counters of the boards, as the session merges them.
const counters = {'strokes'};

/// A JSON copy, as it arrives from another device.
Map<String, dynamic> _json(Object score) =>
    jsonDecode(jsonEncode(score)) as Map<String, dynamic>;

void main() {
  test('takes the side that changed', () {
    expect(mergeJson({'a': 1}, {'a': 1}, {'a': 2}), {'a': 2});
    expect(mergeJson({'a': 1}, {'a': 2}, {'a': 1}), {'a': 2});
  });

  test('keeps changes to different keys', () {
    expect(
      mergeJson({'a': 1, 'b': 'x'}, {'a': 2, 'b': 'x'}, {'a': 1, 'b': 'y'}),
      {'a': 2, 'b': 'y'},
    );
  });

  test('keeps entries both sides appended', () {
    expect(mergeJson([1], [1, 2], [1, 3]), [1, 2, 3]);
    // The same round entered on both devices is two rounds.
    expect(mergeJson([1], [1, 2], [1, 2]), [1, 2, 2]);
  });

  test('takes theirs when an entry was removed', () {
    expect(mergeJson([1, 2], [1], [1, 2, 3]), [1, 2, 3]);
  });

  test('adds up counters', () {
    expect(
      mergeJson({'strokes': 10}, {'strokes': 12}, {
        'strokes': 15,
      }, counters: counters),
      {'strokes': 17},
    );
    expect(
      mergeJson({'strokes': 10}, {'strokes': 12}, {
        'strokes': 12,
      }, counters: counters),
      {'strokes': 14},
    );
    // Counters in a list, and anywhere under the key.
    expect(
      mergeJson(
        {
          'team': [
            {
              'strokes': [1, 0],
            },
          ],
        },
        {
          'team': [
            {
              'strokes': [3, 0],
            },
          ],
        },
        {
          'team': [
            {
              'strokes': [2, 1],
            },
          ],
        },
        counters: counters,
      ),
      {
        'team': [
          {
            'strokes': [4, 1],
          },
        ],
      },
    );
  });

  test('takes theirs for numbers that are not counters', () {
    expect(mergeJson({'goal': 2500}, {'goal': 3000}, {'goal': 3000}), {
      'goal': 3000,
    });
    expect(
      mergeJson(
        {'goal': 2500},
        {'goal': 3000},
        {'goal': 2000},
        counters: {'strokes'},
      ),
      {'goal': 2000},
    );
  });

  test('takes theirs for other values both changed', () {
    expect(mergeJson('a', 'b', 'c'), 'c');
    expect(mergeJson(null, 5, 7), 7);
  });

  test('schieber keeps points entered on two devices at once', () {
    final base = SchieberScore()..add(100, 57);
    final ours = SchieberScore.fromJson(_json(base))..add(30, 127);
    final theirs = SchieberScore.fromJson(_json(base))..add(80, 77);

    final merged = SchieberScore.fromJson(
      mergeJson(_json(base), _json(ours), _json(theirs), counters: counters)
          as Map<String, dynamic>,
    );

    expect(merged.rounds.length, 3);
    expect(merged.team[0].sum(), 210);
    expect(merged.team[1].sum(), 261);
  });

  test('schieber takes one goal when both changed it', () {
    final base = SchieberScore();
    final ours = SchieberScore.fromJson(_json(base))..team[0].goalPoints = 1000;
    final theirs = SchieberScore.fromJson(_json(base))
      ..team[0].goalPoints = 2000;

    final merged = SchieberScore.fromJson(
      mergeJson(_json(base), _json(ours), _json(theirs), counters: counters)
          as Map<String, dynamic>,
    );

    expect(merged.team[0].goalPoints, 2000);
  });

  test('coiffeur keeps cells written on two devices at once', () {
    final base = CoiffeurScore();
    final ours = CoiffeurScore.fromJson(_json(base));
    ours.rows[0].pts[0].pts = 120;
    final theirs = CoiffeurScore.fromJson(_json(base));
    theirs.rows[2].pts[1].pts = 80;

    final merged = CoiffeurScore.fromJson(
      mergeJson(_json(base), _json(ours), _json(theirs))
          as Map<String, dynamic>,
    );

    expect(merged.rows[0].pts[0].pts, 120);
    expect(merged.rows[2].pts[1].pts, 80);
  });
}
