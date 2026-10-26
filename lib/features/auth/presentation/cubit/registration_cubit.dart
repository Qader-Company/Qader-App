import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/failure.dart';
import '../../domain/entities/registration_request.dart';
import '../../domain/entities/email_verification_challenge.dart';
import '../../domain/repositories/auth_repository.dart';

enum RegistrationStatus { initial, loading, success, failure }

class RegistrationState {
  const RegistrationState(this.status, {this.failure, this.challenge});
  final RegistrationStatus status;
  final Failure? failure;
  final EmailVerificationChallenge? challenge;
}

class RegistrationCubit extends Cubit<RegistrationState> {
  RegistrationCubit(this._repository)
    : super(const RegistrationState(RegistrationStatus.initial));
  final AuthRepository _repository;
  Future<void> submit(RegistrationRequest request) async {
    if (state.status == RegistrationStatus.loading ||
        state.status == RegistrationStatus.success) {
      return;
    }
    emit(const RegistrationState(RegistrationStatus.loading));
    try {
      final result = await _repository.register(request);
      if (isClosed) return;
      result.fold(
        (failure) => emit(
          RegistrationState(RegistrationStatus.failure, failure: failure),
        ),
        (challenge) => emit(
          RegistrationState(RegistrationStatus.success, challenge: challenge),
        ),
      );
    } on Object {
      if (!isClosed) {
        emit(
          const RegistrationState(
            RegistrationStatus.failure,
            failure: ServerFailure(message: 'auth_registration_error'),
          ),
        );
      }
    }
  }
}
