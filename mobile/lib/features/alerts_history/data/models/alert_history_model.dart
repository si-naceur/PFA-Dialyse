import '../../domain/entities/alert_history_entity.dart';

class AlertHistoryModel {
  const AlertHistoryModel._();

  static AlertHistoryEntity fromJson(Map<String, dynamic> json) {
    return AlertHistoryEntity(
      id: json['id']?.toString() ?? '',
      source: json['source'] as String? ?? '',
      sessionId: json['session_id'] as String?,
      patient: json['patient'] as String?,
      machine: json['machine'] as String?,
      alertType: json['alert_type'] as String? ?? '',
      message: json['message'] as String? ?? '',
      dangerLevel: json['danger_level'] as String? ?? '',
      severity:
          json['severity'] as String? ?? json['danger_level'] as String? ?? '',
      recommendedAction: json['recommended_action'] as String? ?? '',
      status: json['status'] as String? ?? 'NEW',
      timestamp: json['timestamp'] as String?,
    );
  }

  static List<AlertHistoryEntity> listFromJson(List<dynamic> json) {
    return json
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}
