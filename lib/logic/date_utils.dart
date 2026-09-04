DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime todayDate([DateTime? now]) => dateOnly(now ?? DateTime.now());

DateTime offsetDate(DateTime base, int days) => dateOnly(base).add(Duration(days: days));

bool isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String monthKey(DateTime d) => '${d.year}-${d.month}';

int daysBetween(DateTime a, DateTime b) => dateOnly(b).difference(dateOnly(a)).inDays;

String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

const _weekdayInitials = {
  DateTime.monday: 'Mo',
  DateTime.tuesday: 'Tu',
  DateTime.wednesday: 'We',
  DateTime.thursday: 'Th',
  DateTime.friday: 'Fr',
  DateTime.saturday: 'Sa',
  DateTime.sunday: 'Su',
};

/// Two-letter weekday initial (Mo/Tu/We/Th/Fr/Sa/Su) — unambiguous unlike a
/// single narrow letter, where Tuesday/Thursday and Saturday/Sunday collide.
String weekdayInitial(DateTime d) => _weekdayInitials[d.weekday]!;
