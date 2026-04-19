import 'package:fegh_chat/fegh_chat.dart';
import 'package:flutter/material.dart';

/// Team-Chat-Einstieg der Verwaltung.
///
/// Haelt den [MatrixChatService] ueber die Screen-Lebenszeit und
/// uebergibt ihn dem [ChatListScreen] aus `fegh_chat`. Die
/// Verwaltung nutzt denselben Conduit-Homeserver wie die Doku-App,
/// aber eine eigene lokale Datenbank (`fegh_verwaltung_matrix`),
/// damit Admin- und Feld-Session nebeneinander laufen koennen.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final MatrixChatService _service;

  @override
  void initState() {
    super.initState();
    _service = MatrixChatService(
      appName: 'FEGH-Verwaltung',
      databaseName: 'fegh_verwaltung_matrix',
    );
    _service.initialize();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChatListScreen(chatService: _service);
  }
}
