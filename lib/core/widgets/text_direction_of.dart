import 'package:flutter/widgets.dart';

final _rtl = RegExp(r'[֐-ࣿיִ-﷿ﹰ-﻿]');
final _ltr = RegExp(r'[A-Za-zÀ-ɏ]');

/// The direction of text someone wrote (a report, a note), taken from its
/// first strong letter: English text in the Arabic UI then keeps its
/// punctuation at the end. Falls back to [fallback] when there is no
/// letter.
TextDirection textDirectionOf(String text, TextDirection fallback) {
  for (final char in text.characters) {
    if (_rtl.hasMatch(char)) return TextDirection.rtl;
    if (_ltr.hasMatch(char)) return TextDirection.ltr;
  }
  return fallback;
}
