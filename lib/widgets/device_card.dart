import 'package:flutter/material.dart';
import '../models/device.dart';

class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback onTap;

  const DeviceCard({
    Key? key,
    required this.device,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Верхняя часть карточки: тип устройства и статус
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Тип устройства с иконкой
                  Row(
                    children: [
                      Icon(
                        _getDeviceIcon(device.type),
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getDeviceTypeName(device.type),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  // Статус устройства (в сети/не в сети)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: device.isOnline
                          ? theme.colorScheme.tertiary.withOpacity(0.2)
                          : theme.colorScheme.error.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          device.isOnline
                              ? Icons.check_circle_outline
                              : Icons.error_outline,
                          size: 16,
                          color: device.isOnline
                              ? theme.colorScheme.tertiary
                              : theme.colorScheme.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          device.isOnline ? 'В сети' : 'Не в сети',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: device.isOnline
                                ? theme.colorScheme.tertiary
                                : theme.colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Название устройства
              Text(
                device.name,
                style: theme.textTheme.headlineSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              // Местоположение устройства
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    device.location,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              
              // Специфичные данные устройства
              _buildDeviceSpecificData(context),
            ],
          ),
        ),
      ),
    );
  }

  // Построение специфичных данных в зависимости от типа устройства
  Widget _buildDeviceSpecificData(BuildContext context) {
    final theme = Theme.of(context);
    
    switch (device.type) {
      case DeviceType.thermostat:
        final currentTemp = device.data['currentTemperature'] ?? 0.0;
        final targetTemp = device.data['targetTemperature'] ?? 0.0;
        final isHeatingOn = device.data['isHeatingOn'] ?? false;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDataItem(
                  context,
                  'Текущая',
                  '$currentTemp°C',
                  Icons.thermostat,
                ),
                _buildDataItem(
                  context,
                  'Целевая',
                  '$targetTemp°C',
                  Icons.thermostat_auto,
                ),
                _buildDataItem(
                  context,
                  'Нагрев',
                  isHeatingOn ? 'Вкл' : 'Выкл',
                  isHeatingOn ? Icons.whatshot : Icons.ac_unit,
                  color: isHeatingOn
                      ? theme.colorScheme.error
                      : theme.colorScheme.secondary,
                ),
              ],
            ),
          ],
        );
        
      case DeviceType.camera:
        final isStreamingOn = device.data['isStreamingOn'] ?? false;
        final isLightOn = device.data['isLightOn'] ?? false;
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildDataItem(
              context,
              'Трансляция',
              isStreamingOn ? 'Вкл' : 'Выкл',
              isStreamingOn ? Icons.videocam : Icons.videocam_off,
              color: isStreamingOn
                  ? theme.colorScheme.tertiary
                  : null,
            ),
            _buildDataItem(
              context,
              'Подсветка',
              isLightOn ? 'Вкл' : 'Выкл',
              isLightOn ? Icons.lightbulb : Icons.lightbulb_outline,
              color: isLightOn
                  ? theme.colorScheme.secondary
                  : null,
            ),
          ],
        );
        
      case DeviceType.temperatureSensor:
        final temperature = device.data['temperature'] ?? 0.0;
        
        return Center(
          child: _buildDataItem(
            context,
            'Температура',
            '$temperature°C',
            Icons.thermostat,
            large: true,
          ),
        );
        
      case DeviceType.switch_device:
        final isOn = device.data['isOn'] ?? false;
        
        return Center(
          child: _buildDataItem(
            context,
            'Состояние',
            isOn ? 'Включено' : 'Выключено',
            isOn ? Icons.toggle_on : Icons.toggle_off,
            color: isOn ? theme.colorScheme.tertiary : null,
            large: true,
          ),
        );
    }
  }

  // Вспомогательный метод для построения элемента данных
  Widget _buildDataItem(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
    bool large = false,
  }) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Icon(
          icon,
          size: large ? 32 : 24,
          color: color ?? theme.colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: large
              ? theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)
              : theme.textTheme.bodyMedium,
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
