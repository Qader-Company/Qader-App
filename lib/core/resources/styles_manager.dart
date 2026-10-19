import 'package:flutter/material.dart';
import 'font_manager.dart';

TextStyle _getTextStyle(double fontSize, FontWeight fontWeight, Color color) {
  return TextStyle(
    fontSize: fontSize,
    fontFamily: FontConstants.fontFamily,
    fontWeight: fontWeight,
    color: color,
  );
}

TextStyle getLightStyle({double fontSize = 12, required Color color}) =>
    _getTextStyle(fontSize, FontWeight.w300, color);

TextStyle getRegularStyle({double fontSize = 12, required Color color}) =>
    _getTextStyle(fontSize, FontWeight.w400, color);

TextStyle getMediumStyle({double fontSize = 12, required Color color}) =>
    _getTextStyle(fontSize, FontWeight.w500, color);

TextStyle getSemiBoldStyle({double fontSize = 12, required Color color}) =>
    _getTextStyle(fontSize, FontWeight.w600, color);

TextStyle getBoldStyle({double fontSize = 12, required Color color}) =>
    _getTextStyle(fontSize, FontWeight.w700, color);
