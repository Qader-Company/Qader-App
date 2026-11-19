import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:qader/core/network/either.dart';
import 'package:qader/core/network/failure.dart';
import 'package:qader/features/auth/domain/entities/google_account.dart';
import 'package:qader/features/auth/domain/repositories/google_sign_in_client.dart';
import 'package:qader/features/auth/presentation/cubit/google_sign_in_cubit.dart';

class FakeGoogleSignInClient implements GoogleSignInClient {
  FakeGoogleSignInClient(this.result);
  Future<Either<Failure, GoogleAccount?>> result;
  int calls = 0;

  @override
  Future<Either<Failure, GoogleAccount?>> signIn() {
    calls++;
    return result;
  }
}

void main() {
  test('a picked account ends in state.account', () async {
    final client = FakeGoogleSignInClient(
      Future.value(
        const Right(GoogleAccount(idToken: 'id-token', name: 'Sara')),
      ),
    );
    final cubit = GoogleSignInCubit(client);
    final signIn = cubit.signIn();
    expect(cubit.state.loading, isTrue);
    await signIn;
    expect(cubit.state.loading, isFalse);
    expect(cubit.state.account?.idToken, 'id-token');
    expect(cubit.state.account?.name, 'Sara');
    expect(cubit.state.failure, isNull);
    await cubit.close();
  });

  test('closing the picker is neither an account nor a failure', () async {
    final cubit = GoogleSignInCubit(
      FakeGoogleSignInClient(Future.value(const Right(null))),
    );
    await cubit.signIn();
    expect(cubit.state.loading, isFalse);
    expect(cubit.state.account, isNull);
    expect(cubit.state.failure, isNull);
    await cubit.close();
  });

  test('a failure is exposed with its translation key', () async {
    final cubit = GoogleSignInCubit(
      FakeGoogleSignInClient(
        Future.value(
          const Left(ServerFailure(message: 'google_sign_in_failed')),
        ),
      ),
    );
    await cubit.signIn();
    expect(cubit.state.failure?.message, 'google_sign_in_failed');
    expect(cubit.state.account, isNull);
    await cubit.close();
  });

  test('taps while the picker is open are ignored', () async {
    final pending = Completer<Either<Failure, GoogleAccount?>>();
    final client = FakeGoogleSignInClient(pending.future);
    final cubit = GoogleSignInCubit(client);
    final first = cubit.signIn();
    await cubit.signIn();
    expect(client.calls, 1);
    pending.complete(const Right(null));
    await first;
    await cubit.close();
  });

  test('no emit after close while the picker is open', () async {
    final pending = Completer<Either<Failure, GoogleAccount?>>();
    final cubit = GoogleSignInCubit(FakeGoogleSignInClient(pending.future));
    final signIn = cubit.signIn();
    await cubit.close();
    pending.complete(const Right(GoogleAccount(idToken: 'late')));
    await expectLater(signIn, completes);
  });
}
