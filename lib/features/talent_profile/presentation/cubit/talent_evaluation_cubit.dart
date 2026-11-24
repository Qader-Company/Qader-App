import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/failure.dart';
import '../../domain/entities/talent_evaluation.dart';
import '../../domain/repositories/talent_evaluation_repository.dart';

class TalentEvaluationState {
  const TalentEvaluationState({
    this.loading = false,
    this.evaluation,
    this.unavailable = false,
    this.failure,
  });
  final bool loading;
  final TalentEvaluation? evaluation;

  /// The backend has no evaluation for this talent yet.
  final bool unavailable;
  final Failure? failure;
}

class TalentEvaluationCubit extends Cubit<TalentEvaluationState> {
  TalentEvaluationCubit(this._repository)
    : super(const TalentEvaluationState(loading: true));
  final TalentEvaluationRepository _repository;

  Future<void> load() async {
    emit(TalentEvaluationState(loading: true, evaluation: state.evaluation));
    final result = await _repository.load();
    if (isClosed) return;
    emit(
      result.fold(
        (failure) => TalentEvaluationState(
          failure: failure,
          evaluation: state.evaluation,
        ),
        (evaluation) => evaluation == null
            ? const TalentEvaluationState(unavailable: true)
            : TalentEvaluationState(evaluation: evaluation),
      ),
    );
  }
}
