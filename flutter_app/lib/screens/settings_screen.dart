import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late DatabaseReference _settingsRef;
  late StreamSubscription _settingsSubscription;
  bool _isLoading = true;
  String _error = '';
  bool _isSaving = false;

  // Settings controllers
  final TextEditingController _keepAliveTimeoutController = TextEditingController();
  final TextEditingController _maxTokensAtOnceController = TextEditingController();
  final TextEditingController _requestTimeoutController = TextEditingController();
  final TextEditingController _wifiPasswordController = TextEditingController();
  final TextEditingController _wifiReconnectTimeoutController = TextEditingController();
  final TextEditingController _wifiSsidController = TextEditingController();
  bool _usePrinter = false;
  bool _showPassword = false;
  
  // Validation errors
  String? _keepAliveTimeoutError;
  String? _maxTokensAtOnceError;
  String? _requestTimeoutError;
  String? _wifiPasswordError;
  String? _wifiReconnectTimeoutError;
  String? _wifiSsidError;

  // Default values
  final Map<String, dynamic> _defaultSettings = {
    'keepAliveTimeout': 10000,
    'maxTokensAtOnce': 10,
    'requestTimeout': 30000,
    'usePrinter': false,
    'wifiPassword': 'esp32123',
    'wifiReconnectTimeout': 30000,
    'wifiSsid': 'IOT_project',
  };

  @override
  void initState() {
    super.initState();
    _settingsRef = FirebaseDatabase.instance.ref().child('LiveEventV3/settings');
    _setupSettingsListener();
  }

  void _setupSettingsListener() {
    _settingsSubscription = _settingsRef.onValue.listen(
      (event) {
        if (event.snapshot.value != null) {
          final data = event.snapshot.value as Map<dynamic, dynamic>;
          _loadSettingsFromData(data);
        } else {
          _loadDefaultSettings();
        }
        setState(() {
          _isLoading = false;
        });
      },
      onError: (error) {
        print('Error in settings listener: $error');
        setState(() {
          _error = error.toString();
          _isLoading = false;
        });
      },
    );
  }

  void _loadSettingsFromData(Map<dynamic, dynamic> data) {
    // Convert milliseconds to seconds for display
    final keepAliveTimeoutMs = data['keepAliveTimeout'] ?? _defaultSettings['keepAliveTimeout'];
    _keepAliveTimeoutController.text = (keepAliveTimeoutMs / 1000).toString();
    
    _maxTokensAtOnceController.text = (data['maxTokensAtOnce'] ?? _defaultSettings['maxTokensAtOnce']).toString();
    
    final requestTimeoutMs = data['requestTimeout'] ?? _defaultSettings['requestTimeout'];
    _requestTimeoutController.text = (requestTimeoutMs / 1000).toString();
    
    _wifiPasswordController.text = data['wifiPassword'] ?? _defaultSettings['wifiPassword'];
    
    final wifiReconnectTimeoutMs = data['wifiReconnectTimeout'] ?? _defaultSettings['wifiReconnectTimeout'];
    _wifiReconnectTimeoutController.text = (wifiReconnectTimeoutMs / 1000).toString();
    
    _wifiSsidController.text = data['wifiSsid'] ?? _defaultSettings['wifiSsid'];
    _usePrinter = data['usePrinter'] ?? _defaultSettings['usePrinter'];
  }

  void _loadDefaultSettings() {
    // Convert milliseconds to seconds for display
    _keepAliveTimeoutController.text = (_defaultSettings['keepAliveTimeout'] / 1000).toString();
    _maxTokensAtOnceController.text = _defaultSettings['maxTokensAtOnce'].toString();
    _requestTimeoutController.text = (_defaultSettings['requestTimeout'] / 1000).toString();
    _wifiPasswordController.text = _defaultSettings['wifiPassword'];
    _wifiReconnectTimeoutController.text = (_defaultSettings['wifiReconnectTimeout'] / 1000).toString();
    _wifiSsidController.text = _defaultSettings['wifiSsid'];
    _usePrinter = _defaultSettings['usePrinter'];
  }

  @override
  void dispose() {
    _settingsSubscription.cancel();
    _keepAliveTimeoutController.dispose();
    _maxTokensAtOnceController.dispose();
    _requestTimeoutController.dispose();
    _wifiPasswordController.dispose();
    _wifiReconnectTimeoutController.dispose();
    _wifiSsidController.dispose();
    super.dispose();
  }

  bool _validateFields() {
    bool isValid = true;
    
    // Clear previous errors
    setState(() {
      _keepAliveTimeoutError = null;
      _maxTokensAtOnceError = null;
      _requestTimeoutError = null;
      _wifiPasswordError = null;
      _wifiReconnectTimeoutError = null;
      _wifiSsidError = null;
    });

    // Validate Keep Alive Timeout
    if (_keepAliveTimeoutController.text.isEmpty) {
      setState(() {
        _keepAliveTimeoutError = 'Keep alive timeout is required';
      });
      isValid = false;
    } else {
      final value = double.tryParse(_keepAliveTimeoutController.text);
      if (value == null || value <= 0) {
        setState(() {
          _keepAliveTimeoutError = 'Must be a positive number';
        });
        isValid = false;
      }
    }

    // Validate Max Tokens at Once
    if (_maxTokensAtOnceController.text.isEmpty) {
      setState(() {
        _maxTokensAtOnceError = 'Max tokens is required';
      });
      isValid = false;
    } else {
      final value = int.tryParse(_maxTokensAtOnceController.text);
      if (value == null || value <= 0) {
        setState(() {
          _maxTokensAtOnceError = 'Must be a positive integer';
        });
        isValid = false;
      }
    }

    // Validate Request Timeout
    if (_requestTimeoutController.text.isEmpty) {
      setState(() {
        _requestTimeoutError = 'Request timeout is required';
      });
      isValid = false;
    } else {
      final value = double.tryParse(_requestTimeoutController.text);
      if (value == null || value <= 0) {
        setState(() {
          _requestTimeoutError = 'Must be a positive number';
        });
        isValid = false;
      }
    }

    // Validate WiFi SSID
    if (_wifiSsidController.text.isEmpty) {
      setState(() {
        _wifiSsidError = 'WiFi SSID is required';
      });
      isValid = false;
    } else if (_wifiSsidController.text.length > 32) {
      setState(() {
        _wifiSsidError = 'SSID must be 32 characters or less';
      });
      isValid = false;
    }

    // Validate WiFi Password
    if (_wifiPasswordController.text.isEmpty) {
      setState(() {
        _wifiPasswordError = 'WiFi password is required';
      });
      isValid = false;
    } else if (_wifiPasswordController.text.length < 8) {
      setState(() {
        _wifiPasswordError = 'Password must be at least 8 characters';
      });
      isValid = false;
    } else if (_wifiPasswordController.text.length > 63) {
      setState(() {
        _wifiPasswordError = 'Password must be 63 characters or less';
      });
      isValid = false;
    }

    // Validate WiFi Reconnect Timeout
    if (_wifiReconnectTimeoutController.text.isEmpty) {
      setState(() {
        _wifiReconnectTimeoutError = 'WiFi reconnect timeout is required';
      });
      isValid = false;
    } else {
      final value = double.tryParse(_wifiReconnectTimeoutController.text);
      if (value == null || value <= 0) {
        setState(() {
          _wifiReconnectTimeoutError = 'Must be a positive number';
        });
        isValid = false;
      }
    }

    return isValid;
  }

  Future<void> _saveSettings() async {
    if (!_validateFields()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the validation errors before saving'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Convert seconds to milliseconds for storage
      final settings = {
        'keepAliveTimeout': (double.parse(_keepAliveTimeoutController.text) * 1000).round(),
        'maxTokensAtOnce': int.parse(_maxTokensAtOnceController.text),
        'requestTimeout': (double.parse(_requestTimeoutController.text) * 1000).round(),
        'usePrinter': _usePrinter,
        'wifiPassword': _wifiPasswordController.text,
        'wifiReconnectTimeout': (double.parse(_wifiReconnectTimeoutController.text) * 1000).round(),
        'wifiSsid': _wifiSsidController.text,
      };

      await _settingsRef.set(settings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text(
          'Are you sure you want to reset all settings to their default values? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _loadDefaultSettings();
      await _saveSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveSettings,
              child: Text('Save', style: TextStyle(color: theme.colorScheme.onPrimary)),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Connection Settings
                            _buildSettingsSection(
                              title: 'Connection Settings',
                              icon: Icons.wifi,
                              children: [
                                _buildNumberField(
                                  label: 'Keep Alive Timeout (seconds)',
                                  controller: _keepAliveTimeoutController,
                                  hint: '10',
                                  errorText: _keepAliveTimeoutError,
                                ),
                                _buildNumberField(
                                  label: 'Request Timeout (seconds)',
                                  controller: _requestTimeoutController,
                                  hint: '30',
                                  errorText: _requestTimeoutError,
                                ),
                                _buildNumberField(
                                  label: 'WiFi Reconnect Timeout (seconds)',
                                  controller: _wifiReconnectTimeoutController,
                                  hint: '30',
                                  errorText: _wifiReconnectTimeoutError,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // WiFi Settings
                            _buildSettingsSection(
                              title: 'WiFi Settings',
                              icon: Icons.router,
                              children: [
                                // Information text
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: theme.colorScheme.primary.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: theme.colorScheme.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'This is the WiFi network that the device creates when it cannot connect to the internet. Users can connect to this network and access a form to configure the local internet WiFi credentials.',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurface.withOpacity(0.8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _buildTextField(
                                  label: 'WiFi SSID',
                                  controller: _wifiSsidController,
                                  hint: 'IOT_project',
                                  errorText: _wifiSsidError,
                                ),
                                _buildTextField(
                                  label: 'WiFi Password',
                                  controller: _wifiPasswordController,
                                  hint: 'esp32123',
                                  isPassword: true,
                                  errorText: _wifiPasswordError,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Token Settings
                            _buildSettingsSection(
                              title: 'Token Settings',
                              icon: Icons.confirmation_number,
                              children: [
                                _buildNumberField(
                                  label: 'Max Tokens at Once',
                                  controller: _maxTokensAtOnceController,
                                  hint: '10',
                                  errorText: _maxTokensAtOnceError,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Printer Settings
                            _buildSettingsSection(
                              title: 'Printer Settings',
                              icon: Icons.print,
                              children: [
                                SwitchListTile(
                                  title: const Text('Use Printer'),
                                  subtitle: const Text('Enable printer functionality'),
                                  value: _usePrinter,
                                  onChanged: (value) {
                                    setState(() {
                                      _usePrinter = value;
                                    });
                                  },
                                  activeColor: theme.colorScheme.primary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _resetToDefaults,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Reset to Defaults'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: theme.colorScheme.error,
                                      side: BorderSide(color: theme.colorScheme.error),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool isPassword = false,
    String? errorText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !_showPassword,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          errorText: errorText,
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _showPassword = !_showPassword;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
    required String hint,
    String? errorText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          errorText: errorText,
        ),
      ),
    );
  }
} 