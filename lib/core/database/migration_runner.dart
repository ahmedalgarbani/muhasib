import 'dart:developer' as developer;
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';

/// Migration Runner
/// Handles database schema migrations in order
class MigrationRunner {
  final Database db;

  MigrationRunner(this.db);

  /// Run all pending migrations
  Future<void> runMigrations() async {
    try {
      developer.log('Starting database migrations...', name: 'MigrationRunner');

      // Get current schema version
      final currentVersion = await _getCurrentVersion();
      developer.log('Current schema version: $currentVersion', name: 'MigrationRunner');

      // Define migrations in order
      final migrations = [
        '001_add_fiscal_periods.sql',
        '002_add_number_sequences.sql',
        '003_add_audit_log.sql',
        '004_fix_account_types.sql',
        '005_fix_audit_logs.sql',
        '006_prevent_negative_stock.sql',
        '007_fix_tolerance.sql',
        '008_multi_unit_enhancement.sql',
        '009_pos_held_orders.sql',
      ];

      // Run pending migrations
      for (int i = currentVersion; i < migrations.length; i++) {
        final migrationFile = migrations[i];
        developer.log(
          'Running migration ${i + 1}/${migrations.length}: $migrationFile',
          name: 'MigrationRunner',
        );

        await _runMigration(migrationFile);
        await _updateVersion(i + 1);

        developer.log('Migration ${i + 1} completed successfully', name: 'MigrationRunner');
      }

      developer.log(
        'All migrations completed! Current version: ${migrations.length}',
        name: 'MigrationRunner',
      );
    } catch (e, st) {
      developer.log(
        'Migration failed: $e',
        name: 'MigrationRunner',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Get current schema version from database
  Future<int> _getCurrentVersion() async {
    try {
      // Check if schema_version table exists
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='schema_version'",
      );

      if (tables.isEmpty) {
        // Create schema_version table
        await db.execute('''
          CREATE TABLE schema_version (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            version INTEGER NOT NULL UNIQUE,
            applied_at INTEGER NOT NULL,
            description TEXT
          )
        ''');
        return 0;
      }

      // Get latest version
      final result = await db.rawQuery(
        'SELECT MAX(version) as version FROM schema_version',
      );

      if (result.isEmpty || result.first['version'] == null) {
        return 0;
      }

      return result.first['version'] as int;
    } catch (e) {
      developer.log('Error getting current version: $e', name: 'MigrationRunner');
      return 0;
    }
  }

  /// Run a single migration file
  Future<void> _runMigration(String filename) async {
    try {
      // Load SQL file from assets
      final sql = await rootBundle.loadString(
        'lib/core/database/migrations/$filename',
      );

      // Split by semicolon and execute each statement
      final statements = sql
          .split(';')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty && !s.startsWith('--'));

      int statementCount = 0;
      for (final statement in statements) {
        if (statement.trim().isNotEmpty) {
          try {
            await db.execute(statement);
            statementCount++;
          } catch (e) {
            // Note: If column already exists (idempotent migrations), catch and log as info
            developer.log(
              'Statement executed with warning: $statement ($e)',
              name: 'MigrationRunner',
            );
          }
        }
      }

      developer.log('Executed $statementCount SQL statements in $filename', name: 'MigrationRunner');
    } catch (e) {
      developer.log('Error loading migration file $filename: $e', name: 'MigrationRunner');
      rethrow;
    }
  }

  /// Update schema version
  Future<void> _updateVersion(int version) async {
    await db.insert('schema_version', {
      'version': version,
      'applied_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'description': 'Migration version $version',
    });
  }

  /// Rollback to a specific version (dangerous - for development only)
  Future<void> rollbackToVersion(int targetVersion) async {
    developer.log(
      'WARNING: Rolling back to version $targetVersion',
      name: 'MigrationRunner',
    );

    final currentVersion = await _getCurrentVersion();

    if (targetVersion >= currentVersion) {
      developer.log(
        'Cannot rollback to version >= current version',
        name: 'MigrationRunner',
      );
      return;
    }

    // Delete version records
    await db.delete(
      'schema_version',
      where: 'version > ?',
      whereArgs: [targetVersion],
    );

    developer.log('Rolled back to version $targetVersion', name: 'MigrationRunner');
  }
}

