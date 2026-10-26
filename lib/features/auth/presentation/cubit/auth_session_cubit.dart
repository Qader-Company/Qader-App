import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/failure.dart';
import '../../../../core/storage/app_preferences.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

enum AuthStatus { signedOut, loading, authenticated, failure }

class AuthSessionState {
  const AuthSessionState(this.status, {this.user, this.failure});
  final AuthStatus status;
  final AuthUser? user;
  final Failure? failure;
}

class AuthSessionCubit extends Cubit<AuthSessionState> {
  AuthSessionCubit(this._repository, this._preferences)
    : super(const AuthSessionState(AuthStatus.signedOut)) {
    _preferences.sessionRevision.addListener(_onSessionChanged);
  }
  final AuthRepository _repository;
  final AppPreferences _preferences;
  int _operation = 0;

  void _onSessionChanged() {
    if (!_preferences.isLoggedIn && !isClosed) {
      _operation++;
      emit(const AuthSessionState(AuthStatus.signedOut));
    }
  }

  Future<void> login(String email, String password) async {
    if (state.status == AuthStatus.loading) return;
    final operation = ++_operation;
    emit(const AuthSessionState(AuthStatus.loading));
    final result = await _repository.login(email, password);
    if (isClosed || operation != _operation) return;
    result.fold(
      (failure) => emit(AuthSessionState(AuthStatus.failure, failure: failure)),
      (user) => emit(AuthSessionState(AuthStatus.authenticated, user: user)),
    );
  }

  Future<void> restore() async {
    if (!_preferences.isLoggedIn || state.status == AuthStatus.loading) return;
    final operation = ++_operation;
    emit(const AuthSessionState(AuthStatus.loading));
    final result = await _repository.currentUser();
    if (isClosed || operation != _operation) return;
    result.fold(
      (failure) => emit(AuthSessionState(AuthStatus.failure, failure: failure)),
      (user) => emit(AuthSessionState(AuthStatus.authenticated, user: user)),
    );
  }

  Future<void> logout() async {
    if (state.status == AuthStatus.loading) return;
    emit(const AuthSessionState(AuthStatus.loading));
    try {
      await _repository.logout();
    } on Object {
      if (!isClosed) {
        emit(
          const AuthSessionState(
            AuthStatus.failure,
            failure: CacheFailure(message: 'auth_storage_error'),
          ),
        );
      }
    }
  }

  @override
  Future<void> close() {
    _preferences.sessionRevision.removeListener(_onSessionChanged);
    return super.close();
  }
}
