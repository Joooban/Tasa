import 'package:intl/intl.dart';

final _pesoFormat = NumberFormat.decimalPattern('en_PH');
final _shortDateFormat = DateFormat('MMM d', 'en_PH');
final _monthYearFormat = DateFormat('MMMM yyyy', 'en_PH');

String peso(num n) => '₱${_pesoFormat.format(n.round())}';

String fmtShortDate(DateTime d) => _shortDateFormat.format(d);

String fmtMonthYear(DateTime d) => _monthYearFormat.format(d).toUpperCase();
