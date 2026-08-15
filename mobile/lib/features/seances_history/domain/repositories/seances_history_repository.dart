import '../../domain/entities/seance_history_entity.dart';

abstract class SeancesHistoryRepository {
  Future<List<SeanceHistoryEntity>> getSessions({
    String status = '',
    String date = '',
    String search = '',
    String dateFrom = '',
    String dateTo = '',
  });
}
