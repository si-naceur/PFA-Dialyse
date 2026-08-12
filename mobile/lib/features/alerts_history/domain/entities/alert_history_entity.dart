/// One row of the "Historique des alertes" page
/// (`monitoring/templates/alerts_history.html`, backed by GET /api/alerts/).
class AlertHistoryEntity {
  final String id;
  final String source;
  final String? sessionId;
  final String? patient;
  final String? machine;
  final String alertType;
  final String message;
  final String dangerLevel; // LOW | MEDIUM | HIGH
  final String severity;
  final String recommendedAction;
  final String status; // NEW | ACK | RESOLVED
  final String? timestamp;

  const AlertHistoryEntity({
    required this.id,
    required this.source,
    this.sessionId,
    this.patient,
    this.machine,
    required this.alertType,
    required this.message,
    required this.dangerLevel,
    required this.severity,
    required this.recommendedAction,
    required this.status,
    this.timestamp,
  });

  bool get isNew => status == 'NEW';
  bool get isAcknowledged => status == 'ACK';
  bool get isResolved => status == 'RESOLVED';

  String get levelLabel {
    switch (dangerLevel.toUpperCase()) {
      case 'HIGH':
        return 'Critique';
      case 'MEDIUM':
        return 'Modéré';
      case 'LOW':
      default:
        return 'Faible';
    }
  }
}
