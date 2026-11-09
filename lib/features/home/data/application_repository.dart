import '../../../core/network/api_consumer.dart';
import '../../../core/network/either.dart';
import '../../../core/network/failure.dart';
import '../domain/talent_application.dart';

class ApplicationRepository {
  const ApplicationRepository(this._api);
  final ApiConsumer _api;
  static const applicationPath = '/talent/application';
  static const rejectSlotsPath = '/talent/application/interview/slots/reject';
  static const cancelInterviewPath = '/talent/application/interview/cancel';
  static String selectSlotPath(int slotId) =>
      '/talent/application/interview/slots/$slotId/select';

  /// Confirm Interview Slot (no body).
  Future<Either<Failure, void>> selectSlot(int slotId) =>
      _action(selectSlotPath(slotId));

  /// Reject All Interview Slots with the talent's reason.
  Future<Either<Failure, void>> rejectSlots(String reason) =>
      _action(rejectSlotsPath, data: {'reason': reason});

  /// Cancel Interview and Request New Slots (one chance).
  Future<Either<Failure, void>> cancelInterview() =>
      _action(cancelInterviewPath);

  Future<Either<Failure, void>> _action(String path, {Object? data}) async {
    final result = await _api.post<Object?>(
      path,
      data: data,
      fromJson: (raw) => raw,
    );
    if (result.isError) return Left(result.getErrorOrThrow());
    final raw = result.getOrThrow();
    if (raw is Map && raw['success'] == false) {
      return Left(
        ServerFailure(
          message: raw['message'] is String
              ? raw['message'] as String
              : 'application_action_failed',
        ),
      );
    }
    return const Right(null);
  }

  Future<Either<Failure, TalentApplication>> load() async {
    final result = await _api.get<Object?>(
      applicationPath,
      fromJson: (raw) => raw,
    );
    if (result.isError) return Left(result.getErrorOrThrow());
    final raw = result.getOrThrow();
    if (raw is! Map || raw['success'] != true || raw['data'] is! Map) {
      return const Left(ServerFailure(message: 'application_invalid_response'));
    }
    try {
      return Right(
        TalentApplication.fromJson(
          Map<String, dynamic>.from(raw['data'] as Map),
        ),
      );
    } on Object {
      return const Left(ServerFailure(message: 'application_invalid_response'));
    }
  }
}
