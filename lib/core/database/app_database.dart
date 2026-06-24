import 'package:path/path.dart' as path_package;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._([this._databasePath, this._databaseFactory]);

  static final AppDatabase instance = AppDatabase._();

  static const String databaseFileName = 'ordem_fichas.db';

  final String? _databasePath;
  final DatabaseFactory? _databaseFactory;
  Database? _database;

  factory AppDatabase.forTest({
    required String databasePath,
    required DatabaseFactory databaseFactory,
  }) {
    return AppDatabase._(databasePath, databaseFactory);
  }

  Future<Database> get database async {
    final Database? existingDatabase = _database;

    if (existingDatabase != null) {
      return existingDatabase;
    }

    final Database openedDatabase = await _openDatabase();
    _database = openedDatabase;

    return openedDatabase;
  }

  Future<Database> _openDatabase() async {
    final String databasePath = _databasePath ?? await _defaultDatabasePath();
    final DatabaseFactory selectedDatabaseFactory =
        _databaseFactory ?? _defaultDatabaseFactory();

    return selectedDatabaseFactory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (Database database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (Database database, int databaseVersion) async {
          await _createSchema(database);
        },
      ),
    );
  }

  Future<String> _defaultDatabasePath() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();

    return path_package.join(documentsDirectory.path, databaseFileName);
  }

  DatabaseFactory _defaultDatabaseFactory() {
    return databaseFactory;
  }

  Future<void> close() async {
    final Database? existingDatabase = _database;

    if (existingDatabase == null) {
      return;
    }

    await existingDatabase.close();
    _database = null;
  }

  Future<void> _createSchema(Database database) async {
    await database.execute('''
      CREATE TABLE characters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        character_name TEXT NOT NULL,
        player_name TEXT NOT NULL,
        origin TEXT NOT NULL,
        class_name TEXT NOT NULL,
        path_name TEXT NOT NULL,
        rank_name TEXT NOT NULL,
        exposure_level INTEGER NOT NULL DEFAULT 0,
        movement INTEGER NOT NULL DEFAULT 9,
        base_life INTEGER NOT NULL DEFAULT 16,
        life_per_vigor INTEGER NOT NULL DEFAULT 4,
        life_manual_bonus INTEGER NOT NULL DEFAULT 0,
        life_current INTEGER NOT NULL DEFAULT 0,
        life_maximum INTEGER NOT NULL DEFAULT 0,
        use_manual_life_maximum INTEGER NOT NULL DEFAULT 0,
        base_sanity INTEGER NOT NULL DEFAULT 12,
        sanity_per_presence INTEGER NOT NULL DEFAULT 2,
        sanity_manual_bonus INTEGER NOT NULL DEFAULT 0,
        sanity_current INTEGER NOT NULL DEFAULT 0,
        sanity_maximum INTEGER NOT NULL DEFAULT 0,
        use_manual_sanity_maximum INTEGER NOT NULL DEFAULT 0,
        base_effort INTEGER NOT NULL DEFAULT 2,
        effort_per_presence INTEGER NOT NULL DEFAULT 1,
        effort_manual_bonus INTEGER NOT NULL DEFAULT 0,
        effort_current INTEGER NOT NULL DEFAULT 0,
        effort_maximum INTEGER NOT NULL DEFAULT 0,
        use_manual_effort_maximum INTEGER NOT NULL DEFAULT 0,
        base_defense INTEGER NOT NULL DEFAULT 10,
        defense_manual_bonus INTEGER NOT NULL DEFAULT 0,
        defense INTEGER NOT NULL DEFAULT 10,
        use_manual_defense INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await database.execute('''
      CREATE TABLE character_attributes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        character_id INTEGER NOT NULL UNIQUE,
        strength INTEGER NOT NULL DEFAULT 1,
        agility INTEGER NOT NULL DEFAULT 1,
        intellect INTEGER NOT NULL DEFAULT 1,
        presence INTEGER NOT NULL DEFAULT 1,
        vigor INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (character_id)
          REFERENCES characters (id)
          ON DELETE CASCADE
      )
    ''');

    await database.execute('''
      CREATE TABLE character_skills (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        character_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        training INTEGER NOT NULL DEFAULT 0,
        bonus INTEGER NOT NULL DEFAULT 0,
        notes TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (character_id)
          REFERENCES characters (id)
          ON DELETE CASCADE
      )
    ''');

    await database.execute('''
      CREATE TABLE character_weapons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        character_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        attack_bonus INTEGER NOT NULL DEFAULT 0,
        damage TEXT NOT NULL DEFAULT '',
        critical_text TEXT NOT NULL DEFAULT '',
        range_text TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (character_id)
          REFERENCES characters (id)
          ON DELETE CASCADE
      )
    ''');

    await database.execute('''
      CREATE TABLE character_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        character_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'Item',
        quantity INTEGER NOT NULL DEFAULT 1,
        weight INTEGER NOT NULL DEFAULT 0,
        defense_bonus INTEGER NOT NULL DEFAULT 0,
        notes TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (character_id)
          REFERENCES characters (id)
          ON DELETE CASCADE
      )
    ''');

    await database.execute('''
      CREATE TABLE character_rituals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        character_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        circle TEXT NOT NULL DEFAULT '',
        cost TEXT NOT NULL DEFAULT '',
        description TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (character_id)
          REFERENCES characters (id)
          ON DELETE CASCADE
      )
    ''');

    await database.execute('''
      CREATE TABLE character_powers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        character_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'Poder',
        description TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (character_id)
          REFERENCES characters (id)
          ON DELETE CASCADE
      )
    ''');

    await database.execute('''
      CREATE TABLE character_notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        character_id INTEGER NOT NULL,
        category TEXT NOT NULL DEFAULT 'Anotações',
        title TEXT NOT NULL DEFAULT '',
        content TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (character_id)
          REFERENCES characters (id)
          ON DELETE CASCADE
      )
    ''');

    await database.execute(
      'CREATE INDEX idx_characters_name ON characters(character_name)',
    );
    await database.execute(
      'CREATE INDEX idx_character_skills_owner ON character_skills(character_id)',
    );
    await database.execute(
      'CREATE INDEX idx_character_items_owner ON character_items(character_id)',
    );
  }
}
