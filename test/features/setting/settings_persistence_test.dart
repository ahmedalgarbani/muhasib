import 'package:flutter_test/flutter_test.dart';
import 'package:muhasib/core/database/database_initializer.dart';
import 'package:muhasib/core/services/database_service.dart';
import 'package:muhasib/features/setting/data/repositories/settings_repository.dart';
import 'package:muhasib/features/setting/presentation/cubit/settings_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Settings persistence', () {
    late DatabaseService databaseService;
    late SettingsRepository repository;

    setUpAll(() async {
      await initializeDatabaseFactory();
      databaseService = DatabaseService();
      final db = await databaseService.database;
      repository = SettingsRepository(database: db);
    });

    tearDownAll(() async {
      await databaseService.close();
    });

    test('partial section update keeps untouched keys', () async {
      final before = await repository.getSetting('other_setting');
      final originalLanguage = before is Map ? before['language'] : null;

      await repository.updateSetting('other_setting', {'language': 'en'});
      final other = await repository.getSetting('other_setting');
      expect(other, isA<Map>());
      expect(other['language'], 'en');
      expect(other.containsKey('dateFormat'), isTrue);
      expect(other.containsKey('fontScale'), isTrue);

      if (originalLanguage != null) {
        await repository.updateSetting('other_setting', {
          'language': originalLanguage,
        });
      }
    });

    test('updateSetting creates a key missing from the table', () async {
      final key = 'runtime_test_setting_${DateTime.now().microsecondsSinceEpoch}';
      expect(await repository.getSetting(key), isNull);

      await repository.updateSetting(key, {'enabled': true, 'limit': 5});

      final stored = await repository.getSetting(key);
      expect(stored, isA<Map>());
      expect(stored['enabled'], true);
      expect(stored['limit'], 5);
    });

    test('updateMultipleSettings upserts every key', () async {
      await repository.updateMultipleSettings({
        'runtime_test_a': {'value': 1},
        'runtime_test_b': {'value': 2},
      });
      expect((await repository.getSetting('runtime_test_a'))['value'], 1);
      expect((await repository.getSetting('runtime_test_b'))['value'], 2);
    });

    test('cubit merges partial updates into its in-memory snapshot', () async {
      final cubit = SettingsCubit(repository: repository);
      await cubit.loadSettings();

      final fontSizeBefore = cubit.getOtherSettings()['fontScale'];
      await cubit.updateSetting('other_setting', {'language': 'ar'});

      final other = cubit.getOtherSettings();
      expect(other['language'], 'ar');
      expect(other.containsKey('fontScale'), isTrue);
      expect(other['fontScale'], fontSizeBefore);
    });
  });
}
