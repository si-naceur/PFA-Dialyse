import 'package:flutter/foundation.dart' show kIsWeb;

class ApiEndpoints {
  /// Django API base URL.
  ///
  /// On Flutter Web the page host (`localhost` vs `127.0.0.1`) must match the
  /// API host. Browsers treat those as different sites, so a session cookie set
  /// on one is not sent to the other — causing 401 after a successful login.
  static String get baseUrl {
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host == 'localhost' || host == '127.0.0.1') {
        return 'http://$host:8000';
      }
    }
    // Android emulator: http://10.0.2.2:8000
    // iOS simulator / desktop / same machine:
    return 'http://localhost:8000';
  }

  // Auth
  static const String login = '/api/login/';
  static const String logout = '/api/logout/';

  // Dashboard
  static const String dashboard = '/api/dashboard/';

  // Patients
  static const String patients = '/api/patients/';
  static const String patientDetail = '/api/patients/'; // + {patient_id}/

  // Machines
  static const String machines = '/api/machines/';
  static const String machineDetail = '/api/machines/'; // + {machine_id}/

  // Sessions / Seances
  static const String sessions = '/api/sessions/';
  static const String sessionDetail = '/api/sessions/'; // + {session_id}/
  static const String sessionStart = '/api/sessions/'; // + {session_id}/start/
  static const String sessionEnd = '/api/sessions/'; // + {session_id}/end/
  static const String sessionCancel =
      '/api/sessions/'; // + {session_id}/cancel/

  // Alerts
  static const String alerts = '/api/alerts/';
  static const String alertAck = '/api/alerts/'; // + {alert_id}/ack/
  static const String alertResolve = '/api/alerts/'; // + {alert_id}/resolve/

  // Monitoring
  static const String monitoring = '/api/monitoring/';
  static const String monitoringLive = '/api/monitoring/live/';
  static const String realMonitoring = '/api/real-monitoring/';

  // Raspberry Pi / Edge pipeline
  static const String pushMeasurement = '/api/push/';
  static const String seanceDebit = '/api/seance/debit/';
}
