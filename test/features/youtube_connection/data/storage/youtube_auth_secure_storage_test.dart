import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:transfer_aplicationn/features/youtube_connection/data/storage/youtube_auth_secure_storage.dart';
import 'package:transfer_aplicationn/features/youtube_connection/domain/models/youtube_connection.dart';

void main() {
  const connectionKey = 'youtube_connection.validated_connection';
  const accountKey = 'youtube_connection.account_identifier';
  const displayNameKey = 'youtube_connection.display_name';
  const connectedAtKey = 'youtube_connection.connected_at';
  const validatedAtKey = 'youtube_connection.validated_at';

  final connectedAt = DateTime.utc(2026, 9, 1, 10);
  final validatedAt = DateTime.utc(2026, 9, 1, 11);

  test('saves and restores one versioned validated payload', () async {
    final store = _MemorySecureKeyValueStore({
      accountKey: 'legacy@example.com',
      displayNameKey: 'Legacy',
      connectedAtKey: connectedAt.toIso8601String(),
      validatedAtKey: validatedAt.toIso8601String(),
    });
    final storage = YouTubeAuthSecureStorage(storage: store);
    final connection = YouTubeConnection.connected(
      accountIdentifier: 'listener@example.com',
      displayName: 'Listener',
      connectedAt: connectedAt,
      innerTubeValidatedAt: validatedAt,
    );

    await storage.saveValidatedConnection(connection);

    expect(store.values.keys, [connectionKey]);
    final payload =
        jsonDecode(store.values[connectionKey]!) as Map<String, dynamic>;
    expect(payload['version'], 1);
    expect(payload['accountIdentifier'], 'listener@example.com');
    expect(payload['displayName'], 'Listener');

    final restored = await storage.readValidatedConnection();

    expect(restored?.accountIdentifier, 'listener@example.com');
    expect(restored?.displayName, 'Listener');
    expect(restored?.connectedAt, connectedAt);
    expect(restored?.innerTubeValidatedAt, validatedAt);
    expect(restored?.canContinue, isTrue);
  });

  test(
    'migrates a complete legacy connection to the versioned payload',
    () async {
      final store = _MemorySecureKeyValueStore({
        accountKey: 'legacy@example.com',
        displayNameKey: 'Legacy Listener',
        connectedAtKey: connectedAt.toIso8601String(),
        validatedAtKey: validatedAt.toIso8601String(),
      });
      final storage = YouTubeAuthSecureStorage(storage: store);

      final restored = await storage.readValidatedConnection();

      expect(restored?.accountIdentifier, 'legacy@example.com');
      expect(restored?.displayName, 'Legacy Listener');
      expect(store.values.containsKey(connectionKey), isTrue);
      expect(store.values.containsKey(accountKey), isFalse);
      expect(store.values.containsKey(displayNameKey), isFalse);
      expect(store.values.containsKey(connectedAtKey), isFalse);
      expect(store.values.containsKey(validatedAtKey), isFalse);
    },
  );

  test('corrupted payload fails closed and clears connection data', () async {
    final store = _MemorySecureKeyValueStore({
      connectionKey: '{"version":1,"accountIdentifier":',
      accountKey: 'stale@example.com',
    });
    final storage = YouTubeAuthSecureStorage(storage: store);

    final restored = await storage.readValidatedConnection();

    expect(restored, isNull);
    expect(store.values, isEmpty);
  });

  test('refuses to persist an unvalidated connection', () async {
    final store = _MemorySecureKeyValueStore();
    final storage = YouTubeAuthSecureStorage(storage: store);

    await expectLater(
      storage.saveValidatedConnection(const YouTubeConnection.disconnected()),
      throwsArgumentError,
    );
    expect(store.values, isEmpty);
  });
}

class _MemorySecureKeyValueStore implements SecureKeyValueStore {
  _MemorySecureKeyValueStore([Map<String, String>? initialValues])
    : values = {...?initialValues};

  final Map<String, String> values;

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String? value) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }
}
