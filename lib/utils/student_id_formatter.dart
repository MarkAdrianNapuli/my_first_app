import 'package:flutter/services.dart';

class StudentIdFormatter extends TextInputFormatter {
  static String _format(String digits) {
    final b = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 4 || i == 5) b.write('-');
      b.write(digits[i]);
    }
    return b.toString();
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) digits = digits.substring(0, 10);

    var text = _format(digits);

    if (newValue.text.length < oldValue.text.length &&
        text == oldValue.text &&
        digits.isNotEmpty) {
      digits = digits.substring(0, digits.length - 1);
      text = _format(digits);
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

