part of '../application_status_view.dart';

// Colors, enums and small types shared by the status sections.

// Palette taken from the "status" section of the Qader Figma file.
const _ink = AppColors.neutral900;
const _body = AppColors.neutral700;
const _muted = AppColors.neutral600;
const _line = AppColors.neutral200;
const _grey = AppColors.neutral300;
const _red = AppColors.red600;
const _redSoft = AppColors.red100;
const _green = AppColors.green700;
const _greenSoft = AppColors.green100;
const _yellow = AppColors.yellow700;
const _yellowSoft = AppColors.yellow50;
const _blueSoft = AppColors.blueSoft;
const _blueBorder = AppColors.blueBorder;
const _disabledFill = AppColors.blueDisabled;

enum _Tone { success, warning, danger, info }

enum _Step { done, current, pending, failedDone, failedCurrent }

/// A single round shown in "Interview History".
class _HistoryEntry {
  const _HistoryEntry({
    required this.round,
    required this.completed,
    required this.date,
    required this.online,
    this.location,
  });
  final int round;
  final bool completed;
  final String date;
  final bool online;
  final String? location;
}
