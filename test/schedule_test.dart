import 'package:flutter_test/flutter_test.dart';
import 'package:mai_fitness/domain/schedule.dart';

void main() {
  // Mittwoch, 14.10.2026.
  final wed = DateTime(2026, 10, 14, 9);

  test('Pläne reihum', () {
    expect(
      Schedule.next(routineIds: ['a', 'b'], weekdays: {}, now: wed)!.routineId,
      'a',
    );
    expect(
      Schedule.next(
        routineIds: ['a', 'b'],
        weekdays: {},
        now: wed,
        lastRoutineId: 'a',
      )!.routineId,
      'b',
    );
    expect(
      Schedule.next(
        routineIds: ['a', 'b'],
        weekdays: {},
        now: wed,
        lastRoutineId: 'b',
      )!.routineId,
      'a',
    );
    // Gelöschter Plan → von vorn.
    expect(
      Schedule.next(
        routineIds: ['a', 'b'],
        weekdays: {},
        now: wed,
        lastRoutineId: 'x',
      )!.routineId,
      'a',
    );
    expect(Schedule.next(routineIds: [], weekdays: {}, now: wed), isNull);
  });

  test('nächster Trainingstag', () {
    expect(Schedule.nextDay({3}, wed), DateTime(2026, 10, 14));
    expect(
      Schedule.nextDay({3}, wed, skipToday: true),
      DateTime(2026, 10, 21),
    );
    expect(Schedule.nextDay({1, 5}, wed), DateTime(2026, 10, 16));
    expect(Schedule.nextDay({}, wed), isNull);
  });

  test('Wochentage tolerant lesen', () {
    expect(Schedule.parseWeekdays('1,3, 5,x,9'), {1, 3, 5});
    expect(Schedule.parseWeekdays(null), isEmpty);
    expect(Schedule.formatWeekdays({5, 1, 3}), '1,3,5');
  });
}
