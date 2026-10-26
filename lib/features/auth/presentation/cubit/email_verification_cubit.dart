import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/failure.dart';
import '../../domain/entities/email_verification_challenge.dart';
import '../../domain/repositories/auth_repository.dart';

enum EmailVerificationStatus { initial, loading, success, failure }

class EmailVerificationState {
  const EmailVerificationState(this.status, {this.failure});
  final EmailVerificationStatus status;
  final Failure? failure;
}

class EmailVerificationCubit extends Cubit<EmailVerificationState> {
  EmailVerificationCubit(this._repository, this.challenge)
    : super(const EmailVerificationState(EmailVerificationStatus.initial));
  final AuthRepository _repository;
  final EmailVerificationChallenge challenge;

  Future<void> submit(String otp) async {
    if (state.status == EmailVerificationStatus.loading ||
        state.status == EmailVerificationStatus.success) {
      return;
    }
    emit(const EmailVerificationState(EmailVerificationStatus.loading));
    try {
      final result = await _repository.verifyEmail(challenge, otp);
      if (isClosed) return;
      result.fold(
        (failure) => emit(
          EmailVerificationState(
            EmailVerificationStatus.failure,
            failure: failure,
          ),
        ),
        (_) =>
            emit(const EmailVerificationState(EmailVerificationStatus.success)),
      );
    } on Object {
      if (!isClosed) {
        emit(
          const EmailVerificationState(
            EmailVerificationStatus.failure,
            failure: ServerFailure(message: 'auth_verification_error'),
          ),
        );
      }
    }
  }
}
