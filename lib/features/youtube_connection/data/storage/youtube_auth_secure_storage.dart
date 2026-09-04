import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/models/youtube_connection.dart';

abstract interface class SecureKeyValueStore {
  Future<String?> read(String key);

  Future<void> write(String key, String? value);

  Future<void> delete(String key);
}

class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  const FlutterSecureKeyValueStore([
    this._storage = const FlutterSecureStorage(),
  ]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String? value) {
    return _storage.write(key: key, value: value);
  }

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class YouTubeAuthSecureStorage {
  YouTubeAuthSecureStorage({SecureKeyValueStore? storage})
    : _storage = storage ?? const FlutterSecureKeyValueStore();

  static const _connectionKey = 'youtube_connection.validated_connection';
  static const _accountIdentifierKey = 'youtube_connection.account_identifier';
  static const _displayNameKey = 'youtube_connection.display_name';
  static const _connectedAtKey = 'youtube_connection.connected_at';
  static const _validatedAtKey = 'youtube_connection.validated_at';

  final SecureKeyValueStore _storage;

  Future<void> saveValidatedConnection(YouTubeConnection connection) async {
    if (!connection.canContinue ||
        connection.accountIdentifier == null ||
        connection.connectedAt == null ||
        connection.innerTubeValidatedAt == null) {
      throw ArgumentError('Only a validated connection can be persisted.');
    }

    final payload = jsonEncode({
      'version': 1,
      'accountIdentifier': connection.accountIdentifier,
      'displayName': connection.displayName,
      'connectedAt': connection.connectedAt!.toUtc().toIso8601String(),
      'validatedAt': connection.innerTubeValidatedAt!.toUtc().toIso8601String(),
    });
    await _storage.write(_connectionKey, payload);
    await _deleteLegacyValues();
  }

  Future<YouTubeConnection?> readValidatedConnection() async {
    try {
      final serializedConnection = await _storage.read(_connectionKey);
      if (serializedConnection == null) {
        return _readLegacyConnection();
      }

      final connection = _decodeConnection(serializedConnection);
      if (connection == null) {
        await _clearIgnoringErrors();
      }
      return connection;
    } catch (_) {
      await _clearIgnoringErrors();
      return null;
    }
  }

  Future<void> clear() {
    return Future.wait([
      _storage.delete(_connectionKey),
      _storage.delete(_accountIdentifierKey),
      _storage.delete(_displayNameKey),
      _storage.delete(_connectedAtKey),
      _storage.delete(_validatedAtKey),
    ]);
  }

  YouTubeConnection? _decodeConnection(String serializedConnection) {
    final decoded = jsonDecode(serializedConnection);
    if (decoded is! Map<String, dynamic> || decoded['version'] != 1) {
      return null;
    }

    return _connectionFromValues(
      accountIdentifier: decoded['accountIdentifier'],
      displayName: decoded['displayName'],
      connectedAtValue: decoded['connectedAt'],
      validatedAtValue: decoded['validatedAt'],
    );
  }

  Future<YouTubeConnection?> _readLegacyConnection() async {
    final values = await Future.wait([
      _storage.read(_accountIdentifierKey),
      _storage.read(_displayNameKey),
      _storage.read(_connectedAtKey),
      _storage.read(_validatedAtKey),
    ]);
    if (values.every((value) => value == null)) {
      return null;
    }

    final connection = _connectionFromValues(
      accountIdentifier: values[0],
      displayName: values[1],
      connectedAtValue: values[2],
      validatedAtValue: values[3],
    );
    if (connection == null) {
      await _clearIgnoringErrors();
      return null;
    }

    await saveValidatedConnection(connection);
    return connection;
  }

  YouTubeConnection? _connectionFromValues({
    required Object? accountIdentifier,
    required Object? displayName,
    required Object? connectedAtValue,
    required Object? validatedAtValue,
  }) {
    final connectedAt = DateTime.tryParse(connectedAtValue?.toString() ?? '');
    final validatedAt = DateTime.tryParse(validatedAtValue?.toString() ?? '');
    if (accountIdentifier is! String ||
        accountIdentifier.isEmpty ||
        connectedAt == null ||
        validatedAt == null) {
      return null;
    }

    return YouTubeConnection.connected(
      accountIdentifier: accountIdentifier,
      displayName: displayName is String ? displayName : null,
      connectedAt: connectedAt,
      innerTubeValidatedAt: validatedAt,
    );
  }

  Future<void> _deleteLegacyValues() async {
    for (final key in _legacyKeys) {
      try {
        await _storage.delete(key);
      } catch (_) {
        // The atomic payload is already saved; legacy cleanup is best-effort.
      }
    }
  }

  Future<void> _clearIgnoringErrors() async {
    for (final key in [_connectionKey, ..._legacyKeys]) {
      try {
        await _storage.delete(key);
      } catch (_) {
        // Recovery must return a disconnected state even if storage is down.
      }
    }
  }

  static const _legacyKeys = [
    _accountIdentifierKey,
    _displayNameKey,
    _connectedAtKey,
    _validatedAtKey,
  ];
}
