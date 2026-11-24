import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/storage/app_preferences.dart';

/// Saving that the intro was seen, from the last page's button.
enum OnboardingStatus { idle, finishing, done, failed }

class OnboardingCubit extends Cubit<OnboardingStatus> {
  OnboardingCubit(this._preferences) : super(OnboardingStatus.idle);
  final AppPreferences _preferences;

  /// Saves once; a second tap while saving does nothing. A failure lets the
  /// talent try again.
  Future<void> finish() async {
    if (state == OnboardingStatus.finishing || state == OnboardingStatus.done) {
      return;
    }
    emit(OnboardingStatus.finishing);
    try {
      await _preferences.setOnBoardingViewed();
      if (!isClosed) emit(OnboardingStatus.done);
    } on Object {
      if (!isClosed) emit(OnboardingStatus.failed);
    }
  }
}
