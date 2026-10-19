// TODO: Replace with your feature repository
//
// import '../../../../core/network/api_consumer.dart';
// import '../../../../core/network/either.dart';
// import '../../../../core/network/end_points.dart';
// import '../../../../core/network/failure.dart';
//
// abstract class FeatureRepo {
//   Future<Either<Failure, List<YourModel>>> getData();
// }
//
// class FeatureRepoImpl implements FeatureRepo {
//   final ApiConsumer _api;
//   FeatureRepoImpl(this._api);
//
//   @override
//   Future<Either<Failure, List<YourModel>>> getData() async {
//     return await _api.get(
//       EndPoints.yourEndpoint,
//       fromJson: (json) {
//         final list = json['data'] as List;
//         return list.map((e) => YourModel.fromJson(e)).toList();
//       },
//     );
//   }
// }
