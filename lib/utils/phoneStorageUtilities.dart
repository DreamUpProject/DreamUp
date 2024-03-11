import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class MessageStorage {
  late String chatId;

  late String messageId;
  late DateTime createdOn;
  late String creatorId;
  late bool myMessage;
  late String type;
  late String content;

  MessageStorage({
    required this.chatId,
    required this.messageId,
    required this.createdOn,
    required this.creatorId,
    required this.myMessage,
    required this.type,
    required this.content,
  });

  MessageStorage.fromJson(Map<String, dynamic> json) {
    messageId = json['messageId'];
    createdOn = json['createdOn'];
    creatorId = json['creatorId'];
    myMessage = json['myMessage'];
    type = json['type'];
    content = json['content'];
  }

  Future<String> get appDirectory async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get file async {
    final path = await appDirectory;

    return File('$path/chats/$chatId/$messageId');
  }

  void saveFileOnPhone(File file, MessageStorage message) {
    file.writeAsStringSync(jsonEncode(message));
  }
}
