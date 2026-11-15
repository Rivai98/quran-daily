import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthTokens {
  const GoogleAuthTokens({required this.idToken});
  final String? idToken;
}

abstract interface class GoogleAuthClient {
  Future<GoogleAuthTokens?> authenticate();
  Future<void> signOut();
}

class GoogleSignInAuthClient implements GoogleAuthClient {
  GoogleSignInAuthClient({
    required this.webClientId,
    required this.iosClientId,
    GoogleSignIn? googleSignIn,
  }) : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final String webClientId;
  final String iosClientId;
  final GoogleSignIn _googleSignIn;
  Future<void>? _initialization;

  Future<void> _initialize() => _initialization ??= _googleSignIn.initialize(
        serverClientId: webClientId,
        clientId: iosClientId.isEmpty ? null : iosClientId,
      );

  @override
  Future<GoogleAuthTokens?> authenticate() async {
    await _initialize();
    try {
      final account = await _googleSignIn.authenticate();
      return GoogleAuthTokens(idToken: account.authentication.idToken);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _initialize();
    await _googleSignIn.signOut();
  }
}
