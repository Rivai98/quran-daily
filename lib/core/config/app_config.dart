class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    this.googleWebClientId = '',
    this.googleIosClientId = '',
  });

  static const supabaseUrlKey = 'SUPABASE_URL';
  static const supabaseAnonKeyKey = 'SUPABASE_ANON_KEY';
  static const googleWebClientIdKey = 'GOOGLE_WEB_CLIENT_ID';
  static const googleIosClientIdKey = 'GOOGLE_IOS_CLIENT_ID';

  final Uri supabaseUrl;
  final String supabaseAnonKey;
  final String googleWebClientId;
  final String googleIosClientId;

  factory AppConfig.fromDartEnvironment() {
    return AppConfig.fromEnvironment(const {
      supabaseUrlKey: String.fromEnvironment(supabaseUrlKey),
      supabaseAnonKeyKey: String.fromEnvironment(supabaseAnonKeyKey),
      googleWebClientIdKey: String.fromEnvironment(googleWebClientIdKey),
      googleIosClientIdKey: String.fromEnvironment(googleIosClientIdKey),
    });
  }

  factory AppConfig.fromEnvironment(Map<String, String> environment) {
    final rawUrl = environment[supabaseUrlKey]?.trim() ?? '';
    final anonKey = environment[supabaseAnonKeyKey]?.trim() ?? '';

    if (rawUrl.isEmpty) {
      throw const AppConfigException('Missing SUPABASE_URL.');
    }
    if (anonKey.isEmpty) {
      throw const AppConfigException('Missing SUPABASE_ANON_KEY.');
    }

    final url = Uri.tryParse(rawUrl);
    if (url == null ||
        !url.hasScheme ||
        url.host.isEmpty ||
        (url.scheme != 'https' && url.scheme != 'http')) {
      throw const AppConfigException('SUPABASE_URL must be an absolute URL.');
    }

    return AppConfig(
      supabaseUrl: url,
      supabaseAnonKey: anonKey,
      googleWebClientId: environment[googleWebClientIdKey]?.trim() ?? '',
      googleIosClientId: environment[googleIosClientIdKey]?.trim() ?? '',
    );
  }
}

class AppConfigException implements Exception {
  const AppConfigException(this.message);

  final String message;

  @override
  String toString() => 'AppConfigException: $message';
}
