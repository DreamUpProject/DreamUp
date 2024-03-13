import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_size/flutter_keyboard_size.dart';
import 'package:path_provider/path_provider.dart';
import 'package:swipe_image_gallery/swipe_image_gallery.dart';

import '../additionalPages/chat.dart';

//region Text
class TextMessageWidget extends StatefulWidget {
  final MessageClass message;
  final String chatId;
  final bool single;
  final bool first;
  final bool last;

  const TextMessageWidget({
    Key? key,
    required this.message,
    required this.chatId,
    required this.single,
    required this.first,
    required this.last,
  }) : super(key: key);

  @override
  State<TextMessageWidget> createState() => _TextMessageWidgetState();
}

class _TextMessageWidgetState extends State<TextMessageWidget>
    with AutomaticKeepAliveClientMixin {
  String messageTime(DateTime time) {
    String messageTime = '';

    String hour = time.hour.toString();
    String minute =
        time.minute < 10 ? '0${time.minute}' : time.minute.toString();

    messageTime = '$hour:$minute';

    return messageTime;
  }

  Color myMessageColor = const Color(0xFF84BC8D);
  Color partnerMessageColor = const Color(0xFFECE5DD);

  String currentUser = FirebaseAuth.instance.currentUser!.uid;

  bool showAll = true;
  bool showName = true;
  bool showImage = true;
  bool showBio = true;
  bool showDreamUps = true;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.message.creatorId == currentUser) {
      return GestureDetector(
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
          color: Colors.transparent,
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
    } else {
      return GestureDetector(
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
          color: Colors.transparent,
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
//endregion

//region Image
class ImageMessageWidget extends StatefulWidget {
  final MessageClass message;
  final String chatId;
  final bool single;
  final bool first;
  final bool last;

  const ImageMessageWidget({
    Key? key,
    required this.message,
    required this.chatId,
    required this.single,
    required this.first,
    required this.last,
  }) : super(key: key);

  @override
  State<ImageMessageWidget> createState() => _ImageMessageWidgetState();
}

class _ImageMessageWidgetState extends State<ImageMessageWidget>
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

  Future getImageFile() async {
    final path = await appDirectory;

    var imagePath =
        '$path/chats/${widget.chatId}/images/${widget.message.messageId}';

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

  Color myMessageColor = const Color(0xFF84BC8D);
  Color partnerMessageColor = const Color(0xFFECE5DD);

  String currentUser = FirebaseAuth.instance.currentUser!.uid;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getImageFile();

      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final chatProvider =
        Provider.of<ChatNetworkManager>(context, listen: false);

    if (widget.message.creatorId == currentUser) {
      bool hasSubText = widget.message.imageSubText != null &&
          widget.message.imageSubText != '';

      return GestureDetector(
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
          color: Colors.transparent,
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

                      List<MessageClass> ImageMessages = [];

                      for (var message in chatProvider.messageList) {
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
                                          messageTime(widget.message.createdOn),
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
      bool hasSubText = widget.message.imageSubText != null &&
          widget.message.imageSubText != '';

      return GestureDetector(
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
          color: Colors.transparent,
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

                      List<MessageClass> ImageMessages = [];

                      for (var message in chatProvider.messageList) {
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
                                          messageTime(widget.message.createdOn),
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
    }
  }
}
//endregion

//region System
class SystemMessageWidget extends StatefulWidget {
  final MessageClass message;
  final String chatId;

  const SystemMessageWidget({
    Key? key,
    required this.message,
    required this.chatId,
  }) : super(key: key);

  @override
  State<SystemMessageWidget> createState() => _SystemMessageWidgetState();
}

class _SystemMessageWidgetState extends State<SystemMessageWidget>
    with AutomaticKeepAliveClientMixin {
  Color systemMessageColor = const Color(0xFF6EAFCA);

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
    final chatProvider =
        Provider.of<ChatNetworkManager>(context, listen: false);

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
                          await confirmShownInfoFirstTime(
                              widget.message.messageId);

                          MessageClass? systemMessage = chatProvider.messageList
                              .firstWhereOrNull(
                                  (element) => element.type == 'system');

                          systemMessage?.decided = true;

                          chatProvider.messageList.remove(systemMessage);

                          await chatProvider.saveMessages(widget.chatId);

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
  Widget build(BuildContext context) {
    super.build(context);

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
          color: Colors.transparent,
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
  }
}
//endregion
