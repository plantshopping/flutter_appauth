import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isBusy = false;
  final FlutterAppAuth _appAuth = FlutterAppAuth();
  String? _codeVerifier;
  String? _authorizationCode;
  String? _refreshToken;
  String? _accessToken;
  String? _idToken;

  final TextEditingController _authorizationCodeTextController =
      TextEditingController();
  final TextEditingController _accessTokenTextController =
      TextEditingController();
  final TextEditingController _accessTokenExpirationTextController =
      TextEditingController();

  final TextEditingController _idTokenTextController = TextEditingController();
  final TextEditingController _refreshTokenTextController =
      TextEditingController();
  String? _userInfo;

  final String AUTH0_DOMAIN = 'https://icediary.au.auth0.com';
  final String AUTH0_AUDIENCE = 'https://icediaryapi.azurewebsites.net/api';

  // For a list of client IDs, go to https://demo.identityserver.io
  final String _clientId = 'mq3tbMBfleYJzyOY8Pqt3OAstYJrvaWu';
  final String _redirectUrl = 'com.icediary://login-callback';
  final String _issuer = 'https://icediary.au.auth0.com';
  final String _postLogoutRedirectUrl = 'io.identityserver.demo:/';
  final List<String> _scopes = <String>[
    'openid',
    'profile',
    'email',
    'offline_access',
    'api'
  ];

  // TODO Not sure where to get these values
  final AuthorizationServiceConfiguration _serviceConfiguration =
      const AuthorizationServiceConfiguration(
    authorizationEndpoint: 'https://demo.identityserver.io/connect/authorize',
    tokenEndpoint: 'https://demo.identityserver.io/connect/token',
    endSessionEndpoint: 'https://demo.identityserver.io/connect/endsession',
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Visibility(
                visible: _isBusy,
                child: const LinearProgressIndicator(),
              ),
              ElevatedButton(
                child: const Text('Sign in with auto code exchange'),
                onPressed: () => _signInWithAutoCodeExchange(),
              ),
              if (Platform.isIOS)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    child: const Text(
                      'Sign in with auto code exchange using ephemeral session (iOS only)',
                      textAlign: TextAlign.center,
                    ),
                    onPressed: () => _signInWithAutoCodeExchange(
                        preferEphemeralSession: true),
                  ),
                ),
              ElevatedButton(
                child: const Text('Refresh token'),
                onPressed: _refreshToken != null ? _refresh : null,
              ),
              ElevatedButton(
                child: const Text('End session'),
                onPressed: _idToken != null
                    ? () async {
                        await _endSession();
                      }
                    : null,
              ),
              ElevatedButton(
                child: const Text('Test api'),
                onPressed: () async {
                  await _testApi();
                },
              ),
              const Text('authorization code'),
              TextField(
                controller: _authorizationCodeTextController,
              ),
              const Text('access token'),
              TextField(
                controller: _accessTokenTextController,
              ),
              const Text('access token expiration'),
              TextField(
                controller: _accessTokenExpirationTextController,
              ),
              const Text('id token'),
              TextField(
                controller: _idTokenTextController,
              ),
              const Text('refresh token'),
              TextField(
                controller: _refreshTokenTextController,
              ),
              const Text('test api results'),
              Text(_userInfo ?? ''),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _endSession() async {
    try {
      _setBusyState();
      await _appAuth.endSession(EndSessionRequest(
          idTokenHint: _idToken,
          postLogoutRedirectUrl: _postLogoutRedirectUrl,
          serviceConfiguration: _serviceConfiguration));
      _clearSessionInfo();
    } catch (_) {}
    _clearBusyState();
  }

  void _clearSessionInfo() {
    setState(() {
      _codeVerifier = null;
      _authorizationCode = null;
      _authorizationCodeTextController.clear();
      _accessToken = null;
      _accessTokenTextController.clear();
      _idToken = null;
      _idTokenTextController.clear();
      _refreshToken = null;
      _refreshTokenTextController.clear();
      _accessTokenExpirationTextController.clear();
      _userInfo = null;
    });
  }

  Future<void> _refresh() async {
    try {
      _setBusyState();
      final TokenResponse? result = await _appAuth.token(TokenRequest(
          _clientId, _redirectUrl,
          refreshToken: _refreshToken, issuer: _issuer, scopes: _scopes));
      _processTokenResponse(result);
      await _testApi();
    } catch (_) {
      _clearBusyState();
    }
  }

  Future<void> _signInWithAutoCodeExchange(
      {bool preferEphemeralSession = false}) async {
    try {
      _setBusyState();

      final AuthorizationTokenResponse? result =
          await _appAuth.authorizeAndExchangeCode(AuthorizationTokenRequest(
        _clientId,
        _redirectUrl,
        additionalParameters: {
          'audience': 'https://icediaryapi.azurewebsites.net/api'
        },
        issuer: _issuer,
        scopes: _scopes,
        // Prompts user to login even if already signed in, depends on identity provider.
        // promptValues: ['login']),
      ));

      if (result != null) {
        _processAuthTokenResponse(result);
        await _testApi();
      }
    } catch (_) {
      _clearBusyState();
    }
  }

  void _clearBusyState() {
    setState(() {
      _isBusy = false;
    });
  }

  void _setBusyState() {
    setState(() {
      _isBusy = true;
    });
  }

  void _processAuthTokenResponse(AuthorizationTokenResponse response) {
    setState(() {
      _accessToken = _accessTokenTextController.text = response.accessToken!;
      _idToken = _idTokenTextController.text = response.idToken!;
      _refreshToken = _refreshTokenTextController.text = response.refreshToken!;
      _accessTokenExpirationTextController.text =
          response.accessTokenExpirationDateTime!.toIso8601String();
    });
  }

  void _processTokenResponse(TokenResponse? response) {
    setState(() {
      _accessToken = _accessTokenTextController.text = response!.accessToken!;
      _idToken = _idTokenTextController.text = response.idToken!;
      _refreshToken = _refreshTokenTextController.text = response.refreshToken!;
      _accessTokenExpirationTextController.text =
          response.accessTokenExpirationDateTime!.toIso8601String();
    });
  }

  Future<void> _testApi() async {
    final http.Response httpResponse = await http.get(
        Uri.parse('https://icediaryapi.azurewebsites.net/api/Entity/GetAll'),
        headers: <String, String>{'Authorization': 'Bearer $_accessToken'});
    setState(() {
      _userInfo = httpResponse.statusCode == 200 ? httpResponse.body : '';
      _isBusy = false;
    });
  }
}
