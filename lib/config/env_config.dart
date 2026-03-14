class EnvConfig {
  static const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _signalRUrl = String.fromEnvironment('SIGNALR_URL');

  static String get baseUrl {
    if (_apiBaseUrl.isNotEmpty) return _apiBaseUrl;
    return 'http://localhost:5220/api';
  }

  static String get signalRUrl {
    if (_signalRUrl.isNotEmpty) return _signalRUrl;
    return 'http://localhost:5220/hubs/orders';
  }
}
