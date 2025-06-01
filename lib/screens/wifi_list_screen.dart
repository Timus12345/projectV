import 'package:flutter/material.dart';
import '../utils/responsive_size.dart';
import '../utils/wifi_service.dart';
import 'dart:async';

class WifiListScreen extends StatefulWidget {
  const WifiListScreen({Key? key}) : super(key: key);

  @override
  State<WifiListScreen> createState() => _WifiListScreenState();
}

class _WifiListScreenState extends State<WifiListScreen> {
  final WifiService _wifiService = WifiService();
  List<SmartHomeWifiNetwork> _networks = [];
  bool _isLoading = true;
  String? _error;
  bool _isAutoRefreshEnabled = true;
  late Timer _refreshTimer;

  @override
  void initState() {
    super.initState();
    _scanNetworks();
    
    // Настраиваем автоматическое обновление списка сетей каждые 15 секунд
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_isAutoRefreshEnabled && mounted) {
        _scanNetworks(showLoading: false);
      }
    });
  }
  
  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }

  Future<void> _scanNetworks({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final networks = await _wifiService.scanNetworks();
      
      // Сортируем сети: сначала подключенная, затем по силе сигнала
      networks.sort((a, b) {
        if (a.isCurrentNetwork) return -1;
        if (b.isCurrentNetwork) return 1;
        return b.signalStrength.compareTo(a.signalStrength);
      });
      
      if (mounted) {
        setState(() {
          _networks = networks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Доступные Wi-Fi сети'),
        centerTitle: true,
        actions: [
          // Кнопка для включения/выключения автообновления
          IconButton(
            icon: Icon(
              _isAutoRefreshEnabled ? Icons.sync : Icons.sync_disabled,
              color: _isAutoRefreshEnabled ? Theme.of(context).primaryColor : Colors.grey,
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
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _scanNetworks(),
        child: const Icon(Icons.refresh),
        tooltip: 'Обновить список сетей',
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: ResponsiveSize.padding(context, horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: ResponsiveSize.iconSize(context, 48),
                color: Colors.red,
              ),
              SizedBox(height: ResponsiveSize.height(context, 2)),
              Text(
                'Ошибка при сканировании сетей',
                style: TextStyle(
                  fontSize: ResponsiveSize.fontSize(context, 18),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ResponsiveSize.height(context, 1)),
              Text(
                _error!,
                style: TextStyle(
                  fontSize: ResponsiveSize.fontSize(context, 14),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ResponsiveSize.height(context, 3)),
              ElevatedButton(
                onPressed: _scanNetworks,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    if (_networks.isEmpty) {
      return Center(
        child: Padding(
          padding: ResponsiveSize.padding(context, horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off,
                size: ResponsiveSize.iconSize(context, 48),
                color: Colors.grey,
              ),
              SizedBox(height: ResponsiveSize.height(context, 2)),
              Text(
                'Сети Wi-Fi не найдены',
                style: TextStyle(
                  fontSize: ResponsiveSize.fontSize(context, 18),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ResponsiveSize.height(context, 1)),
              Text(
                'Убедитесь, что Wi-Fi включен и находится в зоне действия сетей',
                style: TextStyle(
                  fontSize: ResponsiveSize.fontSize(context, 14),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ResponsiveSize.height(context, 3)),
              ElevatedButton(
                onPressed: _scanNetworks,
                child: const Text('Обновить'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _scanNetworks(showLoading: false),
      child: Column(
        children: [
          // Информационная панель о последнем обновлении
          Padding(
            padding: ResponsiveSize.padding(context, horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: ResponsiveSize.iconSize(context, 16),
                  color: Colors.grey,
                ),
                SizedBox(width: ResponsiveSize.width(context, 2)),
                Text(
                  'Проведите вниз для обновления списка',
                  style: TextStyle(
                    fontSize: ResponsiveSize.fontSize(context, 12),
                    color: Colors.grey,
                  ),
                ),
                const Spacer(),
                if (_isAutoRefreshEnabled)
                  Container(
                    padding: ResponsiveSize.padding(context, horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sync,
                          size: ResponsiveSize.iconSize(context, 12),
                          color: Theme.of(context).primaryColor,
                        ),
                        SizedBox(width: ResponsiveSize.width(context, 1)),
                        Text(
                          'Авто',
                          style: TextStyle(
                            fontSize: ResponsiveSize.fontSize(context, 10),
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // Список сетей
          Expanded(
            child: ListView.builder(
              padding: ResponsiveSize.padding(context, vertical: 8, horizontal: 16),
              itemCount: _networks.length,
              itemBuilder: (context, index) {
                final network = _networks[index];
                return _buildNetworkItem(network);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkItem(SmartHomeWifiNetwork network) {
    return Card(
      margin: ResponsiveSize.padding(context, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      // Подсветка текущей сети
      color: network.isCurrentNetwork 
          ? Theme.of(context).primaryColor.withOpacity(0.05) 
          : null,
      child: InkWell(
        onTap: () {
          // Если это текущая сеть, показываем информацию о подключении
          if (network.isCurrentNetwork) {
            _showNetworkInfoDialog(network);
          } else {
            // Иначе переходим к экрану подключения
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WifiPasswordScreen(network: network),
              ),
            ).then((_) {
              // Обновляем список после возврата с экрана подключения
              _scanNetworks(showLoading: false);
            });
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: ResponsiveSize.padding(context, all: 16),
          child: Row(
            children: [
              _buildSignalIcon(network.signalStrength),
              SizedBox(width: ResponsiveSize.width(context, 4)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      network.ssid,
                      style: TextStyle(
                        fontSize: ResponsiveSize.fontSize(context, 16),
                        fontWeight: FontWeight.bold,
                        color: network.isCurrentNetwork 
                            ? Theme.of(context).primaryColor 
                            : null,
                      ),
                    ),
                    SizedBox(height: ResponsiveSize.height(context, 0.5)),
                    Row(
                      children: [
                        Icon(
                          network.isSecure ? Icons.lock : Icons.lock_open,
                          size: ResponsiveSize.iconSize(context, 14),
                          color: Colors.grey,
                        ),
                        SizedBox(width: ResponsiveSize.width(context, 1)),
                        Text(
                          network.isSecure ? 'Защищенная сеть' : 'Открытая сеть',
                          style: TextStyle(
                            fontSize: ResponsiveSize.fontSize(context, 12),
                            color: Colors.grey,
                          ),
                        ),
                        if (network.isCurrentNetwork) ...[
                          SizedBox(width: ResponsiveSize.width(context, 2)),
                          Container(
                            padding: ResponsiveSize.padding(context, horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Подключено',
                              style: TextStyle(
                                fontSize: ResponsiveSize.fontSize(context, 10),
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Индикатор силы сигнала в процентах
              Container(
                width: ResponsiveSize.width(context, 10),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${network.signalStrength}%',
                      style: TextStyle(
                        fontSize: ResponsiveSize.fontSize(context, 12),
                        fontWeight: FontWeight.bold,
                        color: _getSignalColor(network.signalStrength),
                      ),
                    ),
                    SizedBox(height: ResponsiveSize.height(context, 0.5)),
                    Icon(
                      network.isCurrentNetwork ? Icons.info_outline : Icons.arrow_forward_ios,
                      size: ResponsiveSize.iconSize(context, 16),
                      color: network.isCurrentNetwork ? Theme.of(context).primaryColor : Colors.grey,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Диалог с информацией о текущем подключении
  void _showNetworkInfoDialog(SmartHomeWifiNetwork network) async {
    String? ipAddress = await _wifiService.getCurrentWifiIP();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Информация о сети ${network.ssid}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Статус:', 'Подключено'),
            _buildInfoRow('Сила сигнала:', '${network.signalStrength}%'),
            _buildInfoRow('Безопасность:', network.isSecure ? 'Защищенная' : 'Открытая'),
            if (ipAddress != null) _buildInfoRow('IP адрес:', ipAddress),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Закрыть'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Отключаемся от сети
              await _wifiService.disconnect();
              // Обновляем список сетей
              _scanNetworks();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Отключено от сети'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Отключиться'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
  
  // Вспомогательный виджет для строк в диалоге информации
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalIcon(int strength) {
    IconData iconData;
    Color iconColor = _getSignalColor(strength);

    if (strength >= 80) {
      iconData = Icons.signal_wifi_4_bar;
    } else if (strength >= 60) {
      iconData = Icons.network_wifi;
    } else if (strength >= 40) {
      iconData = Icons.signal_wifi_4_bar_lock;
    } else {
      iconData = Icons.signal_wifi_0_bar;
    }

    return Container(
      width: ResponsiveSize.width(context, 10),
      height: ResponsiveSize.width(context, 10),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        size: ResponsiveSize.iconSize(context, 20),
        color: iconColor,
      ),
    );
  }
  
  // Получение цвета в зависимости от силы сигнала
  Color _getSignalColor(int strength) {
    if (strength >= 70) {
      return Colors.green;
    } else if (strength >= 40) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}

class WifiPasswordScreen extends StatefulWidget {
  final SmartHomeWifiNetwork network;

  const WifiPasswordScreen({Key? key, required this.network}) : super(key: key);

  @override
  State<WifiPasswordScreen> createState() => _WifiPasswordScreenState();
}

class _WifiPasswordScreenState extends State<WifiPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final WifiService _wifiService = WifiService();
  bool _isConnecting = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _connectToNetwork() async {
    if (_passwordController.text.isEmpty && widget.network.isSecure) {
      setState(() {
        _error = 'Пожалуйста, введите пароль';
      });
      return;
    }

    setState(() {
      _isConnecting = true;
      _error = null;
    });

    try {
      final bool connected = await _wifiService.connectToNetwork(
        widget.network.ssid,
        _passwordController.text,
      );

      if (connected) {
        if (!mounted) return;
        
        // Переход на экран успешного подключения
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WifiSuccessScreen(
              network: widget.network,
            ),
          ),
        );
      } else {
        setState(() {
          _isConnecting = false;
          _error = 'Не удалось подключиться к сети. Проверьте пароль и попробуйте снова.';
        });
      }
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Подключение к Wi-Fi'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: ResponsiveSize.padding(context, horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildNetworkInfo(),
              SizedBox(height: ResponsiveSize.height(context, 4)),
              if (widget.network.isSecure) _buildPasswordField(),
              SizedBox(height: ResponsiveSize.height(context, 2)),
              if (_error != null) _buildErrorMessage(),
              SizedBox(height: ResponsiveSize.height(context, 4)),
              _buildConnectButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: ResponsiveSize.padding(context, all: 16),
        child: Column(
          children: [
            Icon(
              Icons.wifi,
              size: ResponsiveSize.iconSize(context, 48),
              color: Theme.of(context).primaryColor,
            ),
            SizedBox(height: ResponsiveSize.height(context, 2)),
            Text(
              widget.network.ssid,
              style: TextStyle(
                fontSize: ResponsiveSize.fontSize(context, 20),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveSize.height(context, 1)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.network.isSecure ? Icons.lock : Icons.lock_open,
                  size: ResponsiveSize.iconSize(context, 14),
                  color: Colors.grey,
                ),
                SizedBox(width: ResponsiveSize.width(context, 1)),
                Text(
                  widget.network.isSecure ? 'Защищенная сеть' : 'Открытая сеть',
                  style: TextStyle(
                    fontSize: ResponsiveSize.fontSize(context, 14),
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveSize.height(context, 1)),
            // Индикатор силы сигнала
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.signal_cellular_alt,
                  size: ResponsiveSize.iconSize(context, 14),
                  color: _getSignalColor(widget.network.signalStrength),
                ),
                SizedBox(width: ResponsiveSize.width(context, 1)),
                Text(
                  'Сила сигнала: ${widget.network.signalStrength}%',
                  style: TextStyle(
                    fontSize: ResponsiveSize.fontSize(context, 14),
                    color: _getSignalColor(widget.network.signalStrength),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Пароль',
          style: TextStyle(
            fontSize: ResponsiveSize.fontSize(context, 16),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: ResponsiveSize.height(context, 1)),
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(
            hintText: 'Введите пароль от сети',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          obscureText: _obscurePassword,
          enableSuggestions: false,
          autocorrect: false,
          onSubmitted: (_) => _connectToNetwork(),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: ResponsiveSize.padding(context, all: 12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: ResponsiveSize.iconSize(context, 20),
          ),
          SizedBox(width: ResponsiveSize.width(context, 2)),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(
                color: Colors.red,
                fontSize: ResponsiveSize.fontSize(context, 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectButton() {
    return ElevatedButton(
      onPressed: _isConnecting ? null : _connectToNetwork,
      style: ElevatedButton.styleFrom(
        padding: ResponsiveSize.padding(context, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _isConnecting
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: ResponsiveSize.width(context, 5),
                  height: ResponsiveSize.width(context, 5),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: ResponsiveSize.width(context, 3)),
                const Text('Подключение...'),
              ],
            )
          : const Text('Подключиться'),
    );
  }
  
  // Получение цвета в зависимости от силы сигнала
  Color _getSignalColor(int strength) {
    if (strength >= 70) {
      return Colors.green;
    } else if (strength >= 40) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}

class WifiSuccessScreen extends StatelessWidget {
  final SmartHomeWifiNetwork network;

  const WifiSuccessScreen({Key? key, required this.network}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: ResponsiveSize.padding(context, horizontal: 20, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              _buildSuccessIcon(context),
              SizedBox(height: ResponsiveSize.height(context, 4)),
              _buildSuccessText(context),
              const Spacer(),
              _buildButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon(BuildContext context) {
    return Column(
      children: [
        Container(
          width: ResponsiveSize.width(context, 30),
          height: ResponsiveSize.width(context, 30),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle,
            size: ResponsiveSize.iconSize(context, 60),
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessText(BuildContext context) {
    return Column(
      children: [
        Text(
          'Подключено!',
          style: TextStyle(
            fontSize: ResponsiveSize.fontSize(context, 24),
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: ResponsiveSize.height(context, 2)),
        Text(
          'Вы успешно подключились к сети ${network.ssid}',
          style: TextStyle(
            fontSize: ResponsiveSize.fontSize(context, 16),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: () {
            // Возвращаемся на главный экран
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          style: ElevatedButton.styleFrom(
            padding: ResponsiveSize.padding(context, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('На главную'),
        ),
        SizedBox(height: ResponsiveSize.height(context, 2)),
        OutlinedButton(
          onPressed: () {
            // Возвращаемся к списку Wi-Fi сетей
            Navigator.of(context).pop();
          },
          style: OutlinedButton.styleFrom(
            padding: ResponsiveSize.padding(context, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('К списку сетей'),
        ),
      ],
    );
  }
}


