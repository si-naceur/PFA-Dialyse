import '../../domain/entities/machine_entity.dart';

class RaspiModel {
  final String raspiId;
  final String? description;
  final bool isActive;
  final String? lastSeen;

  const RaspiModel({
    required this.raspiId,
    this.description,
    required this.isActive,
    this.lastSeen,
  });

  factory RaspiModel.fromJson(Map<String, dynamic> json) {
    return RaspiModel(
      raspiId: json['raspi_id'] as String? ?? '',
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? false,
      lastSeen: json['last_seen'] as String?,
    );
  }

  RaspiEntity toEntity() {
    return RaspiEntity(
      raspiId: raspiId,
      description: description,
      isActive: isActive,
      lastSeen: lastSeen,
    );
  }
}

class MachineModel {
  final int id;
  final String machineId;
  final String model;
  final String manufacturer;
  final String? installationDate;
  final String status;
  final String location;
  final int sessions;
  final double hours;
  final RaspiModel? raspi;

  const MachineModel({
    required this.id,
    required this.machineId,
    required this.model,
    required this.manufacturer,
    this.installationDate,
    required this.status,
    required this.location,
    required this.sessions,
    required this.hours,
    this.raspi,
  });

  factory MachineModel.fromJson(Map<String, dynamic> json) {
    return MachineModel(
      id: (json['id'] as num).toInt(),
      machineId: json['machine_id'] as String? ?? '',
      model: json['model'] as String? ?? '',
      manufacturer: json['manufacturer'] as String? ?? '',
      installationDate: json['installation_date'] as String?,
      status: json['status'] as String? ?? '',
      location: json['location'] as String? ?? '',
      sessions: (json['sessions'] as num?)?.toInt() ?? 0,
      hours: (json['hours'] as num?)?.toDouble() ?? 0.0,
      raspi: json['raspi'] != null
          ? RaspiModel.fromJson(json['raspi'] as Map<String, dynamic>)
          : null,
    );
  }

  MachineEntity toEntity() {
    return MachineEntity(
      id: id,
      machineId: machineId,
      model: model,
      manufacturer: manufacturer,
      installationDate: installationDate,
      status: status,
      location: location,
      sessions: sessions,
      hours: hours,
      raspi: raspi?.toEntity(),
    );
  }
}
