// lib/db/message_database.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/message.dart';

class MessageDatabase {
  static final MessageDatabase instance = MessageDatabase._init();

  static Database? _database;

  MessageDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'messages.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );

    return _database!;
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE messages (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      senderId TEXT NOT NULL,
      recipientId TEXT NOT NULL,
      content TEXT NOT NULL,
      sentAt TEXT NOT NULL,
      readAt TEXT
    )
    ''');
  }

  Future<List<Message>> getAllMessages() async {
    final db = await instance.database;
    final result = await db.query('messages', orderBy: 'sentAt ASC');
    return result.map((json) => Message.fromMap(json)).toList();
  }

  Future<int> insertMessage(Message msg) async {
    final db = await instance.database;
    return await db.insert('messages', msg.toMap());
  }

  Future<int> markMessageAsRead(int id, DateTime readAt) async {
    final db = await instance.database;
    return await db.update(
      'messages',
      {'readAt': readAt.toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteExpiredMessages() async {
    final db = await instance.database;
    final cutoff = DateTime.now().subtract(const Duration(hours: 24)).toIso8601String();

    return await db.delete(
      'messages',
      where: 'readAt IS NOT NULL AND readAt <= ?',
      whereArgs: [cutoff],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
