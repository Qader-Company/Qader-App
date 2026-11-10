part of '../application_status_view.dart';

// Date and number formatting (English / Arabic) for the sections.

extension _StatusFormat on _ApplicationStatusViewState {
  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';
  static const _monthsEn = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const _monthsAr = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];
  static const _daysEn = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const _daysAr = [
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  String _digits(String value) => _ar
      ? value.replaceAllMapped(
          RegExp('[0-9]'),
          (m) => '٠١٢٣٤٥٦٧٨٩'[int.parse(m[0]!)],
        )
      : value;

  String _month(DateTime date) => (_ar ? _monthsAr : _monthsEn)[date.month - 1];

  /// "Monday, Aug 4, 2026" / "الاثنين، ٤ أغسطس ٢٠٢٦".
  String _day(DateTime date) => _ar
      ? _digits(
          '${_daysAr[date.weekday - 1]}، ${date.day} ${_month(date)} ${date.year}',
        )
      : '${_daysEn[date.weekday - 1]}, ${_month(date).substring(0, 3)} '
            '${date.day}, ${date.year}';

  /// "10:00 AM" / "١٠:٠٠ ص".
  String _time(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = '${date.minute}'.padLeft(2, '0');
    final am = date.hour < 12;
    return _digits('$hour:$minute ${am ? t('AM', 'ص') : t('PM', 'م')}');
  }

  String _range(DateTime start, DateTime? end) =>
      end == null ? _time(start) : '${_time(start)} – ${_time(end)}';
}
