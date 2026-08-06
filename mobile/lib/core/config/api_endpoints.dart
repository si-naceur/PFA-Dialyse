class ApiEndpoints {
  // Base Django Backend URL
  // For Android Emulator: http://10.0.2.2:8000
  // For iOS Simulator / Web / Desktop / Same Machine: http://127.0.0.1:8000
  static const String baseUrl = 'http://127.0.0.1:8000';

  // Auth
  static const String login = '/api/login/';

  // Monitoring
  static const String realMonitoring = '/api/real-monitoring/';
  static const String pushMeasurement = '/api/push/';
  static const String liveData = '/monitoring/surveillance/';
  static const String alertsHistory = '/monitoring/alerts-history/';
  static const String ackAlert = '/monitoring/ack_alert/';
  static const String resolveAlert = '/monitoring/resolve_alert/';
  static const String seancesHistory = '/monitoring/seances-history/';

  // Patients
  static const String patientsList = '/patients/';
  static const String addPatient = '/patients/add/';
  static const String patientProfile = '/patients/profile/';
  static const String editPatient = '/patients/edit/';

  // Machines
  static const String machinesList = '/machines/';
  static const String addMachine = '/machines/ajout_machine/';
  static const String configMachine = '/machines/configurer/';
  static const String updateMachineStatus = '/machines/update_status/';
  static const String detailsMachine = '/machines/details/';
  static const String raspiManagement = '/machines/raspi/';
  static const String assignRaspi = '/machines/raspi/';

  // Sessions / Seances
  static const String planning = '/seances/';
  static const String createSession = '/seances/create_session/';
  static const String searchSessions = '/seances/sessions/search/';
  static const String preSession = '/seances/';
  static const String postSession = '/seances/';
  static const String cancelSession = '/seances/';

  // Accounts & Profile
  static const String dashboard = '/dashboard/';
  static const String profile = '/profile/';
  static const String doctorsList = '/docteurs/';
  static const String addDoctor = '/add-doctor/';
  static const String nursesList = '/nurses/';
  static const String addNurse = '/nurses/ajouter/';
}
