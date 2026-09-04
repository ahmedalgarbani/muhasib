import 'dart:async';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

bool _isFactoryInitialized = false;

Future<void> initializeDatabaseFactory() async {
  if (_isFactoryInitialized) return;

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    _isFactoryInitialized = true;
  }
}


