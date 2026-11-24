import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:qader/core/storage/app_preferences.dart';
import 'package:qader/features/onboarding/presentation/cubit/onboarding_cubit.dart';

class _Prefs extends Fake implements AppPreferences {
  Completer<void> save = Completer();
  int saves = 0;
  @override
  Future<void> setOnBoardingViewed() {
    saves++;
    return save.future;
  }
}

void main() {
  test('saves once, ignores taps while saving and after', () async {
    final prefs = _Prefs();
    final cubit = OnboardingCubit(prefs);
    addTearDown(cubit.close);
    final first = cubit.finish();
    expect(cubit.state, OnboardingStatus.finishing);
    await cubit.finish();
    prefs.save.complete();
    await first;
    expect(cubit.state, OnboardingStatus.done);
    await cubit.finish();
    expect(prefs.saves, 1);
  });

  test('a failed save can be retried', () async {
    final prefs = _Prefs();
    final cubit = OnboardingCubit(prefs);
    addTearDown(cubit.close);
    final first = cubit.finish();
    prefs.save.completeError(Exception('disk full'));
    await first;
    expect(cubit.state, OnboardingStatus.failed);

    prefs.save = Completer()..complete();
    await cubit.finish();
    expect(cubit.state, OnboardingStatus.done);
    expect(prefs.saves, 2);
  });

  test('closing while saving emits nothing more', () async {
    final prefs = _Prefs();
    final cubit = OnboardingCubit(prefs);
    final pending = cubit.finish();
    await cubit.close();
    prefs.save.complete();
    await pending;
    expect(cubit.state, OnboardingStatus.finishing);
  });
}
