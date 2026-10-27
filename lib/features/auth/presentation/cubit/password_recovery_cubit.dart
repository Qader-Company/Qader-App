import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/either.dart';
import '../../../../core/network/failure.dart';
import '../../data/repositories/password_recovery_repository.dart';
import '../../domain/entities/password_recovery_request.dart';

enum PasswordRecoveryStep { email, code, password, done }

class PasswordRecoveryState {
  const PasswordRecoveryState({
    this.step = PasswordRecoveryStep.email,
    this.loading = false,
    this.resending = false,
    this.resent = false,
    this.failure,
  });
  final PasswordRecoveryStep step;
  final bool loading;
  final bool resending;
  final bool resent;
  final Failure? failure;
}

class PasswordRecoveryCubit extends Cubit<PasswordRecoveryState> {
  PasswordRecoveryCubit(this._repository)
    : super(const PasswordRecoveryState());
  final PasswordRecoveryRepository _repository;
  PasswordRecoveryRequest? _request;
  String get email => _request?.email ?? '';

  Future<void> send(String email) async {
    if (state.loading || state.step != PasswordRecoveryStep.email) return;
    emit(const PasswordRecoveryState(loading: true));
    try {
      final result = await _repository.begin(email);
      if (isClosed) return;
      result.fold((failure) => emit(PasswordRecoveryState(failure: failure)), (
        request,
      ) {
        _request = request;
        emit(const PasswordRecoveryState(step: PasswordRecoveryStep.code));
      });
    } on Object {
      if (!isClosed) {
        emit(
          const PasswordRecoveryState(
            failure: ServerFailure(message: 'auth_recovery_error'),
          ),
        );
      }
    }
  }

  Future<void> resend() async {
    if (state.step != PasswordRecoveryStep.code || _request == null) return;
    await _perform(
      () => _repository.resend(_request!),
      PasswordRecoveryStep.code,
      resend: true,
    );
  }

  Future<void> verify(String otp) async {
    if (state.step != PasswordRecoveryStep.code || _request == null) return;
    await _perform(
      () => _repository.verify(_request!, otp),
      PasswordRecoveryStep.password,
    );
  }

  Future<void> reset(String password, String confirmation) async {
    if (state.step != PasswordRecoveryStep.password || _request == null) return;
    await _perform(
      () => _repository.reset(_request!, password, confirmation),
      PasswordRecoveryStep.done,
    );
  }

  Future<void> _perform(
    Future<Either<Failure, void>> Function() action,
    PasswordRecoveryStep next, {
    bool resend = false,
  }) async {
    if (state.loading) return;
    final step = state.step;
    emit(PasswordRecoveryState(step: step, loading: true, resending: resend));
    try {
      final result = await action();
      if (isClosed) return;
      result.fold(
        (failure) => emit(PasswordRecoveryState(step: step, failure: failure)),
        (_) => emit(PasswordRecoveryState(step: next, resent: resend)),
      );
    } on Object {
      if (!isClosed) {
        emit(
          PasswordRecoveryState(
            step: step,
            failure: const ServerFailure(message: 'auth_recovery_error'),
          ),
        );
      }
    }
  }
}
