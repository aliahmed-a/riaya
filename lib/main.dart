import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riaya/core/utils/storage_service.dart';
import 'app.dart';

void main() async {
  // Ensure native engine bindings are fully settled before boot
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Stand up the secure storage service and preload any saved session
  //    so AuthNotifier can restore it synchronously on first build.
  final storageService = StorageService(const FlutterSecureStorage());
  final initialSession = await storageService.getUserSession();

  runApp(
    // 2. Overriding the providers with the loaded instances
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
        initialSessionProvider.overrideWithValue(initialSession),
      ],
      child: const RiayaApp(),
    ),
  );
}
