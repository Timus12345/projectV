import 'package:flutter/material.dart';
import 'dart:async';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/wifi_service.dart';
import '../utils/responsive_size.dart';

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({Key? key}) : super(key: key);

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  int _currentStep = 0;
  List<SmartHomeWifiNetwork> _wifiNetworks = [];
  SmartHomeWifiNetwork? _selectedNetwork;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _deviceNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  bool _isConnecting = false;
  bool _isConnected = false;
  bool _showPassword = false;
  bool _isScanning = false;
  bool _isAutoRefreshEnabled = false;
  String _errorMessage = '';
  final WifiService _wifiService = WifiService();
  StreamSubscription? _connectivitySubscription;
  String? _connectedWifi;
  Timer? _refreshTimer;
  bool _returnedFromSystemSettings = false;

  @override
  void initState() {
    super.initState();
    // Открываем системные настройки WiFi при первом запуске экрана
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openSystemWifiSettings();
    });
    
    _initConnectivityListener();
    
    // Настраиваем автоматическое обновление списка сетей каждые 10 секунд
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_isAutoRefreshEnabled && mounted && _currentStep == 0) {
        _checkPermissionsAndScanWifi(showLoading: false);
      }
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _deviceNameController.dispose();
    _locationController.dispose();
    _connectivitySubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  // Открытие системных настроек WiFi
  Future<void> _openSystemWifiSettings() async {
    try {
      await _wifiService.openSystemWifiSettings();
      setState(() {
        _returnedFromSystemSettings = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при открытии настроек Wi-Fi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Инициализация слушателя подключения
  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.wifi) {
        _updateConnectedWifi();
        
        // Если вернулись из системных настроек и подключились к WiFi
        if (!_returnedFromSystemSettings) {
          setState(() {
            _returnedFromSystemSettings = true;
          });
          
          // Проверяем и сканируем сети после возврата из системных настроек
          _checkPermissionsAndScanWifi(showLoading: true);
        }
      } else {
        setState(() {
          _connectedWifi = null;
        });
      }
    });
    
    // Получение текущего подключения при запуске
    _updateConnectedWifi();
  }

  // Обновление информации о текущем Wi-Fi
  Future<void> _updateConnectedWifi() async {
    try {
      final ssid = await _wifiService.getCurrentWifiName();
      
      if (mounted) {
        setState(() {
          _connectedWifi = ssid;
          
          // Если вернулись из системных настроек и есть подключение к WiFi,
          // автоматически выбираем эту сеть
          if (_returnedFromSystemSettings && ssid != null && _currentStep == 0) {
            // Ищем сеть в списке или создаем новую
            SmartHomeWifiNetwork? network = _wifiNetworks.firstWhere(
              (net) => net.ssid == ssid,
              orElse: () => SmartHomeWifiNetwork(
                ssid: ssid,
                signalStrength: 100,
                isCurrentNetwork: true,
              ),
            );
            
            _selectWifiNetwork(network);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _connectedWifi = null;
        });
      }
    }
  }

  // Проверка разрешений и сканирование Wi-Fi
  Future<void> _checkPermissionsAndScanWifi({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isScanning = true;
        _errorMessage = '';
      });
    }

    try {
      // Получение списка сетей
      final networks = await _wifiService.scanNetworks();
      
      // Сортируем сети: сначала по силе сигнала, затем по имени
      networks.sort((a, b) {
        // Если одна из сетей - текущая, она идет первой
        if (a.isCurrentNetwork && !b.isCurrentNetwork) return -1;
        if (!a.isCurrentNetwork && b.isCurrentNetwork) return 1;
        
        // Иначе сортируем по силе сигнала
        return b.signalStrength.compareTo(a.signalStrength);
      });
      
      if (mounted) {
        setState(() {
          _wifiNetworks = networks;
          _isScanning = false;
        });
        
        // Если вернулись из системных настроек и есть подключение к WiFi,
        // автоматически выбираем эту сеть
        if (_returnedFromSystemSettings && _connectedWifi != null && _currentStep == 0) {
          // Ищем сеть в списке
          final networkIndex = networks.indexWhere((net) => net.ssid == _connectedWifi);
          if (networkIndex != -1) {
            _selectWifiNetwork(networks[networkIndex]);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _selectWifiNetwork(SmartHomeWifiNetwork network) {
    setState(() {
      _selectedNetwork = network;
      _currentStep = 1;
    });
  }

  // Подключение к выбранной Wi-Fi сети
  Future<void> _connectToWifi() async {
    if (_passwordController.text.isEmpty && _selectedNetwork!.isSecure) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, введите пароль'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isConnecting = true;
      _errorMessage = '';
    });

    try {
      // Подключение к сети
      final connected = await _wifiService.connectToNetwork(
        _selectedNetwork!.ssid,
        _passwordController.text,
      );

      if (connected) {
        setState(() {
          _isConnecting = false;
          _isConnected = true;
          _currentStep = 2;
        });
        
        // Обновляем информацию о текущем подключении
        _updateConnectedWifi();
      } else {
        setState(() {
          _isConnecting = false;
          _errorMessage = 'Не удалось подключиться к сети';
        });
      }
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _errorMessage = e.toString();
      });
    }
  }

  // Подключение устройства к Wi-Fi
  Future<void> _connectDeviceToWifi() async {
    if (_passwordController.text.isEmpty && _selectedNetwork!.isSecure) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, введите пароль'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isConnecting = true;
      _errorMessage = '';
    });

    try {
      // Здесь будет код для настройки устройства через BLE или другой протокол
      // Имитация процесса настройки устройства
      await Future.delayed(const Duration(seconds: 3));
      
      setState(() {
        _isConnecting = false;
        _currentStep = 3;
      });
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _finishSetup() {
    if (_deviceNameController.text.isEmpty || _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, заполните все поля'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isConnecting = true;
    });

    // Имитация завершения настройки
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Устройство успешно добавлено'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавление устройства'),
        actions: [
          // Кнопка для вызова системных настроек WiFi
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSystemWifiSettings,
            tooltip: 'Системные настройки Wi-Fi',
          ),
          // Кнопка для включения/выключения автообновления
          if (_currentStep == 0)
            IconButton(
              icon: Icon(
                _isAutoRefreshEnabled ? Icons.sync : Icons.sync_disabled,
                color: _isAutoRefreshEnabled ? theme.colorScheme.primary : Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _isAutoRefreshEnabled = !_isAutoRefreshEnabled;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _isAutoRefreshEnabled 
                          ? 'Автообновление включено' 
                          : 'Автообновление выключено'
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              tooltip: 'Автообновление',
            ),
        ],
      ),
      body: Stepper(
        currentStep: _currentStep,
        controlsBuilder: (context, details) {
          return const SizedBox.shrink();
        },
        steps: [
          // Шаг 1: Выбор WiFi сети
          Step(
            title: const Text('Выберите WiFi сеть'),
            subtitle: const Text('Для подключения к устройству'),
            content: _buildWifiNetworksList(theme),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          ),
          
          // Шаг 2: Подключение к WiFi
          Step(
            title: const Text('Подключение к WiFi'),
            subtitle: Text('Подключение к ${_selectedNetwork?.ssid ?? ""}'),
            content: _buildWifiPasswordInput(theme),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          ),
          
          // Шаг 3: Подключение устройства к WiFi
          Step(
            title: const Text('Подключение устройства'),
            subtitle: const Text('Настройка WiFi для устройства'),
            content: _buildDeviceWifiSetup(theme),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
          ),
          
          // Шаг 4: Настройка устройства
          Step(
            title: const Text('Настройка устройства'),
            subtitle: const Text('Завершение настройки'),
            content: _buildDeviceSetup(theme),
            isActive: _currentStep >= 3,
            state: _currentStep > 3 ? StepState.complete : StepState.indexed,
          ),
        ],
      ),
    );
  }

  // Построение списка WiFi сетей
  Widget _buildWifiNetworksList(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Доступные сети:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        if (_connectedWifi != null) ...[
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.wifi, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Текущее подключение: $_connectedWifi',
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        if (_errorMessage.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        
        if (_isScanning)
          const Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Сканирование Wi-Fi сетей...'),
              ],
            ),
          )
        else if (_wifiNetworks.isEmpty && _errorMessage.isEmpty)
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.wifi_off,
                  size: 48,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Wi-Fi сети не найдены',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Убедитесь, что устройство создало Wi-Fi точку доступа',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _wifiNetworks.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade300),
              itemBuilder: (context, index) {
                final network = _wifiNetworks[index];
                return _buildNetworkItem(network, theme);
              },
            ),
          ),
        
        const SizedBox(height: 16),
        
        // Информационная панель о статусе автообновления
        if (_isAutoRefreshEnabled) 
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Автоматическое обновление списка сетей включено',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        
        // Кнопки действий
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isScanning ? null : () => _checkPermissionsAndScanWifi(),
                icon: const Icon(Icons.refresh),
                label: const Text('Обновить список'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _openSystemWifiSettings,
                icon: const Icon(Icons.settings),
                label: const Text('Системные настройки'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: theme.colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  // Построение элемента списка Wi-Fi сетей
  Widget _buildNetworkItem(SmartHomeWifiNetwork network, ThemeData theme) {
    final bool isDeviceAP = network.ssid.contains('Device') || 
                           network.ssid.contains('ESP') || 
                           network.ssid.contains('IoT') ||
                           network.ssid.startsWith('Smart');
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getSignalStrengthColor(network.signalStrength).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            isDeviceAP ? Icons.devices : Icons.wifi,
            color: _getSignalStrengthColor(network.signalStrength),
            size: 24,
          ),
        ),
      ),
      title: Text(
        network.ssid,
        style: TextStyle(
          fontWeight: network.isCurrentNetwork || isDeviceAP ? FontWeight.bold : FontWeight.normal,
          color: isDeviceAP ? theme.colorScheme.primary : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                network.isSecure ? Icons.lock_outline : Icons.lock_open,
                size: 14,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                network.isSecure ? 'Защищенная' : 'Открытая',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getSignalStrengthColor(network.signalStrength).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${network.signalStrength}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getSignalStrengthColor(network.signalStrength),
                  ),
                ),
              ),
              if (isDeviceAP) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Устройство',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
              if (network.isCurrentNetwork) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Подключено',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _selectWifiNetwork(network),
    );
  }

  // Получение цвета в зависимости от уровня сигнала
  Color _getSignalStrengthColor(int strength) {
    if (strength >= 70) {
      return Colors.green;
    } else if (strength >= 40) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  // Построение формы ввода пароля WiFi
  Widget _buildWifiPasswordInput(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.wifi,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Сеть: ${_selectedNetwork?.ssid ?? ""}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Информация о силе сигнала
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getSignalStrengthColor(_selectedNetwork?.signalStrength ?? 0).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.signal_cellular_alt,
                color: _getSignalStrengthColor(_selectedNetwork?.signalStrength ?? 0),
              ),
              const SizedBox(width: 8),
              Text(
                'Сила сигнала: ${_selectedNetwork?.signalStrength ?? 0}%',
                style: TextStyle(
                  color: _getSignalStrengthColor(_selectedNetwork?.signalStrength ?? 0),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        if (_errorMessage.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        
        if (_selectedNetwork?.isSecure ?? true)
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Пароль',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _showPassword = !_showPassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            obscureText: !_showPassword,
            onSubmitted: (_) => _connectToWifi(),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_open, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Открытая сеть, пароль не требуется',
                  style: TextStyle(color: Colors.green),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        
        // Кнопки действий
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isConnecting ? null : () {
                  setState(() {
                    _currentStep = 0;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Назад'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isConnecting ? null : _connectToWifi,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isConnecting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Подключиться'),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Кнопка для открытия системных настроек
        Center(
          child: TextButton.icon(
            onPressed: _openSystemWifiSettings,
            icon: const Icon(Icons.settings),
            label: const Text('Открыть системные настройки Wi-Fi'),
          ),
        ),
        
        if (_isConnected) ...[
          const SizedBox(height: 16),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text('Подключено'),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // Построение формы настройки WiFi для устройства
  Widget _buildDeviceWifiSetup(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Выберите WiFi сеть для устройства:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        if (_errorMessage.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        
        // Информация о выбранной сети
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.wifi,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Сеть: ${_selectedNetwork?.ssid ?? ""}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    _selectedNetwork?.isSecure ?? true ? Icons.lock_outline : Icons.lock_open,
                    color: theme.colorScheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedNetwork?.isSecure ?? true ? 'Защищенная сеть' : 'Открытая сеть',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        const Text(
          'Устройство будет подключено к выбранной сети:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        // Информация о пароле
        if (_selectedNetwork?.isSecure ?? true)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Пароль:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.lock_outline, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _showPassword ? _passwordController.text : '•' * _passwordController.text.length,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility_off : Icons.visibility,
                        size: 16,
                      ),
                      onPressed: () {
                        setState(() {
                          _showPassword = !_showPassword;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_open, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Открытая сеть, пароль не требуется',
                  style: TextStyle(color: Colors.green),
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 24),
        
        // Кнопки действий
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isConnecting ? null : () {
                  setState(() {
                    _currentStep = 1;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Назад'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isConnecting ? null : _connectDeviceToWifi,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isConnecting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Подключить устройство'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Построение формы настройки устройства
  Widget _buildDeviceSetup(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Устройство успешно подключено к сети',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        // Информация о подключении
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Устройство подключено к сети ${_selectedNetwork?.ssid ?? ""}',
                  style: const TextStyle(color: Colors.green),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        const Text(
          'Завершите настройку устройства:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        // Поле для имени устройства
        TextField(
          controller: _deviceNameController,
          decoration: InputDecoration(
            labelText: 'Название устройства',
            prefixIcon: const Icon(Icons.devices),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Поле для местоположения
        TextField(
          controller: _locationController,
          decoration: InputDecoration(
            labelText: 'Местоположение',
            prefixIcon: const Icon(Icons.location_on),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Кнопки действий
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isConnecting ? null : () {
                  setState(() {
                    _currentStep = 2;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Назад'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isConnecting ? null : _finishSetup,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isConnecting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Завершить настройку'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
