import 'package:flutter/material.dart';
import '../models/device.dart';
import '../utils/theme.dart';

class DeviceDetailScreen extends StatefulWidget {
  final Device device;

  const DeviceDetailScreen({Key? key, required this.device}) : super(key: key);

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  late Device _device;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _device = widget.device;
  }

  // Обновление состояния устройства
  void _updateDeviceState(Map<String, dynamic> newData) {
    setState(() {
      _isLoading = true;
    });

    // Имитация задержки обновления
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _device = Device(
          id: _device.id,
          name: _device.name,
          type: _device.type,
          location: _device.location,
          isOnline: _device.isOnline,
          data: {..._device.data, ...newData},
        );
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Построение интерфейса в зависимости от типа устройства
    Widget deviceSpecificContent;

    switch (_device.type) {
      case DeviceType.camera:
        deviceSpecificContent = _buildCameraContent(theme);
        break;
      case DeviceType.thermostat:
        deviceSpecificContent = _buildThermostatContent(theme);
        break;
      case DeviceType.temperatureSensor:
        deviceSpecificContent = _buildTemperatureSensorContent(theme);
        break;
      case DeviceType.switch_device:
        deviceSpecificContent = _buildSwitchContent(theme);
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_device.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {

            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Информация об устройстве
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getDeviceIcon(_device.type),
                                size: 24,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getDeviceTypeName(_device.type),
                                style: theme.textTheme.headlineSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 20,
                                color: theme.colorScheme.secondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _device.location,
                                style: theme.textTheme.bodyLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                _device.isOnline
                                    ? Icons.check_circle_outline
                                    : Icons.error_outline,
                                size: 20,
                                color: _device.isOnline
                                    ? theme.colorScheme.tertiary
                                    : theme.colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _device.isOnline ? 'В сети' : 'Не в сети',
                                style: theme.textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Специфичный для устройства контент
                  deviceSpecificContent,
                ],
              ),
            ),
    );
  }

  // Построение интерфейса для камеры
  Widget _buildCameraContent(ThemeData theme) {
    final camera = _device;
    final isStreamingOn = camera.data['isStreamingOn'] ?? false;
    final isLightOn = camera.data['isLightOn'] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Управление камерой',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        
        // Область для вывода изображения
        Container(
          width: double.infinity,
          height: 240,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(12),
          ),
          child: isStreamingOn
              ? Center(
                  child: Image.asset(
                    'assets/images/camera_stream_placeholder.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.videocam_off,
                        size: 48,
                        color: Colors.white70,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Готов к стриму',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 24),
        
        // Кнопки управления
        Padding(
          padding: const EdgeInsets.only(left: 80, bottom: 30),
          child: ElevatedButton.icon(
            onPressed: _device.isOnline
                ? () {
                    _updateDeviceState({
                      'isStreamingOn': !isStreamingOn,
                    });
                  }
                : null,
            icon: Icon(
              isStreamingOn ? Icons.stop : Icons.play_arrow,
            ),
            label: Text(
              isStreamingOn ? 'Остановить' : 'Начать трансляцию',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isStreamingOn
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
            ),
          ),
        ),

        // Кнопка для включения/выключения подсветки
        Padding(
          padding: const EdgeInsets.only(top:0, left: 80),
          child: ElevatedButton.icon(
            onPressed: _device.isOnline
                ? () {
                    _updateDeviceState({
                      'isLightOn': !isLightOn,
                    });
                  }
                : null,
            icon: Icon(
              isLightOn ? Icons.lightbulb : Icons.lightbulb_outline,
            ),
            label: Text(
              isLightOn ? 'Выключить свет' : 'Включить подсветку',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isLightOn
                  ? theme.colorScheme.tertiary
                  : theme.colorScheme.secondary,
              foregroundColor: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  // Построение интерфейса для термостата
  Widget _buildThermostatContent(ThemeData theme) {
    final thermostat = _device;
    final currentTemp = thermostat.data['currentTemperature'] ?? 0.0;
    final targetTemp = thermostat.data['targetTemperature'] ?? 0.0;
    final isHeatingOn = thermostat.data['isHeatingOn'] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Управление термостатом',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 24),
        
        // Текущая и целевая температура
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildTemperatureDisplay(
              theme,
              'Текущая',
              currentTemp,
              Icons.thermostat,
              theme.colorScheme.secondary,
            ),
            _buildTemperatureDisplay(
              theme,
              'Целевая',
              targetTemp,
              Icons.thermostat_auto,
              theme.colorScheme.tertiary,
            ),
          ],
        ),
        const SizedBox(height: 32),
        
        // Слайдер для изменения целевой температуры
        Text(
          'Установить температуру',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Slider(
          value: targetTemp,
          min: 16,
          max: 30,
          divisions: 28,
          label: '${targetTemp.toStringAsFixed(1)}°C',
          onChanged: _device.isOnline
              ? (value) {
                  _updateDeviceState({
                    'targetTemperature': double.parse(value.toStringAsFixed(1)),
                  });
                }
              : null,
        ),
        const SizedBox(height: 24),
        
        // Переключатель нагрева
        SwitchListTile(
          title: Text('Нагрев', style: theme.textTheme.bodyLarge),
          subtitle: Text(
            isHeatingOn ? 'Включен' : 'Выключен',
            style: theme.textTheme.bodyMedium,
          ),
          value: isHeatingOn,
          onChanged: _device.isOnline
              ? (value) {
                  _updateDeviceState({
                    'isHeatingOn': value,
                  });
                }
              : null,
          activeColor: theme.colorScheme.tertiary,
        ),
      ],
    );
  }

  // Построение интерфейса для датчика температуры
  Widget _buildTemperatureSensorContent(ThemeData theme) {
    final sensor = _device;
    final temperature = sensor.data['temperature'] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Данные датчика',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 24),
        
        // Отображение температуры
        Center(
          child: _buildTemperatureDisplay(
            theme,
            'Температура',
            temperature,
            Icons.thermostat,
            theme.colorScheme.secondary,
            large: true,
          ),
        ),
        const SizedBox(height: 24),
        
        // График температуры (заглушка)
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'График температуры',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }

  // Построение интерфейса для переключателя
  Widget _buildSwitchContent(ThemeData theme) {
    final switchDevice = _device;
    final isOn = switchDevice.data['isOn'] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Управление переключателем',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 24),
        
        // Большая кнопка включения/выключения
        Center(
          child: GestureDetector(
            onTap: _device.isOnline
                ? () {
                    _updateDeviceState({
                      'isOn': !isOn,
                    });
                  }
                : null,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOn
                    ? theme.colorScheme.tertiary
                    : theme.cardTheme.color,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.power_settings_new,
                  size: 60,
                  color: isOn
                      ? Colors.white
                      : theme.colorScheme.primary.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Текстовое состояние
        Center(
          child: Text(
            isOn ? 'Включено' : 'Выключено',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: isOn
                  ? theme.colorScheme.tertiary
                  : theme.colorScheme.primary.withOpacity(0.5),
            ),
          ),
        ),
      ],
    );
  }

  // Вспомогательный виджет для отображения температуры
  Widget _buildTemperatureDisplay(
    ThemeData theme,
    String label,
    double temperature,
    IconData icon,
    Color color, {
    bool large = false,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(large ? 24 : 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: large ? 48 : 32,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                '${temperature.toStringAsFixed(1)}°C',
                style: large
                    ? theme.textTheme.headlineMedium
                    : theme.textTheme.headlineSmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Получение иконки для типа устройства
  IconData _getDeviceIcon(DeviceType type) {
    switch (type) {
      case DeviceType.thermostat:
        return Icons.thermostat;
      case DeviceType.camera:
        return Icons.videocam;
      case DeviceType.temperatureSensor:
        return Icons.device_thermostat;
      case DeviceType.switch_device:
        return Icons.power;
    }
  }

  // Получение названия типа устройства
  String _getDeviceTypeName(DeviceType type) {
    switch (type) {
      case DeviceType.thermostat:
        return 'Термостат';
      case DeviceType.camera:
        return 'Камера';
      case DeviceType.temperatureSensor:
        return 'Датчик температуры';
      case DeviceType.switch_device:
        return 'Переключатель';
    }
  }
}
