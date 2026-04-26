class EnvConfig {
  static const String _defaultDesktopApiBaseUrl = 'http://localhost:5220/api';
  static const String _defaultDesktopSignalRUrl =
      'http://localhost:5220/hubs/orders';

  static const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _signalRUrl = String.fromEnvironment('SIGNALR_URL');
  static const String _stripeKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
  );

  static String get baseUrl {
    if (_apiBaseUrl.isNotEmpty) return _apiBaseUrl;
    return _defaultDesktopApiBaseUrl;
  }

  static String get signalRUrl {
    if (_signalRUrl.isNotEmpty) return _signalRUrl;
    return _defaultDesktopSignalRUrl;
  }

  static String get stripePublishableKey => _stripeKey;
}
