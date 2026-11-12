import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/failure.dart';
import '../../domain/entities/talent_profile.dart';
import '../../domain/repositories/talent_profile_repository.dart';

class TalentProfileState {
  const TalentProfileState({this.loading = false, this.profile, this.failure});
  final bool loading;
  final TalentProfile? profile;
  final Failure? failure;
}

class TalentProfileCubit extends Cubit<TalentProfileState> {
  TalentProfileCubit(this._repository)
    : super(const TalentProfileState(loading: true));
  final TalentProfileRepository _repository;

  Future<void> load() async {
    emit(TalentProfileState(loading: true, profile: state.profile));
    final result = await _repository.load();
    if (isClosed) return;
    emit(
      result.fold(
        (failure) =>
            TalentProfileState(failure: failure, profile: state.profile),
        (profile) => TalentProfileState(profile: profile),
      ),
    );
  }
}
