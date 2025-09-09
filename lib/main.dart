import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  runApp(const ChatApp());
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ChatListScreen(),
    );
  }
}

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dialogs')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseHelper.instance.getChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No chats available'));
          }
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final chat = snapshot.data![index];
              return ListTile(
                title: Text(chat['name']),
                subtitle: Text(chat['lastMessage'] ?? 'No messages yet'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        chatId: chat['id'],
                        chatName: chat['name'],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final int chatId;
  final String chatName;

  const ChatScreen({super.key, required this.chatId, required this.chatName});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late Future<List<Map<String, dynamic>>> _messagesFuture;

  @override
  void initState() {
    super.initState();
    _messagesFuture = DatabaseHelper.instance.getMessages(widget.chatId);
  }

  void _sendMessage(String text, bool isMine) async {
    await DatabaseHelper.instance.insertMessage(widget.chatId, text, isMine);
    setState(() {
      _messagesFuture = DatabaseHelper.instance.getMessages(widget.chatId);
    });
    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.chatName)),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _messagesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No messages yet'));
                }
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final message = snapshot.data![index];
                    final isMine = message['isMine'] == 1;
                    return Align(
                      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        decoration: BoxDecoration(
                          color: isMine ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          message['text'],
                          style: TextStyle(color: isMine ? Colors.white : Colors.black),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(controller: _controller, decoration: const InputDecoration(hintText: 'Enter message...')),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      _sendMessage(_controller.text, true);
                      Future.delayed(const Duration(seconds: 1), () {
                        _sendMessage('Привет от собеседника!', false);
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('chat_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE chats (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          lastMessage TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE messages (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          chatId INTEGER NOT NULL,
          text TEXT NOT NULL,
          isMine INTEGER NOT NULL,
          FOREIGN KEY (chatId) REFERENCES chats (id) ON DELETE CASCADE
        )
      ''');
      await db.insert('chats', {'name': 'Alice', 'lastMessage': ''});
      await db.insert('chats', {'name': 'Bob', 'lastMessage': ''});
      await db.insert('chats', {'name': 'Charlie', 'lastMessage': ''});
    });
  }

  Future<List<Map<String, dynamic>>> getChats() async {
    final db = await database;
    return await db.query('chats', orderBy: 'id DESC');
  }

  Future<List<Map<String, dynamic>>> getMessages(int chatId) async {
    final db = await database;
    return await db.query('messages', where: 'chatId = ?', whereArgs: [chatId]);
  }

  Future<void> insertMessage(int chatId, String text, bool isMine) async {
    final db = await database;
    await db.insert('messages', {'chatId': chatId, 'text': text, 'isMine': isMine ? 1 : 0});
  }
}

//ffd