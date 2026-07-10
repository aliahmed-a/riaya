import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riaya/core/utils/storage_service.dart';
import 'app.dart';

void main() async {
  // Ensure native engine bindings are fully settled before boot
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize SharedPreferences asynchronously from disk
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    // 2. Overriding the storageServiceProvider with the loaded instance
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(
          StorageService(sharedPreferences),
        ),
      ],
      child: const RiayaApp(),
    ),
  );
}