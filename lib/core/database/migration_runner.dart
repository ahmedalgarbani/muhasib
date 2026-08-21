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
      print('🔄 Starting database migrations...');
      
      // Get current schema version
      final currentVersion = await _getCurrentVersion();
      print('📊 Current schema version: $currentVersion');

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
      ];

      // Run pending migrations
      for (int i = currentVersion; i < migrations.length; i++) {
        final migrationFile = migrations[i];
        print('⚡ Running migration ${i + 1}/${migrations.length}: $migrationFile');
        
        await _runMigration(migrationFile);
        await _updateVersion(i + 1);
        
        print('✅ Migration ${i + 1} completed successfully');
      }

      print('🎉 All migrations completed! Current version: ${migrations.length}');
    } catch (e) {
      print('❌ Migration failed: $e');
      rethrow;
    }
  }

  /// Get current schema version from database
  Future<int> _getCurrentVersion() async {
    try {
      // Check if schema_version table exists
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='schema_version'"
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
        print('📝 Created schema_version table');
        return 0;
      }

      // Get latest version
      final result = await db.rawQuery(
        'SELECT MAX(version) as version FROM schema_version'
      );

      if (result.isEmpty || result.first['version'] == null) {
        return 0;
      }

      return result.first['version'] as int;
    } catch (e) {
      print('⚠️ Error getting current version: $e');
      return 0;
    }
  }

  /// Run a single migration file
  Future<void> _runMigration(String filename) async {
    try {
      // Load SQL file from assets
      final sql = await rootBundle.loadString(
        'lib/core/database/migrations/$filename'
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
            print('⚠️ Error executing statement: $statement');
            print('Error: $e');
            // Continue with next statement
          }
        }
      }

      print('   Executed $statementCount SQL statements');
    } catch (e) {
      print('❌ Error loading migration file $filename: $e');
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
    print('⚠️ WARNING: Rolling back to version $targetVersion');
    print('⚠️ This may cause data loss!');

    final currentVersion = await _getCurrentVersion();

    if (targetVersion >= currentVersion) {
      print('❌ Cannot rollback to version >= current version');
      return;
    }

    // Delete version records
    await db.delete(
      'schema_version',
      where: 'version > ?',
      whereArgs: [targetVersion],
    );

    print('✅ Rolled back to version $targetVersion');
    print('⚠️ You may need to manually drop tables created by rolled-back migrations');
  }
}
