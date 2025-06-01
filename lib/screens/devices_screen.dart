import 'package:flutter/material.dart';
import '../models/device.dart';
import '../widgets/device_card.dart';
import 'add_device_screen.dart';
import 'device_detail_screen.dart';
import 'login_screen.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({Key? key}) : super(key: key);

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  late List<Device> _devices;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  // Имитация загрузки устройств
  Future<void> _loadDevices() async {
    await Future.delayed(const Duration(seconds: 1));
    
    // Демо-данные для устройств
    _devices = [
      Device(
        id: '1',
        name: 'Термостат гостиной',
        type: DeviceType.thermostat,
        location: 'Гостиная',
        isOnline: true,
        data: {
          'currentTemperature': 22.5,
          'targetTemperature': 24.0,
          'isHeatingOn': true,
        },
      ),
      Device(
        id: '2',
        name: 'Камера входной двери',
        type: DeviceType.camera,
        location: 'Прихожая',
        isOnline: true,
        data: {
          'isStreamingOn': false,
          'isLightOn': false,
          'streamUrl': 'https://example.com/stream/1',
        },
      ),
      Device(
        id: '3',
        name: 'Датчик температуры',
        type: DeviceType.temperatureSensor,
        location: 'Спальня',
        isOnline: true,
        data: {
          'temperature': 21.0,
        },
      ),
      Device(
        id: '4',
        name: 'Умная розетка',
        type: DeviceType.switch_device,
        location: 'Кухня',
        isOnline: false,
        data: {
          'isOn': false,
        },
      ),
      Device(
        id: '5',
        name: 'Камера заднего двора',
        type: DeviceType.camera,
        location: 'Задний двор',
        isOnline: true,
        data: {
          'isStreamingOn': true,
          'isLightOn': true,
          'streamUrl': 'https://example.com/stream/2',
        },
      ),
    ];

    setState(() {
      _isLoading = false;
    });
  }

  void _logout() {
    // Переход на экран входа при выходе из профиля
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
      (route) => false, // Удаляем все предыдущие экраны из стека
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои устройства'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadDevices();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Выйти из профиля',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _devices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.devices_other,
                        size: 64,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Устройства не найдены',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Добавьте новое устройство, нажав на кнопку ниже',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDevices,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: DeviceCard(
                          device: device,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => DeviceDetailScreen(device: device),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddDeviceScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
