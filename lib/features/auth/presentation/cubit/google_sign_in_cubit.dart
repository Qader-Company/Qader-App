import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/failure.dart';
import '../../domain/entities/google_account.dart';
import '../../domain/repositories/google_sign_in_client.dart';

class GoogleSignInState {
  const GoogleSignInState({this.loading = false, this.account, this.failure});

  final bool loading;

  /// Set once the user picked an account.
  final GoogleAccount? account;
  final Failure? failure;
}

/// Runs Google's account picker for the auth screens' Google button.
// TODO(auth): send `account.idToken` to POST /auth/talent/social/google/login
// once the backend confirms the token type and the success response.
class GoogleSignInCubit extends Cubit<GoogleSignInState> {
  GoogleSignInCubit(this._client) : super(const GoogleSignInState());

  final GoogleSignInClient _client;

  Future<void> signIn() async {
    if (state.loading) return;
    emit(const GoogleSignInState(loading: true));
    final result = await _client.signIn();
    if (isClosed) return;
    emit(
      result.fold(
        (failure) => GoogleSignInState(failure: failure),
        (account) => GoogleSignInState(account: account),
      ),
    );
  }
}
