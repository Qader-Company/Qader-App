import 'package:flutter_test/flutter_test.dart';
import 'package:qader/core/network/api_consumer.dart';
import 'package:qader/core/network/either.dart';
import 'package:qader/core/network/failure.dart';
import 'package:qader/features/home/data/repositories/api_application_repository.dart';
import 'package:qader/features/home/presentation/cubit/application_cubit.dart';
import 'package:qader/features/home/presentation/status_copy.dart';

class _Api extends Fake implements ApiConsumer {
  final posts = <(String, Object?)>[];
  int gets = 0;
  String screenState = 'interview_slot_required';
  Failure? postFailure;

  @override
  Future<Either<Failure, T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) fromJson,
  }) async {
    gets++;
    return Right(
      fromJson({
        'success': true,
        'data': {'id': 1, 'status': 'x', 'screen_state': screenState},
      }),
    );
  }

  @override
  Future<Either<Failure, T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? authToken,
    String? contentType,
    required T Function(dynamic json) fromJson,
  }) async {
    posts.add((path, data));
    if (postFailure case final failure?) return Left(failure);
    return Right(fromJson({'success': true, 'message': 'ok'}));
  }
}

void main() {
  test('actions call the talent endpoints with the right bodies', () async {
    final api = _Api();
    final repository = ApiApplicationRepository(api);
    await repository.selectSlot(21);
    await repository.rejectSlots('I am unavailable on all offered dates.');
    await repository.cancelInterview();
    expect(api.posts.map((post) => post.$1), [
      '/talent/application/interview/slots/21/select',
      '/talent/application/interview/slots/reject',
      '/talent/application/interview/cancel',
    ]);
    expect(api.posts[0].$2, isNull);
    expect(api.posts[1].$2, {
      'reason': 'I am unavailable on all offered dates.',
    });
    expect(api.posts[2].$2, isNull);
  });

  test('cubit reloads after an action and surfaces failures', () async {
    final api = _Api();
    final cubit = ApplicationCubit(ApiApplicationRepository(api));
    addTearDown(cubit.close);
    await cubit.load();
    expect(cubit.state.application!.viewStatus, ApplicationStatus.slots);

    api.screenState = 'interview_confirmed';
    expect(await cubit.selectSlot(21), isNull);
    expect(api.gets, 2);
    expect(cubit.state.application!.viewStatus, ApplicationStatus.confirmed);
    expect(cubit.state.submitting, isFalse);

    api.postFailure = const ServerFailure(
      message: 'You can no longer reschedule this interview.',
    );
    final failure = await cubit.cancelInterview();
    expect(failure?.message, 'You can no longer reschedule this interview.');
    expect(api.gets, 3);
  });
}
