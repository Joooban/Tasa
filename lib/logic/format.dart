import 'package:intl/intl.dart';

final _pesoFormat = NumberFormat.decimalPattern('en_PH');
final _shortDateFormat = DateFormat('MMM d', 'en_PH');
final _monthYearFormat = DateFormat('MMMM yyyy', 'en_PH');
final _monthShortFormat = DateFormat('MMM', 'en_PH');

String peso(num n) => '₱${_pesoFormat.format(n.round())}';

String fmtShortDate(DateTime d) => _shortDateFormat.format(d);

String fmtMonthYear(DateTime d) => _monthYearFormat.format(d).toUpperCase();

/// Three-letter month abbreviation ("Jan", "Dec") — unambiguous across a
/// year boundary, unlike a single initial (every "J" or "A" repeats).
String fmtMonthShort(DateTime d) => _monthShortFormat.format(d);
