import 'package:flutter/widgets.dart';

/// Calls [onChanged] when the app language changes while this widget is
/// on screen.
///
/// The backend localizes its text (labels, names, FAQs) from the
/// `Accept-Language` header, so data fetched before a language switch stays
/// in the old language until it is loaded again.
class LocaleChangeListener extends StatefulWidget {
  const LocaleChangeListener({
    super.key,
    required this.onChanged,
    required this.child,
  });
  final VoidCallback onChanged;
  final Widget child;
  @override
  State<LocaleChangeListener> createState() => _LocaleChangeListenerState();
}

class _LocaleChangeListenerState extends State<LocaleChangeListener> {
  Locale? _locale;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    if (_locale != null && _locale != locale) widget.onChanged();
    _locale = locale;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
