enum DeviceType {
  thermostat,
  camera,
  temperatureSensor,
  switch_device,
}

class Device {
  final String id;
  final String name;
  final DeviceType type;
  final String location;
  final bool isOnline;
  
  // Общие данные для всех устройств
  Map<String, dynamic> data;

  Device({
    required this.id,
    required this.name,
    required this.type,
    required this.location,
    required this.isOnline,
    required this.data,
  });

  // Фабричный метод для создания устройства из JSON
  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      name: json['name'],
      type: DeviceType.values.firstWhere(
        (e) => e.toString() == 'DeviceType.${json['type']}',
        orElse: () => DeviceType.switch_device,
      ),
      location: json['location'],
      isOnline: json['isOnline'],
      data: json['data'],
    );
  }

  // Метод для преобразования устройства в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'location': location,
      'isOnline': isOnline,
      'data': data,
    };
  }
}

// Расширения для разных типов устройств
extension ThermostatData on Device {
  double get currentTemperature => data['currentTemperature'] ?? 0.0;
  double get targetTemperature => data['targetTemperature'] ?? 0.0;
  bool get isHeatingOn => data['isHeatingOn'] ?? false;
}

extension CameraData on Device {
  bool get isStreamingOn => data['isStreamingOn'] ?? false;
  bool get isLightOn => data['isLightOn'] ?? false;
  String? get streamUrl => data['streamUrl'];
}

extension TemperatureSensorData on Device {
  double get temperature => data['temperature'] ?? 0.0;
}

extension SwitchData on Device {
  bool get isOn => data['isOn'] ?? false;
}
