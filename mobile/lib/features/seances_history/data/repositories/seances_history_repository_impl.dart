import '../../domain/entities/seance_history_entity.dart';
import '../../domain/repositories/seances_history_repository.dart';
import '../datasources/seances_history_remote_datasource.dart';

class SeancesHistoryRepositoryImpl implements SeancesHistoryRepository {
  final SeancesHistoryRemoteDatasource _datasource;

  SeancesHistoryRepositoryImpl(this._datasource);

  @override
  Future<List<SeanceHistoryEntity>> getSessions({
    String status = '',
    String date = '',
    String search = '',
    String dateFrom = '',
    String dateTo = '',
  }) {
    return _datasource.getSessions(
      status: status,
      date: date,
      search: search,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
  }
}
