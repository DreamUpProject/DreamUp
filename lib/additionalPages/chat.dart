import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_size/flutter_keyboard_size.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:friendivity/additionalPages/userProfile.dart';
import 'package:friendivity/widgets/messageWidgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:sticky_grouped_list/sticky_grouped_list.dart';

import '../main.dart';

//region Global Variables
String currentChatId = '';
Map? chatData = {};
bool keyBoardOpen = false;
//endregion

//region UI Logic
class ChatWidget extends StatefulWidget {
  final String chatId;
  final String partnerName;
  final String partnerId;

  const ChatWidget({
    Key? key,
    required this.chatId,
    required this.partnerName,
    required this.partnerId,
  }) : super(key: key);

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final currentUser = FirebaseAuth.instance.currentUser?.uid;

  File? imageFile;

  Widget dateSeparator(MessageClass message) {
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

  String dateString(MessageClass message) {
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

  bool showLandscape = false;

  static List<MessageClass> imageMessages = [];

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

  Widget buildMessageWidget({
    required MessageClass message,
    required bool single,
    required bool first,
    required bool last,
  }) {
    switch (message.type) {
      case 'text':
        return TextMessageWidget(
          message: message,
          chatId: widget.chatId,
          single: single,
          first: first,
          last: last,
        );
      case 'image':
        return ImageMessageWidget(
          message: message,
          chatId: widget.chatId,
          single: single,
          first: first,
          last: last,
        );
      case 'system':
        return SystemMessageWidget(
          message: message,
          chatId: widget.chatId,
        );
      default:
        return Container();
    }
  }

  @override
  void initState() {
    super.initState();

    currentChatId = widget.chatId;

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);

    imageSubTextController = TextEditingController()
      ..addListener(() {
        setState(() {});
      });

    Future.delayed(
      Duration.zero,
      () async {
        final chatProvider =
            Provider.of<ChatNetworkManager>(context, listen: false);

        chatProvider.messageList.clear();

        await chatProvider.loadMessages(widget.chatId);

        var last = chatProvider.messageList.last.createdOn;

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
      },
    );
  }

  @override
  void dispose() {
    currentChatId = '';

    changeOnlineStatus(false);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    final chatProvider =
        Provider.of<ChatNetworkManager>(context, listen: false);

    chatProvider.messageList.clear();

    imageSubTextController.dispose();

    keyBoardOpen = false;

    chatData = null;

    imageMessages.clear();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatNetworkManager>(context);

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

                          var message = MessageClass.fromJson(data);

                          var existing = chatProvider.messageList
                              .firstWhereOrNull((element) =>
                                  element.messageId == message.messageId);

                          if (existing == null) {
                            chatProvider.messageList.add(message);

                            Future.delayed(
                              Duration.zero,
                              () async {
                                setState(() {});

                                await chatProvider.saveMessages(widget.chatId);
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
                                                      MessageClass, DateTime>(
                                                    key: Key(
                                                      chatProvider
                                                          .messageList.length
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
                                                    elements: chatProvider
                                                        .messageList,
                                                    order:
                                                        StickyGroupedListOrder
                                                            .ASC,
                                                    groupBy: (MessageClass
                                                            message) =>
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
                                                    itemComparator: (MessageClass
                                                                message1,
                                                            MessageClass
                                                                message2) =>
                                                        message2.createdOn
                                                            .compareTo(message1
                                                                .createdOn),
                                                    floatingHeader: true,
                                                    groupSeparatorBuilder:
                                                        dateSeparator,
                                                    indexedItemBuilder:
                                                        (BuildContext context,
                                                            MessageClass
                                                                message,
                                                            int index) {
                                                      bool single = true;
                                                      bool first = false;
                                                      bool last = false;

                                                      MessageClass?
                                                          previousMessage;
                                                      MessageClass? nextMessage;

                                                      bool previousExisting =
                                                          false;
                                                      bool nextExisting = false;

                                                      if (index > 0) {
                                                        nextMessage =
                                                            chatProvider
                                                                    .messageList[
                                                                index - 1];
                                                        nextExisting = true;
                                                      }

                                                      if (index + 1 <
                                                          chatProvider
                                                              .messageList
                                                              .length) {
                                                        previousMessage =
                                                            chatProvider
                                                                    .messageList[
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

                                                      return buildMessageWidget(
                                                        message: message,
                                                        single: single,
                                                        first: first,
                                                        last: last,
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
                                partnerId: widget.partnerId,
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
                                chatProvider.sendImageMessage(
                                  chatId: widget.chatId,
                                  file: imageFile,
                                  subText: imageSubTextController.text,
                                  partnerId: widget.partnerId,
                                );

                                setState(() {
                                  imageSubTextController.text = '';
                                  imageFile = null;
                                });
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
  final String partnerId;

  const MessageInputWidget({
    Key? key,
    required this.sendingCallback,
    required this.onImageSelection,
    required this.chatId,
    required this.partnerId,
  }) : super(key: key);

  @override
  State<MessageInputWidget> createState() => _MessageInputWidgetState();
}

class _MessageInputWidgetState extends State<MessageInputWidget>
    with WidgetsBindingObserver {
  final chat = FirebaseFirestore.instance.collection('chats');

  bool sending = false;

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

  final currentUser = FirebaseAuth.instance.currentUser?.uid;

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
    final chatProvider =
        Provider.of<ChatNetworkManager>(context, listen: false);

    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      showLandscape = false;
    } else {
      showLandscape = true;
    }

    return ChangeNotifierProvider(
      create: (context) => ChatNetworkManager(),
      child: Container(
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
                                          borderRadius:
                                              BorderRadius.circular(15),
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
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 15,
                                                  ),
                                                  color: Colors.transparent,
                                                  child: const Row(
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .camera_alt_outlined,
                                                        size: 30,
                                                        color:
                                                            Colors.blueAccent,
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
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 15,
                                                  ),
                                                  color: Colors.transparent,
                                                  child: const Row(
                                                    children: [
                                                      Icon(
                                                        Icons.image_outlined,
                                                        size: 30,
                                                        color:
                                                            Colors.blueAccent,
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
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .width *
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
                                    height: MediaQuery.of(context).size.height *
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
                                      left: MediaQuery.of(context).size.width *
                                          0.05,
                                      right: MediaQuery.of(context).size.width *
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
                                                      BorderRadius.circular(
                                                          300),
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
                          chatProvider.sendTextMessage(
                            chatId: widget.chatId,
                            message: sendController.text,
                            partnerId: widget.partnerId,
                          );

                          sendController.text = '';
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
      ),
    );
  }
}
//endregion

//region Business Logic
class ChatNetworkManager with ChangeNotifier {
  List<MessageClass> messageList = [];

  bool sending = false;

  final currentUser = FirebaseAuth.instance.currentUser?.uid;

  Future<String> get appDirectory async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future saveMessages(String chatId) async {
    final path = await appDirectory;

    bool existing = await File('$path/chats/$chatId/messageFile').exists();

    if (existing) {
      var file = File('$path/chats/$chatId/messageFile');

      String json = jsonEncode(messageList);

      file.writeAsStringSync(json);
    } else {
      File file =
          await File('$path/chats/$chatId/messageFile').create(recursive: true);

      String json = jsonEncode(messageList);

      file.writeAsStringSync(json);
    }

    print('messages saved');

    notifyListeners();
  }

  Future loadMessages(String chatId) async {
    final path = await appDirectory;

    bool existing = await File('$path/chats/$chatId/messageFile').exists();

    if (existing) {
      print('existing');

      var file = File('$path/chats/$chatId/messageFile');

      var json = await file.readAsString();

      print(json);

      var decoded = jsonDecode(json);

      print('entries on file: ${decoded.length}');

      for (Map<String, dynamic> entry in decoded) {
        var message = MessageClass.fromJson(entry);

        print(message.content);

        var duplicate = messageList.firstWhereOrNull(
            (element) => element.messageId == message.messageId);

        if (duplicate == null) {
          messageList.add(message);
        }
      }

      print('messages on list: ${messageList.length}');
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

        var message = MessageClass.fromJson(data);

        messageList.add(message);
      }

      await saveMessages(chatId);

      print('messages saved');
    }

    notifyListeners();
  }

  Future saveMediaOnPhone({
    required File file,
    required String messageId,
    required String chatId,
  }) async {
    final path = await appDirectory;

    await File('$path/chats/$chatId/images/$messageId').create(recursive: true);

    await file.copy('$path/chats/$chatId/images/$messageId');
  }

  Future sendImageMessage({
    required String chatId,
    required File? file,
    required String subText,
    required String partnerId,
  }) async {
    if (!sending) {
      sending = true;

      final FirebaseStorage storage = FirebaseStorage.instance;

      var messageRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();

      var id = messageRef.id;

      String imageLink = '';

      DateTime now = DateTime.now();

      await saveMediaOnPhone(file: file!, messageId: id, chatId: chatId);

      var messageObject = MessageClass(
        content: imageLink,
        creatorId: currentUser!,
        type: 'image',
        messageId: id,
        createdOn: now,
        imageSubText: subText,
      );

      messageList.add(messageObject);

      notifyListeners();

      var currentFile = file;

      file = null;

      try {
        await storage.ref('chatMedia/$chatId/images/$id').putFile(
              currentFile,
            );

        imageLink = await FirebaseStorage.instance
            .ref('chatMedia/$chatId/images/$id')
            .getDownloadURL();
      } on FirebaseException catch (e) {
        print(e);
      }

      var thisMessage =
          messageList.lastWhere((element) => element.messageId == id);

      thisMessage.content = imageLink;

      await saveMessages(chatId);

      Map<String, dynamic> chatJson = {};

      await messageRef.set({
        'messageId': id,
        'createdOn': now,
        'creatorId': currentUser,
        'type': 'image',
        'content': imageLink,
        'imageSubText': subText,
      });

      var onlineUsers = chatData?['onlineUsers'] as List<dynamic>;

      if (!onlineUsers.contains(partnerId)) {
        chatJson.addAll({
          'new': true,
        });

        var notificationDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(partnerId)
            .collection('messageNotifications')
            .doc();

        var note = {
          'time': now,
          'new': true,
          'chatId': chatId,
        };

        await notificationDoc.set(note);
      }

      sending = false;

      chatJson.addAll({
        'lastAction': DateTime.now(),
        'lastSender': currentUser,
        'lastMessage': imageLink,
        'lastType': 'image',
      });

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .update(chatJson);
    }
  }

  Future sendTextMessage({
    required String chatId,
    required String message,
    required String partnerId,
  }) async {
    if (!sending) {
      sending = true;

      if (message == '') return;

      DateTime now = DateTime.now();

      var messageDoc = FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();

      var messageObject = MessageClass(
        content: message.trim(),
        creatorId: currentUser!,
        type: 'text',
        messageId: messageDoc.id,
        createdOn: now,
      );

      messageList.add(messageObject);

      notifyListeners();

      await saveMessages(chatId);

      await messageDoc.set({
        'messageId': messageDoc.id,
        'createdOn': now,
        'creatorId': currentUser,
        'type': 'text',
        'content': message.trim(),
      });

      Map<String, dynamic> chatJson = {};

      var onlineUsers = chatData?['onlineUsers'] as List<dynamic>;

      if (!onlineUsers.contains(partnerId)) {
        chatJson.addAll({'new': true});

        var notificationDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(partnerId)
            .collection('messageNotifications')
            .doc();

        var note = {
          'time': now,
          'new': true,
          'chatId': chatId,
        };

        await notificationDoc.set(note);
      }

      sending = false;

      chatJson.addAll({
        'lastAction': DateTime.now(),
        'lastSender': currentUser,
        'lastMessage': message.trim(),
        'lastType': 'text',
      });

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .update(chatJson);
    }
  }
}

class MessageClass {
  late String messageId;
  late String creatorId;
  late DateTime createdOn;
  late String type;
  late String content;
  late String? imageSubText;
  late bool? decided;

  MessageClass({
    required this.messageId,
    required this.creatorId,
    required this.createdOn,
    required this.type,
    required this.content,
    this.imageSubText,
    this.decided,
  });

  MessageClass.fromJson(Map<String, dynamic> json) {
    messageId = json['messageId'];
    creatorId = json['creatorId'];
    createdOn = json['createdOn'] is String
        ? DateTime.parse(json['createdOn'])
        : (json['createdOn'] as Timestamp).toDate();
    type = json['type'];
    content = json['content'];
    imageSubText = json['imageSubText'];
    decided = json['decided'] ?? false;
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'creatorId': creatorId,
      'createdOn': createdOn.toString(),
      'type': type,
      'content': content,
      'imageSubText': imageSubText ?? '',
      'decided': decided ?? false,
    };
  }
}
//endregion
