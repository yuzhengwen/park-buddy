class DateFormatter {
  DateFormatter._(); // static use only

  static String formatDateTime(dynamic raw) {
    if (raw == null) return '-';
    final dt = DateTime.tryParse(raw.toString())?.toLocal();
    if (dt == null) return raw.toString();

    int hour12 = dt.hour % 12;
    if (hour12 == 0) hour12 = 12;
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';

    return '${_weekday(dt.weekday)} ${dt.day.toString().padLeft(2, '0')} '
        '${_month(dt.month)} ${dt.year} '
        '${hour12.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')} '
        '$amPm';
  }

  static String _weekday(int d) =>
      ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d - 1];

  static String _month(int m) => [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m - 1];
}