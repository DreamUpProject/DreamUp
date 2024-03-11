import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:friendivity/additionalPages/userProfile.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:sticky_grouped_list/sticky_grouped_list.dart';
import 'package:swipe_image_gallery/swipe_image_gallery.dart';

import '../main.dart';

Map? chatData = {};
String currentChatId = '';
bool keyBoardOpen = false;

class ChatObject {
  late String id;
  late String lastMessage;
  late String lastSender;
  late DateTime lastTime;
  late String lastType;

  static List<Message> Messages = [];

  ChatObject({
    required this.id,
    required this.lastMessage,
    required this.lastSender,
    required this.lastTime,
    required this.lastType,
  });

  ChatObject.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    lastMessage = json['lastMessage'];
    lastSender = json['lastSender'];
    lastTime = json['lastTime'] is String
        ? DateTime.parse(json['lastTime'])
        : (json['lastTime'] as Timestamp).toDate();
    lastType = json['lastType'];
  }

  Map<String, dynamic> toJson() {
    return {
      'chatId': id,
      'lastMessage': lastMessage,
      'lastSender': lastSender,
      'lastTime': lastTime.toString(),
      'lastType': lastType,
    };
  }

  Future<String> get appDirectory async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  //tool to control the JSON size on device
  getFileSize(String filepath, int decimals) async {
    var file = File(filepath);
    int bytes = await file.length();
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  Future saveMessages(String chatId) async {
    final path = await appDirectory;

    bool existing = await File('$path/chats/$chatId/messageFile').exists();

    if (existing) {
      var file = File('$path/chats/$chatId/messageFile');

      String json = jsonEncode(Messages);

      file.writeAsStringSync(json);
    } else {
      File file =
          await File('$path/chats/$chatId/messageFile').create(recursive: true);

      String json = jsonEncode(Messages);

      file.writeAsStringSync(json);
    }

    print('messages saved');
  }

  Future getMessagesFromJson(String chatId) async {
    final path = await appDirectory;

    bool existing = await File('$path/chats/$chatId/messageFile').exists();

    if (existing) {
      print('existing');

      var file = File('$path/chats/$chatId/messageFile');

      var json = await file.readAsString();

      var decoded = jsonDecode(json);

      print('entries on file: ${decoded.length}');

      for (Map<String, dynamic> entry in decoded) {
        var message = Message.fromJson(entry);

        print(message.content);

        var duplicate = Messages.firstWhereOrNull(
            (element) => element.messageId == message.messageId);

        if (duplicate == null) {
          Messages.add(message);
        }
      }

      print('messages on list: ${ChatObject.Messages.length}');
    } else {
      print('not existing');

      var messages = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('createdOn', descending: false)
          .get();

      for (var doc in messages.docs) {
        var data = doc.data();

        var message = Message.fromJson(data);

        Messages.add(message);
      }

      await saveMessages(chatId);

      print('messages saved');
    }
  }
}

class Message {
  late String messageId;
  late String creatorId;
  late DateTime createdOn;
  late String type;
  late String content;
  late bool myMessage;
  late String? imageSubText;
  late bool? passedOn;
  late int? audioDuration;
  late bool? decided;

  Message({
    required this.messageId,
    required this.creatorId,
    required this.createdOn,
    required this.type,
    required this.content,
    required this.myMessage,
    this.imageSubText,
    this.passedOn,
    this.audioDuration,
    this.decided,
  });

  Message.fromJson(Map<String, dynamic> json) {
    messageId = json['messageId'];
    creatorId = json['creatorId'];
    createdOn = json['createdOn'] is String
        ? DateTime.parse(json['createdOn'])
        : (json['createdOn'] as Timestamp).toDate();
    type = json['type'];
    content = json['content'];
    myMessage = json['creatorId'] == FirebaseAuth.instance.currentUser?.uid;
    imageSubText = json['imageSubText'];
    passedOn = json['passedOn'] ?? false;
    audioDuration = json['audioDuration'] ?? 0;
    decided = json['decided'] ?? false;
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'creatorId': creatorId,
      'createdOn': createdOn.toString(),
      'type': type,
      'content': content,
      'myMessage': myMessage,
      'imageSubText': imageSubText ?? '',
      'passedOn': passedOn ?? false,
      'audioDuration': audioDuration ?? 0,
      'decided': decided ?? false,
    };
  }

  Future<String> get appDirectory async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  getFileSize(String filepath, int decimals) async {
    var file = File(filepath);
    int bytes = await file.length();
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  void saveFileOnPhone(String chatId, Message message, File? mediaFile) async {
    final path = await appDirectory;

    File file = await File('$path/chats/$chatId/messages/$messageId')
        .create(recursive: true);

    String json = jsonEncode(message.toJson());

    file.writeAsStringSync(json);

    if (message.type != 'text') {
      saveMediaOnPhone(chatId, messageId, mediaFile!);
    }
  }

  void saveMediaOnPhone(String chatId, String messageId, File file) async {
    final path = await appDirectory;

    await File('$path/chats/$chatId/messages/$messageId')
        .create(recursive: true);

    await file.copy('$path/chats/$chatId/media/$messageId');
  }
}

class MessagePage extends StatefulWidget {
  final String chatId;
  final String partnerName;
  final String partnerId;

  const MessagePage({
    Key? key,
    required this.chatId,
    required this.partnerName,
    required this.partnerId,
  }) : super(key: key);

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final currentUser = FirebaseAuth.instance.currentUser?.uid;

  var chat = FirebaseFirestore.instance.collection('chats');

  File? imageFile;

  Map<String, dynamic> userData = {};

  Widget dateSeparator(Message message) {
    return SizedBox(
      height: 50,
      child: Align(
        alignment: Alignment.center,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.7),
            borderRadius: const BorderRadius.all(
              Radius.circular(
                10.0,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              dateString(message),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black.withOpacity(0.7),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String dateString(Message message) {
    String dateString = '';

    if (message.createdOn.day == DateTime.now().day &&
        message.createdOn.month == DateTime.now().month &&
        message.createdOn.year == DateTime.now().year) {
      dateString = 'Heute';
    } else if (message.createdOn.day == DateTime.now().day - 1 &&
        message.createdOn.month == DateTime.now().month &&
        message.createdOn.year == DateTime.now().year) {
      dateString = 'Gestern';
    } else {
      dateString =
          '${message.createdOn.day}.${message.createdOn.month}.${message.createdOn.year}';
    }

    return dateString;
  }

  late TextEditingController imageSubTextController;

  bool sending = false;

  Future<String> get appDirectory async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future saveImageOnPhone(File image, String messageId) async {
    final path = await appDirectory;

    await File('$path/chats/${widget.chatId}/images/$messageId')
        .create(recursive: true);

    await image.copy('$path/chats/${widget.chatId}/images/$messageId');
  }

  void sendImageMessage() async {
    if (!sending) {
      sending = true;

      setState(() {});

      final FirebaseStorage storage = FirebaseStorage.instance;

      var messageRef = chat.doc(widget.chatId).collection('messages').doc();

      var id = messageRef.id;

      String imageLink = '';

      DateTime now = DateTime.now();

      await saveImageOnPhone(imageFile!, id);

      var messageObject = Message(
        content: imageLink,
        creatorId: currentUser!,
        type: 'image',
        messageId: id,
        myMessage: true,
        createdOn: now,
        passedOn: false,
        imageSubText: imageSubTextController.text,
      );

      ChatObject.Messages.add(messageObject);

      var currentFile = imageFile!;

      imageFile = null;

      setState(() {});

      try {
        await storage.ref('chatMedia/${widget.chatId}/images/$id').putFile(
              currentFile,
            );

        imageLink = await FirebaseStorage.instance
            .ref('chatMedia/${widget.chatId}/images/$id')
            .getDownloadURL();
      } on FirebaseException catch (e) {
        print(e);
      }

      var thisMessage =
          ChatObject.Messages.lastWhere((element) => element.messageId == id);

      thisMessage.content = imageLink;

      await ChatObject(
              id: '',
              lastMessage: '',
              lastSender: '',
              lastTime: DateTime.now(),
              lastType: '')
          .saveMessages(widget.chatId);

      setState(() {});

      Map<String, dynamic> chatJson = {};

      await messageRef.set({
        'messageId': id,
        'createdOn': now,
        'creatorId': currentUser,
        'type': 'image',
        'content': imageLink,
        'imageSubText': imageSubTextController.text,
      });

      var onlineUsers = chatData?['onlineUsers'] as List<dynamic>;

      if (!onlineUsers.contains(widget.partnerId)) {
        chatJson.addAll({
          'new': true,
        });

        var notificationDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(userData['id'])
            .collection('messageNotifications')
            .doc();

        var note = {
          'time': now,
          'new': true,
          'chatId': widget.chatId,
        };

        await notificationDoc.set(note);
      }

      sending = false;

      imageSubTextController.text = '';

      setState(() {});

      chatJson.addAll({
        'lastAction': DateTime.now(),
        'lastSender': currentUser,
        'lastMessage': imageLink,
        'lastType': 'image',
      });

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update(chatJson);
    }
  }

  bool manageModeOn = false;
  List<Message> managedMessages = [];

  bool showLandscape = false;

  static List<Message> imageMessages = [];

  bool containsForeignMessage() {
    bool contains = false;

    for (var message in managedMessages) {
      if (message.creatorId != currentUser!) {
        contains = true;

        break;
      }
    }

    return contains;
  }

  bool loaded = false;

  final scrollController = GroupedItemScrollController();

  Stream<QuerySnapshot>? messageStream;

  bool scrolled = false;

  Future changeOnlineStatus(bool online) async {
    if (online) {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'onlineUsers': FieldValue.arrayUnion([currentUser]),
      });
    } else {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'onlineUsers': FieldValue.arrayRemove([currentUser]),
        'lastLogin.$currentUser': DateTime.now(),
      });
    }
  }

  GlobalKey messageInputKey = GlobalKey();

  bool showAll = true;
  bool showName = true;
  bool showImage = true;
  bool showBio = true;
  bool showDreamUps = true;

  //called when coming first into screen after being accepted
  Future confirmShownInfoFirstTime() async {
    var chat =
        FirebaseFirestore.instance.collection('chats').doc(widget.chatId);

    var infoMap = {
      'name': showName,
      'image': showImage,
      'bio': showBio,
      'dreamUps': showDreamUps,
    };

    var info = chatData!['shownInformation'] as Map;
    var partnerInfo = info[widget.partnerId];

    await chat.update(
      {
        'shownInformation': {
          widget.partnerId: partnerInfo,
          currentUser: infoMap,
        },
      },
    );

    Navigator.pop(context);
  }

  bool shownSheet = false;

  @override
  void initState() {
    super.initState();

    currentChatId = widget.chatId;

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);

    ChatObject.Messages.clear();

    imageSubTextController = TextEditingController()
      ..addListener(() {
        setState(() {});
      });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ChatObject(
              id: 'id',
              lastMessage: 'lastMessage',
              lastSender: 'lastSender',
              lastTime: DateTime.now(),
              lastType: 'lastType')
          .getMessagesFromJson(widget.chatId);

      print(ChatObject.Messages.last.type);

      var last = ChatObject.Messages.last.createdOn;

      messageStream = FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .where('creatorId', isEqualTo: widget.partnerId)
          .orderBy('createdOn', descending: false)
          .startAfter([Timestamp.fromDate(last)]).snapshots();

      setState(() {
        loaded = true;
      });
    });
  }

  @override
  void dispose() {
    changeOnlineStatus(false);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    ChatObject.Messages.clear();

    imageSubTextController.dispose();

    keyBoardOpen = false;

    currentChatId = '';

    chatData = null;

    imageMessages.clear();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      showLandscape = false;
    } else {
      showLandscape = true;
    }

    return Scaffold(
      resizeToAvoidBottomInset: imageFile != null,
      body: Stack(
        children: [
          loaded
              ? StreamBuilder<QuerySnapshot>(
                  stream: messageStream!,
                  builder: (BuildContext context, snapshot) {
                    if (snapshot.hasData) {
                      var docs = snapshot.data!.docs;

                      if (docs.isNotEmpty) {
                        for (var doc in docs) {
                          var data = doc.data() as Map<String, dynamic>;

                          var message = Message.fromJson(data);

                          var existing = ChatObject.Messages.firstWhereOrNull(
                              (element) =>
                                  element.messageId == message.messageId);

                          if (existing == null) {
                            ChatObject.Messages.add(message);

                            Future.delayed(
                              Duration.zero,
                              () async {
                                setState(() {});

                                await ChatObject(
                                        id: 'id',
                                        lastMessage: 'lastMessage',
                                        lastSender: 'lastSender',
                                        lastTime: DateTime.now(),
                                        lastType: 'lastType')
                                    .saveMessages(widget.chatId);
                              },
                            );
                          }
                        }
                      }
                    }

                    return Container();
                  },
                )
              : Container(),
          loaded
              ? StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chats')
                      .doc(widget.chatId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      var data = snapshot.data!.data() as Map<String, dynamic>;
                      chatData = data;

                      if (data['new'] && data['lastSender'] != currentUser) {
                        FirebaseFirestore.instance
                            .collection('chats')
                            .doc(widget.chatId)
                            .update(
                          {
                            'new': false,
                          },
                        );
                      }

                      String name = 'Nutzer';
                      String image =
                          'https://firebasestorage.googleapis.com/v0/b/activities-with-friends.appspot.com/o/placeholderImages%2FuserPlaceholder.png?alt=media&token=1a4e6423-446d-48b5-8bbf-466900c350ec&_gl=1*1g9i9yi*_ga*ODE3ODU3OTY4LjE2OTI2OTU2NzA.*_ga_CW55HF8NVT*MTY5ODkxNDQwMS4yMy4xLjE2OTg5MTUyNzEuNTkuMC4w';

                      if (!data['isRequest']) {
                        var info = data['shownInformation'] as Map;

                        if (!info.containsKey(currentUser) && !shownSheet) {
                          Future.delayed(Duration.zero, () {
                            shownSheet = true;

                            showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                isDismissible: false,
                                isScrollControlled: true,
                                enableDrag: false,
                                builder: (context) {
                                  return StatefulBuilder(builder:
                                      (context, StateSetter setSheetState) {
                                    return Container(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.6,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(
                                            MediaQuery.of(context).size.width *
                                                0.05,
                                          ),
                                          topRight: Radius.circular(
                                            MediaQuery.of(context).size.width *
                                                0.05,
                                          ),
                                        ),
                                      ),
                                      padding: EdgeInsets.only(
                                        top: MediaQuery.of(context).size.width *
                                            0.1,
                                        left:
                                            MediaQuery.of(context).size.width *
                                                0.05,
                                        right:
                                            MediaQuery.of(context).size.width *
                                                0.05,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Welche Informationen möchtest du preisgeben?',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 20,
                                            ),
                                          ),
                                          SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.05,
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              setSheetState(() {
                                                if (showAll) {
                                                  showName = false;
                                                  showImage = false;
                                                  showBio = false;
                                                  showDreamUps = false;
                                                } else {
                                                  showName = true;
                                                  showImage = true;
                                                  showBio = true;
                                                  showDreamUps = true;
                                                }
                                              });
                                            },
                                            child: Row(
                                              children: [
                                                Checkbox(
                                                  value: showName &&
                                                      showImage &&
                                                      showBio &&
                                                      showDreamUps,
                                                  onChanged: (value) {
                                                    setSheetState(() {
                                                      showAll = value!;
                                                      showName = value;
                                                      showImage = value;
                                                      showBio = value;
                                                      showDreamUps = value;
                                                    });
                                                  },
                                                ),
                                                const Text(
                                                  'Alles zeigen',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Center(
                                            child: Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.9,
                                              height: 1,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              setSheetState(() {
                                                showName = !showName;
                                              });
                                            },
                                            child: Row(
                                              children: [
                                                Checkbox(
                                                  value: showName,
                                                  onChanged: (value) {
                                                    setSheetState(() {
                                                      showName = value!;
                                                    });
                                                  },
                                                ),
                                                const Text(
                                                  'Namen zeigen',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              setSheetState(() {
                                                showImage = !showImage;
                                              });
                                            },
                                            child: Row(
                                              children: [
                                                Checkbox(
                                                  value: showImage,
                                                  onChanged: (value) {
                                                    setSheetState(() {
                                                      showImage = value!;
                                                    });
                                                  },
                                                ),
                                                const Text(
                                                  'Bild zeigen',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              setSheetState(() {
                                                showBio = !showBio;
                                              });
                                            },
                                            child: Row(
                                              children: [
                                                Checkbox(
                                                  value: showBio,
                                                  onChanged: (value) {
                                                    setSheetState(() {
                                                      showBio = value!;
                                                    });
                                                  },
                                                ),
                                                const Text(
                                                  'Profiletext zeigen',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              setSheetState(() {
                                                showDreamUps = !showDreamUps;
                                              });
                                            },
                                            child: Row(
                                              children: [
                                                Checkbox(
                                                  value: showDreamUps,
                                                  onChanged: (value) {
                                                    setSheetState(() {
                                                      showDreamUps = value!;
                                                    });
                                                  },
                                                ),
                                                const Text(
                                                  'DreamUps zeigen',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Center(
                                              child: GestureDetector(
                                                onTap: () async {
                                                  confirmShownInfoFirstTime();
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    vertical: 8,
                                                    horizontal: 10,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blueAccent,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            300),
                                                  ),
                                                  child: const Text(
                                                    'Bestätigen',
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  });
                                });
                          });
                        }

                        if (info.containsKey(widget.partnerId) &&
                            info.containsKey(currentUser)) {
                          var partnerInfo = info[widget.partnerId] as Map;

                          bool nameUnlocked = partnerInfo['name'] == true;
                          bool imageUnlocked = partnerInfo['image'] == true;

                          var names = data['names'] as List<dynamic>;
                          names.remove(CurrentUser.name);
                          var partnerName = names.first;

                          if (nameUnlocked) {
                            name = partnerName;
                          }

                          var images = data['images'] as Map;
                          var imageUrl = images[widget.partnerId];

                          if (imageUnlocked) {
                            image = imageUrl;
                          }
                        }
                      }

                      return Scaffold(
                        backgroundColor: Colors.transparent,
                        resizeToAvoidBottomInset: true,
                        body: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.asset(
                                'assets/images/GlassBackground.jpg',
                                fit: BoxFit.fill,
                              ),
                            ),
                            Column(
                              children: [
                                Container(
                                  padding: EdgeInsets.only(
                                    top: MediaQuery.of(context).padding.top,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE3E3E3),
                                    boxShadow: [
                                      BoxShadow(
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                        color: Colors.black26,
                                        offset: Offset(2, 0),
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    height: 45,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: showLandscape
                                          ? max(
                                              MediaQuery.of(context)
                                                  .padding
                                                  .left,
                                              MediaQuery.of(context)
                                                  .padding
                                                  .right)
                                          : 0,
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        FocusManager.instance.primaryFocus
                                            ?.unfocus();

                                        Navigator.push(
                                          context,
                                          changePage(
                                            UserProfile(
                                              chatId: widget.chatId,
                                              partnerId: widget.partnerId,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        color: Colors.transparent,
                                        child: Row(
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.pop(context, true);
                                              },
                                              child: Container(
                                                color: Colors.transparent,
                                                height: 45,
                                                width: 45,
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.arrow_back_ios_new,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            CircleAvatar(
                                              backgroundImage:
                                                  CachedNetworkImageProvider(
                                                image,
                                              ),
                                              backgroundColor:
                                                  Colors.transparent,
                                              radius: 18,
                                            ),
                                            SizedBox(
                                              width: min(
                                                MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.03,
                                                MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.03,
                                              ),
                                            ),
                                            Expanded(
                                              child: SizedBox(
                                                height: 20,
                                                child: Text(
                                                  name,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: min(
                                                MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.05,
                                                MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.05,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: loaded
                                      ? Stack(
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                FocusManager
                                                    .instance.primaryFocus
                                                    ?.unfocus();

                                                keyBoardOpen = false;

                                                setState(() {});
                                              },
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: showLandscape
                                                      ? max(
                                                          MediaQuery.of(context)
                                                              .padding
                                                              .left,
                                                          MediaQuery.of(context)
                                                              .padding
                                                              .right)
                                                      : 0,
                                                ),
                                                child: NotificationListener<
                                                    ScrollNotification>(
                                                  onNotification: (note) {
                                                    if (note
                                                        is ScrollUpdateNotification) {
                                                      if (scrolled == false &&
                                                          !note
                                                              .metrics.atEdge) {
                                                        setState(() {
                                                          scrolled = true;
                                                        });
                                                      }

                                                      if (scrolled == true &&
                                                          note.metrics.atEdge) {
                                                        setState(() {
                                                          scrolled = false;
                                                        });
                                                      }

                                                      if (note.dragDetails !=
                                                          null) {
                                                        RenderBox box = messageInputKey
                                                                .currentContext
                                                                ?.findRenderObject()
                                                            as RenderBox;
                                                        Offset position = box
                                                            .localToGlobal(Offset
                                                                .zero); //this is global position
                                                        double y =
                                                            position.dy; //

                                                        if (note
                                                                .dragDetails!
                                                                .globalPosition
                                                                .dy >=
                                                            y) {
                                                          FocusManager.instance
                                                              .primaryFocus
                                                              ?.unfocus();
                                                        }
                                                      }
                                                    }

                                                    return true;
                                                  },
                                                  child: StickyGroupedListView<
                                                      Message, DateTime>(
                                                    key: Key(
                                                      ChatObject.Messages.length
                                                          .toString(),
                                                    ),
                                                    addAutomaticKeepAlives:
                                                        true,
                                                    itemScrollController:
                                                        scrollController,
                                                    padding: EdgeInsets.only(
                                                      bottom: min(
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.03,
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            0.03,
                                                      ),
                                                    ),
                                                    physics:
                                                        const BouncingScrollPhysics(),
                                                    reverse: true,
                                                    elements:
                                                        ChatObject.Messages,
                                                    order:
                                                        StickyGroupedListOrder
                                                            .ASC,
                                                    groupBy:
                                                        (Message message) =>
                                                            DateTime(
                                                      message.createdOn.year,
                                                      message.createdOn.month,
                                                      message.createdOn.day,
                                                    ),
                                                    groupComparator: (DateTime
                                                                value1,
                                                            DateTime value2) =>
                                                        value2
                                                            .compareTo(value1),
                                                    itemComparator: (Message
                                                                message1,
                                                            Message message2) =>
                                                        message2.createdOn
                                                            .compareTo(message1
                                                                .createdOn),
                                                    floatingHeader: true,
                                                    groupSeparatorBuilder:
                                                        dateSeparator,
                                                    indexedItemBuilder:
                                                        (BuildContext context,
                                                            Message message,
                                                            int index) {
                                                      bool single = true;
                                                      bool first = false;
                                                      bool last = false;

                                                      Message? previousMessage;
                                                      Message? nextMessage;

                                                      bool previousExisting =
                                                          false;
                                                      bool nextExisting = false;

                                                      if (index > 0) {
                                                        nextMessage =
                                                            ChatObject.Messages[
                                                                index - 1];
                                                        nextExisting = true;
                                                      }

                                                      if (index + 1 <
                                                          ChatObject.Messages
                                                              .length) {
                                                        previousMessage =
                                                            ChatObject.Messages[
                                                                index + 1];
                                                        previousExisting = true;
                                                      }

                                                      if (!previousExisting) {
                                                        first = true;
                                                      }

                                                      if (!nextExisting) {
                                                        last = true;
                                                      }

                                                      DateTime thisTime =
                                                          DateTime(
                                                        message.createdOn.year,
                                                        message.createdOn.month,
                                                        message.createdOn.day,
                                                        message.createdOn.hour,
                                                        message
                                                            .createdOn.minute,
                                                      );

                                                      DateTime? previousTime;
                                                      DateTime? nextTime;

                                                      if (previousExisting) {
                                                        previousTime = DateTime(
                                                          previousMessage!
                                                              .createdOn.year,
                                                          previousMessage
                                                              .createdOn.month,
                                                          previousMessage
                                                              .createdOn.day,
                                                          previousMessage
                                                              .createdOn.hour,
                                                          previousMessage
                                                              .createdOn.minute,
                                                        );
                                                      }

                                                      if (nextExisting) {
                                                        nextTime = DateTime(
                                                          nextMessage!
                                                              .createdOn.year,
                                                          nextMessage
                                                              .createdOn.month,
                                                          nextMessage
                                                              .createdOn.day,
                                                          nextMessage
                                                              .createdOn.hour,
                                                          nextMessage
                                                              .createdOn.minute,
                                                        );
                                                      }

                                                      if ((thisTime !=
                                                                  previousTime &&
                                                              thisTime !=
                                                                  nextTime) ||
                                                          (previousMessage
                                                                      ?.creatorId !=
                                                                  message
                                                                      .creatorId &&
                                                              nextMessage
                                                                      ?.creatorId !=
                                                                  message
                                                                      .creatorId)) {
                                                        single = true;
                                                      } else {
                                                        single = false;

                                                        if (thisTime ==
                                                                previousTime &&
                                                            thisTime !=
                                                                nextTime) {
                                                          last = true;
                                                        }
                                                        if (thisTime ==
                                                                nextTime &&
                                                            thisTime !=
                                                                previousTime) {
                                                          first = true;
                                                        }
                                                      }

                                                      bool onList() {
                                                        bool existing = false;

                                                        for (var messageOnList
                                                            in managedMessages) {
                                                          if (messageOnList
                                                                  .messageId ==
                                                              message
                                                                  .messageId) {
                                                            existing = true;

                                                            break;
                                                          }
                                                        }

                                                        return existing;
                                                      }

                                                      if (message.type ==
                                                          'image') {
                                                        var existing = imageMessages
                                                            .firstWhereOrNull(
                                                                (element) =>
                                                                    element
                                                                        .messageId ==
                                                                    message
                                                                        .messageId);

                                                        if (existing == null) {
                                                          imageMessages
                                                              .add(message);
                                                        }
                                                      }

                                                      return MessageWidget(
                                                        interactWithMessage:
                                                            (toggledOn) {
                                                          if (toggledOn) {
                                                            managedMessages
                                                                .add(message);

                                                            if (managedMessages
                                                                .isNotEmpty) {
                                                              manageModeOn =
                                                                  true;
                                                            }

                                                            setState(() {});
                                                          } else {
                                                            var thisMessage =
                                                                managedMessages.firstWhere(
                                                                    (element) =>
                                                                        element
                                                                            .messageId ==
                                                                        message
                                                                            .messageId);

                                                            managedMessages
                                                                .remove(
                                                                    thisMessage);

                                                            if (managedMessages
                                                                .isEmpty) {
                                                              manageModeOn =
                                                                  false;
                                                            }

                                                            setState(() {});
                                                          }
                                                        },
                                                        manageModeOn:
                                                            manageModeOn,
                                                        onList: onList(),
                                                        imageMessages:
                                                            imageMessages,
                                                        messageId:
                                                            message.messageId,
                                                        chatId: widget.chatId,
                                                        userName:
                                                            widget.partnerName,
                                                        single: single,
                                                        first: first,
                                                        last: last,
                                                        message: message,
                                                        scrollController:
                                                            scrollController,
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              right: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.05,
                                              bottom: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.05,
                                              child: AnimatedOpacity(
                                                duration: const Duration(
                                                  milliseconds: 250,
                                                ),
                                                opacity: scrolled ? 1 : 0,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    if (scrolled) {
                                                      scrollController.scrollTo(
                                                        index: 0,
                                                        duration:
                                                            const Duration(
                                                          milliseconds: 250,
                                                        ),
                                                        automaticAlignment:
                                                            false,
                                                        alignment: 1,
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.1,
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.1,
                                                    decoration:
                                                        const BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: Colors.white,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          blurRadius: 7,
                                                          spreadRadius: 1,
                                                          offset: Offset(
                                                            1,
                                                            1,
                                                          ),
                                                          color: Colors.black38,
                                                        ),
                                                      ],
                                                    ),
                                                    child: Center(
                                                      child: Icon(
                                                        Icons
                                                            .arrow_drop_down_rounded,
                                                        size: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width *
                                                            0.1,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : Container(),
                                ),
                                const SizedBox(
                                  height: 50,
                                ),
                                SizedBox(
                                  height: MediaQuery.of(context).padding.bottom,
                                ),
                              ],
                            ),
                            AnimatedPositioned(
                              duration: const Duration(
                                milliseconds: 200,
                              ),
                              bottom: chatData!['isRequest']
                                  ? -(MediaQuery.of(context).padding.bottom +
                                      50)
                                  : 0,
                              left: 0,
                              right: 0,
                              child: MessageInputWidget(
                                key: messageInputKey,
                                sendingCallback: () {
                                  setState(() {});
                                },
                                onImageSelection: (image, view) {
                                  setState(() {
                                    imageFile = image;
                                  });
                                },
                                chatId: widget.chatId,
                                chatPartnerData: userData,
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return Scaffold(
                        backgroundColor: Colors.transparent,
                        resizeToAvoidBottomInset: true,
                        body: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.asset(
                                'assets/images/GlassBackground.jpg',
                                fit: BoxFit.fill,
                              ),
                            ),
                            Column(
                              children: [
                                Container(
                                  padding: EdgeInsets.only(
                                    top: MediaQuery.of(context).padding.top,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE3E3E3),
                                    boxShadow: [
                                      BoxShadow(
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                        color: Colors.black26,
                                        offset: Offset(2, 0),
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    height: 55,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: showLandscape
                                          ? max(
                                              MediaQuery.of(context)
                                                  .padding
                                                  .left,
                                              MediaQuery.of(context)
                                                  .padding
                                                  .right)
                                          : 0,
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        FocusManager.instance.primaryFocus
                                            ?.unfocus();

                                        Navigator.push(
                                          context,
                                          changePage(
                                            UserProfile(
                                              chatId: widget.chatId,
                                              partnerId: widget.partnerId,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        color: Colors.transparent,
                                        child: Row(
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.pop(context, true);
                                              },
                                              child: Container(
                                                color: Colors.transparent,
                                                height: showLandscape
                                                    ? min(
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.12,
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            0.12,
                                                      )
                                                    : min(
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.15,
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            0.15,
                                                      ),
                                                width: showLandscape
                                                    ? min(
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.12,
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            0.12,
                                                      )
                                                    : min(
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.15,
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            0.15,
                                                      ),
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.arrow_back_ios_new,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            CircleAvatar(
                                              backgroundImage: Image.asset(
                                                'assets/uiComponents/profilePicturePlaceholder.jpg',
                                              ).image,
                                              backgroundColor:
                                                  Colors.transparent,
                                              radius: 20,
                                            ),
                                            SizedBox(
                                              width: min(
                                                MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.03,
                                                MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.03,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                widget.partnerName,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: min(
                                                MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.05,
                                                MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.05,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(),
                                ),
                                const SizedBox(
                                  height: 50,
                                ),
                                SizedBox(
                                  height: MediaQuery.of(context).padding.bottom,
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }
                  },
                )
              : Container(),
          Positioned.fill(
            child: Visibility(
              visible: imageFile != null,
              child: Container(
                color: Colors.black,
                child: Stack(
                  children: [
                    Center(
                      child: imageFile != null
                          ? Image.file(
                              imageFile!,
                            )
                          : Container(),
                    ),
                    Positioned(
                      top: MediaQuery.of(context).padding.top +
                          min(
                            MediaQuery.of(context).size.width * 0.02,
                            MediaQuery.of(context).size.height * 0.02,
                          ),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: Row(
                          children: [
                            SizedBox(
                              width: min(
                                MediaQuery.of(context).size.width * 0.02,
                                MediaQuery.of(context).size.height * 0.02,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                imageFile = null;

                                setState(() {});
                              },
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: MediaQuery.of(context).size.width * 0.1,
                              ),
                            ),
                            Expanded(
                              child: Container(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: MediaQuery.of(context).padding.bottom +
                          min(
                            MediaQuery.of(context).size.width * 0.02,
                            MediaQuery.of(context).size.height * 0.02,
                          ),
                      right: min(
                        MediaQuery.of(context).size.width * 0.02,
                        MediaQuery.of(context).size.height * 0.02,
                      ),
                      left: min(
                        MediaQuery.of(context).size.width * 0.02,
                        MediaQuery.of(context).size.height * 0.02,
                      ),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: showLandscape
                              ? max(
                                  MediaQuery.of(context).padding.left,
                                  MediaQuery.of(context).padding.right,
                                )
                              : 0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Container(
                                margin: EdgeInsets.all(
                                  min(
                                    MediaQuery.of(context).size.width * 0.02,
                                    MediaQuery.of(context).size.height * 0.02,
                                  ),
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: min(
                                    MediaQuery.of(context).size.width * 0.01,
                                    MediaQuery.of(context).size.height * 0.01,
                                  ),
                                  horizontal: min(
                                    MediaQuery.of(context).size.width * 0.03,
                                    MediaQuery.of(context).size.height * 0.03,
                                  ),
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    min(
                                      MediaQuery.of(context).size.width * 0.05,
                                      MediaQuery.of(context).size.height * 0.05,
                                    ),
                                  ),
                                  border: Border.all(
                                    color: Colors.black45,
                                    width: 1.5,
                                  ),
                                ),
                                child: TextField(
                                  controller: imageSubTextController,
                                  minLines: 1,
                                  maxLines: showLandscape ? 2 : 7,
                                  enableSuggestions: true,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  autocorrect: true,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    hintText: 'Bildunterschrift',
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                sendImageMessage();
                              },
                              child: Container(
                                margin: EdgeInsets.only(
                                  bottom: min(
                                    MediaQuery.of(context).size.width * 0.02,
                                    MediaQuery.of(context).size.height * 0.02,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: min(
                                    MediaQuery.of(context).size.width * 0.05,
                                    MediaQuery.of(context).size.height * 0.05,
                                  ),
                                  backgroundColor: Colors.white,
                                  child: const Icon(
                                    Icons.send_rounded,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MessageInputWidget extends StatefulWidget {
  final void Function() sendingCallback;
  final void Function(File? imageFile, bool viewImage) onImageSelection;
  final String chatId;
  final Map<String, dynamic> chatPartnerData;

  const MessageInputWidget({
    Key? key,
    required this.sendingCallback,
    required this.onImageSelection,
    required this.chatId,
    required this.chatPartnerData,
  }) : super(key: key);

  @override
  State<MessageInputWidget> createState() => _MessageInputWidgetState();
}

class _MessageInputWidgetState extends State<MessageInputWidget>
    with WidgetsBindingObserver {
  final currentUser = FirebaseAuth.instance.currentUser?.uid;
  final chat = FirebaseFirestore.instance.collection('chats');

  bool sending = false;

  void sendTextMessage(String message) async {
    if (!sending) {
      sending = true;

      setState(() {});

      if (message == '') return;

      DateTime now = DateTime.now();

      var messageDoc = chat.doc(widget.chatId).collection('messages').doc();

      var messageObject = Message(
        content: message.trim(),
        creatorId: currentUser!,
        type: 'text',
        messageId: messageDoc.id,
        myMessage: true,
        createdOn: now,
        passedOn: false,
      );

      ChatObject.Messages.add(messageObject);

      setState(() {});

      await ChatObject(
              id: '',
              lastMessage: '',
              lastSender: '',
              lastTime: DateTime.now(),
              lastType: '')
          .saveMessages(widget.chatId);

      await messageDoc.set({
        'messageId': messageDoc.id,
        'createdOn': now,
        'creatorId': currentUser,
        'type': 'text',
        'content': message.trim(),
      }).then((value) {
        sendController.text = '';
      });

      Map<String, dynamic> chatJson = {};

      var onlineUsers = chatData?['onlineUsers'] as List<dynamic>;

      if (!onlineUsers.contains(widget.chatPartnerData['id'])) {
        chatJson.addAll({'new': true});

        var notificationDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(widget.chatPartnerData['id'])
            .collection('messageNotifications')
            .doc();

        var note = {
          'time': now,
          'new': true,
          'chatId': widget.chatId,
        };

        await notificationDoc.set(note);
      }

      sending = false;

      setState(() {});

      widget.sendingCallback();

      chatJson.addAll({
        'lastAction': DateTime.now(),
        'lastSender': currentUser,
        'lastMessage': message.trim(),
        'lastType': 'text',
      });

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update(chatJson);
    }
  }

  Future<String> get appDirectory async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  File? imageFile;

  Future getImage(bool fromGallery) async {
    if (fromGallery) {
      if (Platform.isIOS) {
        var status = await Permission.photos.status;

        if (status == PermissionStatus.granted) {
          Navigator.pop(context);

          final pickedImage = await ImagePicker().pickImage(
            source: ImageSource.gallery,
          );

          if (pickedImage == null) return;

          imageFile = File(pickedImage.path);
        }
      } else {
        var status = await Permission.storage.status;

        if (status == PermissionStatus.granted) {
          Navigator.pop(context);

          final pickedImage = await ImagePicker().pickImage(
            source: ImageSource.gallery,
          );

          if (pickedImage == null) return;

          imageFile = File(pickedImage.path);
        }
      }
    } else {
      var status = await Permission.camera.status;

      if (status == PermissionStatus.granted) {
        Navigator.pop(context);

        final pickedImage = await ImagePicker().pickImage(
          source: ImageSource.camera,
        );

        if (pickedImage == null) return;

        imageFile = File(pickedImage.path);
      }
    }
  }

  Widget PermissionDialog(String theme) {
    return Dialog(
      child: Container(
        padding: EdgeInsets.all(
          MediaQuery.of(context).size.width * 0.05,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bitte gewähre uns Zugriff auf deine $theme, um ein Bild zu senden.',
              style: const TextStyle(
                fontSize: 20,
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.width * 0.05,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 7,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.blue,
                        width: 1,
                      ),
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'Schließen',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    inSettings = true;

                    theme == 'Kamera' ? withCamera = true : withCamera = false;

                    await openAppSettings();

                    if (theme == 'Kamera') {
                      var permission = await Permission.camera.status;

                      if (permission == PermissionStatus.granted) {
                        final pickedImage = await ImagePicker().pickImage(
                          source: ImageSource.camera,
                        );

                        if (pickedImage == null) return;

                        imageFile = File(pickedImage.path);

                        Navigator.pop(context);

                        setState(() {});
                      }
                    } else {
                      if (Platform.isIOS) {
                        var permission = await Permission.photos.status;

                        if (permission == PermissionStatus.granted) {
                          final pickedImage = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                          );

                          if (pickedImage == null) return;

                          imageFile = File(pickedImage.path);

                          Navigator.pop(context);

                          setState(() {});
                        }
                      } else {
                        var permission = await Permission.storage.status;

                        if (permission == PermissionStatus.granted) {
                          final pickedImage = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                          );

                          if (pickedImage == null) return;

                          imageFile = File(pickedImage.path);

                          Navigator.pop(context);

                          setState(() {});
                        }
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 7,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.blue,
                        width: 1,
                      ),
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'Einstellungen öffnen',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future pickImage(bool fromGallery) async {
    if (!fromGallery) {
      var status = await Permission.camera.status;

      if (status != PermissionStatus.granted) {
        var asked = await Permission.camera.request();

        if (asked != PermissionStatus.granted) {
          showDialog(
            context: context,
            builder: (context) => PermissionDialog('Kamera'),
          );
        }
      } else {
        final pickedImage = await ImagePicker().pickImage(
          source: ImageSource.camera,
        );

        if (pickedImage == null) return;

        imageFile = File(pickedImage.path);
      }
    } else {
      if (Platform.isIOS) {
        var status = await Permission.photos.status;

        if (status != PermissionStatus.granted) {
          var asked = await Permission.photos.request();

          if (asked != PermissionStatus.granted) {
            showDialog(
              context: context,
              builder: (context) => PermissionDialog('Galerie'),
            );
          }
        } else {
          final pickedImage = await ImagePicker().pickImage(
            source: ImageSource.gallery,
          );

          if (pickedImage == null) return;

          imageFile = File(pickedImage.path);
        }
      } else if (Platform.isAndroid) {
        var status = await Permission.storage.status;

        if (status != PermissionStatus.granted) {
          var asked = await Permission.storage.request();

          if (asked != PermissionStatus.granted) {
            showDialog(
              context: context,
              builder: (context) => PermissionDialog('Gallerie'),
            );
          }
        } else {
          final pickedImage = await ImagePicker().pickImage(
            source: ImageSource.gallery,
          );

          if (pickedImage == null) return;

          imageFile = File(pickedImage.path);
        }
      }
    }

    setState(() {});
  }

  //not functional yet
  bool sendVoice = false;
  bool recording = false;
  int recordDuration = 0;
  Timer? timer;
  final audioRecorder = Record();
  StreamSubscription<RecordState>? recordSubscription;
  RecordState recordState = RecordState.stop;
  String audioPath = '';

  File? audioFile;

  void startTimer() {
    timer?.cancel();

    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) async {
      setState(() => recordDuration++);
    });
  }

  String formatTime(int number) {
    String time = number.toString();
    if (number < 10) {
      time = '0$time';
    }

    return time;
  }

  double right = 0;
  double rightStart = 0;
  double bottom = 0;
  double bottomStart = 0;

  bool recordVoice = false;

  bool locked = false;

  bool showLandscape = false;

  late TextEditingController sendController;

  bool inSettings = false;
  bool withCamera = false;

  bool showAll = true;
  bool showName = true;
  bool showImage = true;
  bool showBio = true;
  bool showDreamUps = true;

  Future confirmShownInfo() async {
    var chat =
        FirebaseFirestore.instance.collection('chats').doc(widget.chatId);

    var infoMap = {
      'name': showName,
      'image': showImage,
      'bio': showBio,
      'dreamUps': showDreamUps,
    };

    await chat.update({
      'shownInformation.$currentUser': infoMap,
    });

    Navigator.pop(context);

    Fluttertoast.showToast(
      msg: 'updated shown information!',
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    sendController = TextEditingController();

    sendController.addListener(() {
      setState(() {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.landscapeRight,
          DeviceOrientation.landscapeLeft,
        ]);
      });
    });

    recordSubscription = audioRecorder.onStateChanged().listen((recordState) {
      setState(() {
        recordState = recordState;

        if (recordState == RecordState.record) {
          recording = true;
        } else {
          recording = false;
        }
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (inSettings) {
        inSettings = false;

        getImage(!withCamera);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    sendController.dispose();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      showLandscape = false;
    } else {
      showLandscape = true;
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFE3E3E3),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            spreadRadius: 1,
            color: Colors.black26,
            offset: Offset(-2, 0),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: showLandscape
            ? max(MediaQuery.of(context).padding.left,
                MediaQuery.of(context).padding.right)
            : 0,
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Container(
                  margin: EdgeInsets.fromLTRB(
                    min(
                      MediaQuery.of(context).size.width * 0.02,
                      MediaQuery.of(context).size.height * 0.02,
                    ),
                    min(
                      MediaQuery.of(context).size.width * 0.02,
                      MediaQuery.of(context).size.height * 0.02,
                    ),
                    0,
                    min(
                      MediaQuery.of(context).size.width * 0.02,
                      MediaQuery.of(context).size.height * 0.02,
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: min(
                      MediaQuery.of(context).size.width * 0.03,
                      MediaQuery.of(context).size.height * 0.03,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      min(
                        MediaQuery.of(context).size.width * 0.05,
                        MediaQuery.of(context).size.height * 0.05,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: sendController,
                          readOnly: keyBoardOpen ? false : true,
                          autofocus: keyBoardOpen ? true : false,
                          minLines: 1,
                          maxLines: showLandscape ? 2 : 7,
                          onTap: () {
                            keyBoardOpen = true;

                            setState(() {});
                          },
                          enableSuggestions: true,
                          textCapitalization: TextCapitalization.sentences,
                          autocorrect: true,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            hintText: 'Nachricht',
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          FocusManager.instance.primaryFocus?.unfocus();

                          showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (context) {
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD0D0D0),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Center(
                                            child: GestureDetector(
                                              onTap: () async {
                                                await pickImage(false);

                                                if (imageFile != null) {
                                                  Navigator.pop(context);
                                                }

                                                widget.onImageSelection(
                                                    imageFile, true);
                                              },
                                              child: Container(
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.15,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 15,
                                                ),
                                                color: Colors.transparent,
                                                child: const Row(
                                                  children: [
                                                    Icon(
                                                      Icons.camera_alt_outlined,
                                                      size: 30,
                                                      color: Colors.blueAccent,
                                                    ),
                                                    SizedBox(
                                                      width: 10,
                                                    ),
                                                    Text(
                                                      'Kamera',
                                                      style: TextStyle(
                                                        fontSize: 20,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width -
                                                10,
                                            height: 1,
                                            color: Colors.white,
                                          ),
                                          Center(
                                            child: GestureDetector(
                                              onTap: () async {
                                                await pickImage(true);

                                                if (imageFile != null) {
                                                  Navigator.pop(context);
                                                }

                                                widget.onImageSelection(
                                                    imageFile, true);
                                              },
                                              child: Container(
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.15,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 15,
                                                ),
                                                color: Colors.transparent,
                                                child: const Row(
                                                  children: [
                                                    Icon(
                                                      Icons.image_outlined,
                                                      size: 30,
                                                      color: Colors.blueAccent,
                                                    ),
                                                    SizedBox(
                                                      width: 10,
                                                    ),
                                                    Text(
                                                      'Galerie',
                                                      style: TextStyle(
                                                        fontSize: 20,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.pop(context);
                                      },
                                      child: Container(
                                        height:
                                            MediaQuery.of(context).size.width *
                                                0.15,
                                        margin: const EdgeInsets.all(
                                          10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            'Abbrechen',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blueAccent,
                                              fontSize: 22,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              });
                        },
                        child: Container(
                          color: Colors.transparent,
                          child: Transform.rotate(
                            angle: 45 * pi / 180,
                            child: const Icon(
                              Icons.attach_file_rounded,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              sendController.text.isEmpty
                  ? GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (context) {
                              return StatefulBuilder(builder:
                                  (context, StateSetter setSheetState) {
                                return Container(
                                  height:
                                      MediaQuery.of(context).size.height * 0.6,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(
                                        MediaQuery.of(context).size.width *
                                            0.05,
                                      ),
                                      topRight: Radius.circular(
                                        MediaQuery.of(context).size.width *
                                            0.05,
                                      ),
                                    ),
                                  ),
                                  padding: EdgeInsets.only(
                                    top:
                                        MediaQuery.of(context).size.width * 0.1,
                                    left: MediaQuery.of(context).size.width *
                                        0.05,
                                    right: MediaQuery.of(context).size.width *
                                        0.05,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Welche Informationen möchtest du preisgeben?',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 20,
                                        ),
                                      ),
                                      SizedBox(
                                        height:
                                            MediaQuery.of(context).size.width *
                                                0.05,
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          setSheetState(() {
                                            if (showAll) {
                                              showName = false;
                                              showImage = false;
                                              showBio = false;
                                              showDreamUps = false;
                                            } else {
                                              showName = true;
                                              showImage = true;
                                              showBio = true;
                                              showDreamUps = true;
                                            }
                                          });
                                        },
                                        child: Row(
                                          children: [
                                            Checkbox(
                                              value: showName &&
                                                  showImage &&
                                                  showBio &&
                                                  showDreamUps,
                                              onChanged: (value) {
                                                setSheetState(() {
                                                  showAll = value!;
                                                  showName = value;
                                                  showImage = value;
                                                  showBio = value;
                                                  showDreamUps = value;
                                                });
                                              },
                                            ),
                                            const Text(
                                              'Alles zeigen',
                                              style: TextStyle(
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Center(
                                        child: Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.9,
                                          height: 1,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          setSheetState(() {
                                            showName = !showName;
                                          });
                                        },
                                        child: Row(
                                          children: [
                                            Checkbox(
                                              value: showName,
                                              onChanged: (value) {
                                                setSheetState(() {
                                                  showName = value!;
                                                });
                                              },
                                            ),
                                            const Text(
                                              'Namen zeigen',
                                              style: TextStyle(
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          setSheetState(() {
                                            showImage = !showImage;
                                          });
                                        },
                                        child: Row(
                                          children: [
                                            Checkbox(
                                              value: showImage,
                                              onChanged: (value) {
                                                setSheetState(() {
                                                  showImage = value!;
                                                });
                                              },
                                            ),
                                            const Text(
                                              'Bild zeigen',
                                              style: TextStyle(
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          setSheetState(() {
                                            showBio = !showBio;
                                          });
                                        },
                                        child: Row(
                                          children: [
                                            Checkbox(
                                              value: showBio,
                                              onChanged: (value) {
                                                setSheetState(() {
                                                  showBio = value!;
                                                });
                                              },
                                            ),
                                            const Text(
                                              'Profiletext zeigen',
                                              style: TextStyle(
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          setSheetState(() {
                                            showDreamUps = !showDreamUps;
                                          });
                                        },
                                        child: Row(
                                          children: [
                                            Checkbox(
                                              value: showDreamUps,
                                              onChanged: (value) {
                                                setSheetState(() {
                                                  showDreamUps = value!;
                                                });
                                              },
                                            ),
                                            const Text(
                                              'DreamUps zeigen',
                                              style: TextStyle(
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Center(
                                          child: GestureDetector(
                                            onTap: () async {
                                              await confirmShownInfo();
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 8,
                                                horizontal: 10,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.blueAccent,
                                                borderRadius:
                                                    BorderRadius.circular(300),
                                              ),
                                              child: const Text(
                                                'Bestätigen',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              });
                            });
                      },
                      child: Container(
                        color: Colors.transparent,
                        height: 50,
                        width: 50,
                        child: const Center(
                          child: Icon(
                            Icons.question_mark_rounded,
                          ),
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: () async {
                        sendTextMessage(sendController.text);
                      },
                      child: Container(
                        color: Colors.transparent,
                        height: 50,
                        width: 50,
                        child: const Icon(
                          Icons.send_rounded,
                        ),
                      ),
                    ),
            ],
          ),
          SizedBox(
            height: MediaQuery.of(context).padding.bottom,
          ),
        ],
      ),
    );
  }
}

class MessageWidget extends StatefulWidget {
  final void Function(bool toggledOn) interactWithMessage;
  final GroupedItemScrollController scrollController;
  final String messageId;
  final String chatId;
  final bool manageModeOn;
  final bool onList;
  final bool single;
  final bool first;
  final bool last;
  final List<Message> imageMessages;
  final Message message;
  final String userName;

  const MessageWidget({
    Key? key,
    required this.interactWithMessage,
    required this.scrollController,
    required this.messageId,
    required this.chatId,
    required this.manageModeOn,
    required this.onList,
    required this.single,
    required this.first,
    required this.last,
    required this.imageMessages,
    required this.message,
    required this.userName,
  }) : super(key: key);

  @override
  State<MessageWidget> createState() => _MessageWidgetState();
}

class _MessageWidgetState extends State<MessageWidget>
    with AutomaticKeepAliveClientMixin {
  String messageTime(DateTime time) {
    String messageTime = '';

    String hour = time.hour.toString();
    String minute =
        time.minute < 10 ? '0${time.minute}' : time.minute.toString();

    messageTime = '$hour:$minute';

    return messageTime;
  }

  Future<String> get appDirectory async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  File? imageFile;
  File? audioFile;

  Future getImageFile() async {
    final path = await appDirectory;

    var imagePath = '$path/chats/${widget.chatId}/images/${widget.messageId}';

    bool existing = await File(imagePath).exists();

    if (existing) {
      imageFile = File(imagePath);
    } else {
      await Dio().download(
        widget.message.content,
        imagePath,
      );

      imageFile = File(imagePath);
    }
  }

  String? path;

  bool toggled = false;

  Color systemMessageColor = const Color(0xFF6EAFCA);
  Color myMessageColor = const Color(0xFF84BC8D);
  Color partnerMessageColor = const Color(0xFFECE5DD);

  String currentUser = FirebaseAuth.instance.currentUser!.uid;

  bool showAll = true;
  bool showName = true;
  bool showImage = true;
  bool showBio = true;
  bool showDreamUps = true;

  //called when receiving the first chat request
  Future confirmShownInfoFirstTime(String messageId) async {
    var chat =
        FirebaseFirestore.instance.collection('chats').doc(widget.chatId);

    var infoMap = {
      'name': showName,
      'image': showImage,
      'bio': showBio,
      'dreamUps': showDreamUps,
    };

    await chat.update({
      'shownInformation': {
        currentUser: infoMap,
      },
      'isRequest': false,
      'lastSender': currentUser,
      'new': true,
      'lastAction': DateTime.now(),
      'participants': FieldValue.arrayUnion([chatData!['lastSender']]),
    });

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc(messageId)
        .delete();

    Navigator.pop(context);
  }

  void acceptChatRequest() async {
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isDismissible: false,
        enableDrag: false,
        isScrollControlled: true,
        builder: (context) {
          return StatefulBuilder(builder: (context, StateSetter setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(
                    MediaQuery.of(context).size.width * 0.05,
                  ),
                  topRight: Radius.circular(
                    MediaQuery.of(context).size.width * 0.05,
                  ),
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.width * 0.1,
                left: MediaQuery.of(context).size.width * 0.05,
                right: MediaQuery.of(context).size.width * 0.05,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text(
                    'Welche Informationen möchtest du preisgeben?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.width * 0.05,
                  ),
                  GestureDetector(
                    onTap: () {
                      setSheetState(() {
                        if (showAll) {
                          showName = false;
                          showImage = false;
                          showBio = false;
                          showDreamUps = false;
                        } else {
                          showName = true;
                          showImage = true;
                          showBio = true;
                          showDreamUps = true;
                        }
                      });
                    },
                    child: Row(
                      children: [
                        Checkbox(
                          value:
                              showName && showImage && showBio && showDreamUps,
                          onChanged: (value) {
                            setSheetState(() {
                              showAll = value!;
                              showName = value;
                              showImage = value;
                              showBio = value;
                              showDreamUps = value;
                            });
                          },
                        ),
                        const Text(
                          'Alles zeigen',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.9,
                      height: 1,
                      color: Colors.black54,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setSheetState(() {
                        showName = !showName;
                      });
                    },
                    child: Row(
                      children: [
                        Checkbox(
                          value: showName,
                          onChanged: (value) {
                            setSheetState(() {
                              showName = value!;
                            });
                          },
                        ),
                        const Text(
                          'Namen zeigen',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setSheetState(() {
                        showImage = !showImage;
                      });
                    },
                    child: Row(
                      children: [
                        Checkbox(
                          value: showImage,
                          onChanged: (value) {
                            setSheetState(() {
                              showImage = value!;
                            });
                          },
                        ),
                        const Text(
                          'Bild zeigen',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setSheetState(() {
                        showBio = !showBio;
                      });
                    },
                    child: Row(
                      children: [
                        Checkbox(
                          value: showBio,
                          onChanged: (value) {
                            setSheetState(() {
                              showBio = value!;
                            });
                          },
                        ),
                        const Text(
                          'Profiletext zeigen',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setSheetState(() {
                        showDreamUps = !showDreamUps;
                      });
                    },
                    child: Row(
                      children: [
                        Checkbox(
                          value: showDreamUps,
                          onChanged: (value) {
                            setSheetState(() {
                              showDreamUps = value!;
                            });
                          },
                        ),
                        const Text(
                          'DreamUps zeigen',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: GestureDetector(
                        onTap: () async {
                          await confirmShownInfoFirstTime(widget.messageId);

                          Message? systemMessage =
                              ChatObject.Messages.firstWhereOrNull(
                                  (element) => element.type == 'system');

                          systemMessage?.decided = true;

                          ChatObject.Messages.remove(systemMessage);

                          await ChatObject(
                            id: '',
                            lastMessage: '',
                            lastSender: '',
                            lastTime: DateTime.now(),
                            lastType: '',
                          ).saveMessages(widget.chatId);

                          setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(300),
                          ),
                          child: const Text(
                            'Bestätigen',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          });
        });
  }

  void declineChatRequest() async {
    Navigator.pop(context, true);

    var docs = await FirebaseFirestore.instance
        .collection('users')
        .doc(chatData!['lastSender'])
        .collection('requestedCreators')
        .where('userId', isEqualTo: currentUser)
        .get();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(chatData!['lastSender'])
        .collection('requestedCreators')
        .doc(docs.docs.first.id)
        .delete();

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(currentChatId)
        .delete();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.message.type == 'image') {
        await getImageFile();

        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.message.type == 'system') {
      return Visibility(
        visible: !widget.message.decided!,
        child: GestureDetector(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();

            keyBoardOpen = false;

            setState(() {});
          },
          child: Container(
            width: min(
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height,
            ),
            color: toggled
                ? Colors.blueAccent.withOpacity(0.3)
                : Colors.transparent,
            margin: EdgeInsets.only(
              top: min(
                MediaQuery.of(context).size.width * 0.1,
                MediaQuery.of(context).size.height * 0.1,
              ),
              bottom: min(
                MediaQuery.of(context).size.width * 0.1,
                MediaQuery.of(context).size.height * 0.1,
              ),
            ),
            child: Align(
              alignment: Alignment.center,
              child: Container(
                margin: EdgeInsets.only(
                  left: min(
                    MediaQuery.of(context).size.width * 0.1,
                    MediaQuery.of(context).size.height * 0.1,
                  ),
                  right: min(
                    MediaQuery.of(context).size.width * 0.1,
                    MediaQuery.of(context).size.height * 0.1,
                  ),
                ),
                width: min(
                  MediaQuery.of(context).size.width * 0.8,
                  MediaQuery.of(context).size.height * 0.8,
                ),
                decoration: BoxDecoration(
                  color: systemMessageColor.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    top: min(
                      MediaQuery.of(context).size.width * 0.05,
                      MediaQuery.of(context).size.height * 0.05,
                    ),
                    left: min(
                      MediaQuery.of(context).size.width * 0.03,
                      MediaQuery.of(context).size.height * 0.03,
                    ),
                    right: min(
                      MediaQuery.of(context).size.width * 0.03,
                      MediaQuery.of(context).size.height * 0.03,
                    ),
                    bottom: min(
                      MediaQuery.of(context).size.width * 0.05,
                      MediaQuery.of(context).size.height * 0.05,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Center(
                        child: Text(
                          'Möchtest du die Chatanfrage annehmen?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.8),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          'Achtung! Wenn du die Anfrage dieses Nutzers ablehnst, werden dir künftig keine weiteren DreamUps dieses Nutzers angezeigt.\nDies kann nicht rückgängig gemacht werden!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.redAccent.withOpacity(0.8),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: min(
                          MediaQuery.of(context).size.width * 0.05,
                          MediaQuery.of(context).size.height * 0.05,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                acceptChatRequest();
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: min(
                                    MediaQuery.of(context).size.width * 0.02,
                                    MediaQuery.of(context).size.height * 0.02,
                                  ),
                                  horizontal: min(
                                    MediaQuery.of(context).size.width * 0.03,
                                    MediaQuery.of(context).size.height * 0.03,
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Annehmen',
                                    style: TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: min(
                              MediaQuery.of(context).size.width * 0.05,
                              MediaQuery.of(context).size.height * 0.05,
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                declineChatRequest();
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: min(
                                    MediaQuery.of(context).size.width * 0.02,
                                    MediaQuery.of(context).size.height * 0.02,
                                  ),
                                  horizontal: min(
                                    MediaQuery.of(context).size.width * 0.03,
                                    MediaQuery.of(context).size.height * 0.03,
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Ablehnen',
                                    style: TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } else if (widget.message.creatorId == currentUser) {
      if (widget.message.type == 'image') {
        bool hasSubText = widget.message.imageSubText != null &&
            widget.message.imageSubText != '';

        return GestureDetector(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();

            keyBoardOpen = false;

            setState(() {});

            if (widget.manageModeOn) {
              if (toggled) {
                toggled = false;

                widget.interactWithMessage(false);
              } else {
                toggled = true;

                widget.interactWithMessage(true);
              }

              setState(() {});
            }
          },
          child: Container(
            width: min(
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height,
            ),
            color: toggled
                ? Colors.blueAccent.withOpacity(0.3)
                : Colors.transparent,
            margin: EdgeInsets.only(
              top: widget.single || widget.first
                  ? min(
                      MediaQuery.of(context).size.width * 0.03,
                      MediaQuery.of(context).size.height * 0.03,
                    )
                  : min(
                      MediaQuery.of(context).size.width * 0.01,
                      MediaQuery.of(context).size.height * 0.01,
                    ),
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                margin: EdgeInsets.only(
                  right: min(
                    MediaQuery.of(context).size.width * 0.05,
                    MediaQuery.of(context).size.height * 0.05,
                  ),
                ),
                width: min(
                  MediaQuery.of(context).size.width * 0.8,
                  MediaQuery.of(context).size.height * 0.8,
                ),
                decoration: BoxDecoration(
                  color: myMessageColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: !widget.single && !widget.first
                        ? const Radius.circular(5)
                        : const Radius.circular(20),
                    bottomRight: !widget.single && !widget.last
                        ? const Radius.circular(5)
                        : const Radius.circular(20),
                    bottomLeft: const Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        var path = await appDirectory;

                        List<Message> ImageMessages = [];

                        for (var message in ChatObject.Messages) {
                          if (message.type == 'image') {
                            ImageMessages.add(message);
                          }
                        }

                        var reverseList = ImageMessages.reversed.toList();

                        var index = reverseList.indexOf(widget.message);

                        FocusManager.instance.primaryFocus?.unfocus();

                        await SwipeImageGallery(
                          context: context,
                          itemBuilder: (context, ind) {
                            var message = reverseList[ind];

                            var messageFile = File(
                                '$path/chats/$currentChatId/images/${message.messageId}');

                            return Stack(
                              children: [
                                Positioned.fill(
                                  child: Image.file(
                                    messageFile,
                                  ),
                                ),
                              ],
                            );
                          },
                          itemCount: reverseList.length,
                          initialIndex: index,
                          dismissDragDistance: 10,
                          transitionDuration: 250,
                          hideStatusBar: false,
                        ).show();
                      },
                      child: imageFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(20),
                                topRight: !widget.single && !widget.first
                                    ? const Radius.circular(5)
                                    : const Radius.circular(20),
                                bottomRight: hasSubText
                                    ? Radius.zero
                                    : !widget.single && !widget.last
                                        ? const Radius.circular(5)
                                        : const Radius.circular(20),
                                bottomLeft: hasSubText
                                    ? Radius.zero
                                    : const Radius.circular(20),
                              ),
                              child: Stack(
                                children: [
                                  Hero(
                                    tag: widget.message.content,
                                    child: Image.file(
                                      imageFile!,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    left: 0,
                                    child: Visibility(
                                      visible: widget.last || widget.single,
                                      child: Visibility(
                                        visible: !hasSubText,
                                        child: Container(
                                          height: 30,
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.transparent,
                                                Colors.black87,
                                              ],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ),
                                          ),
                                          padding: EdgeInsets.only(
                                            right: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.03,
                                            bottom: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.02,
                                          ),
                                          alignment: Alignment.bottomRight,
                                          child: Text(
                                            messageTime(
                                                widget.message.createdOn),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const CircularProgressIndicator(),
                    ),
                    Visibility(
                      visible: hasSubText,
                      child: Container(
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.width * 0.02,
                          horizontal: MediaQuery.of(context).size.width * 0.03,
                        ),
                        child: Text(
                          widget.message.imageSubText ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    Visibility(
                      visible: hasSubText,
                      child: Container(
                        padding: EdgeInsets.only(
                          right: MediaQuery.of(context).size.width * 0.03,
                          bottom: MediaQuery.of(context).size.width * 0.02,
                        ),
                        child: Text(
                          messageTime(widget.message.createdOn),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      } else {
        return GestureDetector(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();

            keyBoardOpen = false;

            setState(() {});

            if (widget.manageModeOn) {
              if (toggled) {
                toggled = false;

                widget.interactWithMessage(false);
              } else {
                toggled = true;

                widget.interactWithMessage(true);
              }

              setState(() {});
            }
          },
          child: Container(
            width: min(
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height,
            ),
            color: toggled && widget.manageModeOn
                ? Colors.blueAccent.withOpacity(0.3)
                : Colors.transparent,
            margin: EdgeInsets.only(
              top: widget.single || widget.first
                  ? min(
                      MediaQuery.of(context).size.width * 0.03,
                      MediaQuery.of(context).size.height * 0.03,
                    )
                  : min(
                      MediaQuery.of(context).size.width * 0.01,
                      MediaQuery.of(context).size.height * 0.01,
                    ),
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                margin: EdgeInsets.only(
                  right: min(
                    MediaQuery.of(context).size.width * 0.05,
                    MediaQuery.of(context).size.height * 0.05,
                  ),
                ),
                constraints: BoxConstraints(
                  maxWidth: min(
                    MediaQuery.of(context).size.width * 0.8,
                    MediaQuery.of(context).size.height * 0.8,
                  ),
                ),
                decoration: BoxDecoration(
                  color: myMessageColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: !widget.single && !widget.first
                        ? const Radius.circular(5)
                        : const Radius.circular(20),
                    bottomRight: !widget.single && !widget.last
                        ? const Radius.circular(5)
                        : const Radius.circular(20),
                    bottomLeft: const Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    top: min(
                      MediaQuery.of(context).size.width * 0.02,
                      MediaQuery.of(context).size.height * 0.02,
                    ),
                    left: min(
                      MediaQuery.of(context).size.width * 0.03,
                      MediaQuery.of(context).size.height * 0.03,
                    ),
                    right: min(
                      MediaQuery.of(context).size.width * 0.03,
                      MediaQuery.of(context).size.height * 0.03,
                    ),
                    bottom: min(
                      MediaQuery.of(context).size.width * 0.02,
                      MediaQuery.of(context).size.height * 0.02,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.message.content,
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      Visibility(
                        visible: widget.single || widget.last,
                        child: SizedBox(
                          height: min(
                            MediaQuery.of(context).size.width * 0.02,
                            MediaQuery.of(context).size.height * 0.02,
                          ),
                        ),
                      ),
                      Visibility(
                        visible: widget.single || widget.last,
                        child: Text(
                          messageTime(widget.message.createdOn),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    } else {
      if (widget.message.type == 'image') {
        bool hasSubText = widget.message.imageSubText != null &&
            widget.message.imageSubText != '';

        return GestureDetector(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();

            keyBoardOpen = false;

            setState(() {});

            if (widget.manageModeOn) {
              if (toggled) {
                toggled = false;

                widget.interactWithMessage(false);
              } else {
                toggled = true;

                widget.interactWithMessage(true);
              }

              setState(() {});
            }
          },
          child: Container(
            width: min(
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height,
            ),
            color: toggled ? Colors.white.withOpacity(0.3) : Colors.transparent,
            margin: EdgeInsets.only(
              top: widget.single || widget.first
                  ? min(
                      MediaQuery.of(context).size.width * 0.03,
                      MediaQuery.of(context).size.height * 0.03,
                    )
                  : min(
                      MediaQuery.of(context).size.width * 0.01,
                      MediaQuery.of(context).size.height * 0.01,
                    ),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: EdgeInsets.only(
                  left: min(
                    MediaQuery.of(context).size.width * 0.05,
                    MediaQuery.of(context).size.height * 0.05,
                  ),
                ),
                width: min(
                  MediaQuery.of(context).size.width * 0.8,
                  MediaQuery.of(context).size.height * 0.8,
                ),
                decoration: BoxDecoration(
                  color: partnerMessageColor,
                  borderRadius: BorderRadius.only(
                    topRight: const Radius.circular(20),
                    topLeft: !widget.single && !widget.first
                        ? const Radius.circular(5)
                        : const Radius.circular(20),
                    bottomLeft: !widget.single && !widget.last
                        ? const Radius.circular(5)
                        : const Radius.circular(20),
                    bottomRight: const Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        var path = await appDirectory;

                        List<Message> ImageMessages = [];

                        for (var message in ChatObject.Messages) {
                          if (message.type == 'image') {
                            ImageMessages.add(message);
                          }
                        }

                        var reverseList = ImageMessages.reversed.toList();

                        var index = reverseList.indexOf(widget.message);

                        FocusManager.instance.primaryFocus?.unfocus();

                        await SwipeImageGallery(
                          context: context,
                          itemBuilder: (context, ind) {
                            var message = reverseList[ind];

                            var messageFile = File(
                                '$path/chats/$currentChatId/images/${message.messageId}');

                            return Stack(
                              children: [
                                Positioned.fill(
                                  child: Image.file(
                                    messageFile,
                                  ),
                                ),
                              ],
                            );
                          },
                          itemCount: reverseList.length,
                          initialIndex: index,
                          dismissDragDistance: 10,
                          transitionDuration: 250,
                          hideStatusBar: false,
                        ).show();
                      },
                      child: imageFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(20),
                                topRight: !widget.single && !widget.first
                                    ? const Radius.circular(5)
                                    : const Radius.circular(20),
                                bottomRight: hasSubText
                                    ? Radius.zero
                                    : !widget.single && !widget.last
                                        ? const Radius.circular(5)
                                        : const Radius.circular(20),
                                bottomLeft: hasSubText
                                    ? Radius.zero
                                    : const Radius.circular(20),
                              ),
                              child: Stack(
                                children: [
                                  Hero(
                                    tag: widget.message.content,
                                    child: Image.file(
                                      imageFile!,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    left: 0,
                                    child: Visibility(
                                      visible: widget.last || widget.single,
                                      child: Visibility(
                                        visible: !hasSubText,
                                        child: Container(
                                          height: 30,
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.transparent,
                                                Colors.black87,
                                              ],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ),
                                          ),
                                          padding: EdgeInsets.only(
                                            right: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.03,
                                            bottom: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.02,
                                          ),
                                          alignment: Alignment.bottomRight,
                                          child: Text(
                                            messageTime(
                                                widget.message.createdOn),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const CircularProgressIndicator(),
                    ),
                    Visibility(
                      visible: hasSubText,
                      child: Container(
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.width * 0.02,
                          horizontal: MediaQuery.of(context).size.width * 0.03,
                        ),
                        child: Text(
                          widget.message.imageSubText ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    Visibility(
                      visible: hasSubText,
                      child: Container(
                        padding: EdgeInsets.only(
                          right: MediaQuery.of(context).size.width * 0.03,
                          bottom: MediaQuery.of(context).size.width * 0.02,
                        ),
                        child: Text(
                          messageTime(widget.message.createdOn),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      } else {
        return GestureDetector(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();

            keyBoardOpen = false;

            setState(() {});

            if (widget.manageModeOn) {
              if (toggled) {
                toggled = false;

                widget.interactWithMessage(false);
              } else {
                toggled = true;

                widget.interactWithMessage(true);
              }

              setState(() {});
            }
          },
          child: Container(
            width: min(
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height,
            ),
            color: toggled
                ? Colors.blueAccent.withOpacity(0.3)
                : Colors.transparent,
            margin: EdgeInsets.only(
              top: widget.single || widget.first
                  ? min(
                      MediaQuery.of(context).size.width * 0.03,
                      MediaQuery.of(context).size.height * 0.03,
                    )
                  : min(
                      MediaQuery.of(context).size.width * 0.01,
                      MediaQuery.of(context).size.height * 0.01,
                    ),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: EdgeInsets.only(
                  left: min(
                    MediaQuery.of(context).size.width * 0.05,
                    MediaQuery.of(context).size.height * 0.05,
                  ),
                ),
                constraints: BoxConstraints(
                  maxWidth: min(
                    MediaQuery.of(context).size.width * 0.8,
                    MediaQuery.of(context).size.height * 0.8,
                  ),
                ),
                decoration: BoxDecoration(
                  color: partnerMessageColor,
                  borderRadius: BorderRadius.only(
                    topRight: const Radius.circular(20),
                    topLeft: !widget.single && !widget.first
                        ? const Radius.circular(5)
                        : const Radius.circular(20),
                    bottomLeft: !widget.single && !widget.last
                        ? const Radius.circular(5)
                        : const Radius.circular(20),
                    bottomRight: const Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    top: min(
                      MediaQuery.of(context).size.width * 0.02,
                      MediaQuery.of(context).size.height * 0.02,
                    ),
                    left: min(
                      MediaQuery.of(context).size.width * 0.03,
                      MediaQuery.of(context).size.height * 0.03,
                    ),
                    right: min(
                      MediaQuery.of(context).size.width * 0.03,
                      MediaQuery.of(context).size.height * 0.03,
                    ),
                    bottom: min(
                      MediaQuery.of(context).size.width * 0.02,
                      MediaQuery.of(context).size.height * 0.02,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Visibility(
                        visible: widget.message.passedOn!,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.forward_rounded,
                              color: Colors.black54,
                            ),
                            SizedBox(
                              width: min(
                                MediaQuery.of(context).size.width * 0.02,
                                MediaQuery.of(context).size.height * 0.02,
                              ),
                            ),
                            const Text(
                              'Weitergeleitet',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.black54,
                              ),
                            )
                          ],
                        ),
                      ),
                      Visibility(
                        visible: widget.message.passedOn!,
                        child: SizedBox(
                          height: min(
                            MediaQuery.of(context).size.width * 0.02,
                            MediaQuery.of(context).size.height * 0.02,
                          ),
                        ),
                      ),
                      Text(
                        widget.message.content,
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      Visibility(
                        visible: widget.single || widget.last,
                        child: SizedBox(
                          height: min(
                            MediaQuery.of(context).size.width * 0.02,
                            MediaQuery.of(context).size.height * 0.02,
                          ),
                        ),
                      ),
                      Visibility(
                        visible: widget.single || widget.last,
                        child: Text(
                          messageTime(widget.message.createdOn),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
  }
}
