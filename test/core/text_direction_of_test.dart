import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qader/core/widgets/text_direction_of.dart';

void main() {
  test('direction follows the first strong letter', () {
    const rtl = TextDirection.rtl;
    const ltr = TextDirection.ltr;
    expect(textDirectionOf('Strong communication.', rtl), ltr);
    expect(textDirectionOf('تقرير جيد.', ltr), rtl);
    // Leading digits and punctuation do not decide it.
    expect(textDirectionOf('90% — ممتاز', ltr), rtl);
    expect(textDirectionOf('(1) Good', rtl), ltr);
    expect(textDirectionOf('123 ...', rtl), rtl);
    expect(textDirectionOf('', ltr), ltr);
  });
}
