import '../../../../core/network/either.dart';
import '../../../../core/network/failure.dart';
import '../talent_application.dart';

/// The talent's application and the interview actions they can take.
abstract class ApplicationRepository {
  /// `GET /talent/application`.
  Future<Either<Failure, TalentApplication>> load();

  /// Confirm Interview Slot.
  Future<Either<Failure, void>> selectSlot(int slotId);

  /// Reject All Interview Slots with the talent's reason.
  Future<Either<Failure, void>> rejectSlots(String reason);

  /// Cancel Interview and Request New Slots (one chance).
  Future<Either<Failure, void>> cancelInterview();
}
