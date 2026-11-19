/// The talent's counter offer: body of
/// `POST /talent/hiring-offers/{item}/counter`.
///
/// Fields the dialog does not edit (work type, days, hours) are carried
/// over from the offer being countered.
class CounterOffer {
  const CounterOffer({
    required this.salary,
    required this.workMode,
    required this.noticeDays,
    required this.location,
    this.currencyId,
    this.workType,
    this.firstWorkday,
    this.lastWorkday,
    this.hybridDays = const [],
    this.hoursPerDay,
  });

  /// Monthly salary.
  final num salary;

  /// Backend id of the offer's currency.
  final int? currencyId;

  /// Backend codes, e.g. `full_time`, `hybrid`.
  final String? workType;
  final String workMode;

  /// `DateTime.weekday` values (1 = Monday … 7 = Sunday).
  final int? firstWorkday, lastWorkday;

  /// Office days when [workMode] is `hybrid`.
  final List<int> hybridDays;
  final num? hoursPerDay;
  final int noticeDays;
  final String location;
}
