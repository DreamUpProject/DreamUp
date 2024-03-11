import 'dart:io';
import 'dart:math';

import 'package:age_calculator/age_calculator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:decorated_icon/decorated_icon.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:friendivity/additionalPages/dreamUpEdit.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../main.dart';
import '../mainScreens/thread.dart';
import '../utils/audioWidgets.dart';
import '../utils/imageEditingIsolate.dart';

Map<String, dynamic> creatorInfo = {};
List<Map<String, dynamic>> creatorWishes = [];

bool loading = false;

ImageProvider? dreamUpImage;
ImageProvider? blurredImage;

class DreamUpDetailPage extends StatefulWidget {
  final Map<String, dynamic> dreamUpData;

  const DreamUpDetailPage({
    Key? key,
    required this.dreamUpData,
  }) : super(key: key);

  @override
  State<DreamUpDetailPage> createState() => _DreamUpDetailPageState();
}

class _DreamUpDetailPageState extends State<DreamUpDetailPage>
    with SingleTickerProviderStateMixin {
  final currentUser = FirebaseAuth.instance.currentUser?.uid;

  int counter = 0;

  bool hasKeyQuestions = true;

  final scrollController = ScrollController();

  bool needsScroller = false;

  bool descriptionExpanded = false;

  late DraggableScrollableController connectDragController;
  late DraggableScrollableController profileDragController;

  double connectInitSize = 0;

  double currentSheetHeight = 0;

  bool uploading = false;

  List<Map<String, dynamic>> contactInfo = [];

  void contactCreator() async {
    uploading = true;

    await CurrentUser().saveUserInformation();

    var existingChat =
        await FirebaseFirestore.instance.collection('chats').where(
      'users',
      isEqualTo: {
        widget.dreamUpData['creator']: null,
        currentUser: null,
      },
    ).get();

    if (existingChat.docs.isNotEmpty) {
      print('chat is there');

      for (var entry in contactInfo) {
        if (entry['isAnswer']) {
          Map<String, dynamic> answerMessage = entry;

          String question = answerMessage['question'];
          DateTime created = answerMessage['createdOn'];
          DateTime questionCreated = DateTime(created.year, created.month,
              created.day, created.hour, created.minute, created.second - 1);
          String creator = widget.dreamUpData['creator'];

          Map<String, dynamic> questionMessage = {
            'content': question,
            'createdOn': questionCreated,
            'creatorId': creator,
            'type': 'requestText',
          };

          answerMessage.remove('isAnswer');
          answerMessage.remove('question');

          var questionDoc = FirebaseFirestore.instance
              .collection('chats')
              .doc(existingChat.docs.first.data()['id'])
              .collection('messages')
              .doc();
          var answerDoc = FirebaseFirestore.instance
              .collection('chats')
              .doc(existingChat.docs.first.data()['id'])
              .collection('messages')
              .doc();

          questionMessage.addAll(
            {
              'messageId': questionDoc.id,
            },
          );
          answerMessage.addAll(
            {
              'messageId': answerDoc.id,
            },
          );

          await questionDoc.set(questionMessage);
          await answerDoc.set(answerMessage);
        } else {
          Map<String, dynamic> answerMessage = entry;
          answerMessage.remove('isAnswer');

          var answerDoc = FirebaseFirestore.instance
              .collection('chats')
              .doc(existingChat.docs.first.data()['id'])
              .collection('messages')
              .doc();

          answerMessage.addAll(
            {
              'messageId': answerDoc.id,
            },
          );

          await answerDoc.set(answerMessage);
        }
      }

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(existingChat.docs.first.id)
          .update({
        'lastAction': DateTime.now(),
        'lastSender': currentUser,
        'participants': widget.dreamUpData['creator'],
        'new': true,
        'lastMessage': '',
        'lastType': 'text',
      });
    } else {
      print('chat is not there');

      var requestChat = FirebaseFirestore.instance.collection('chats').doc();

      var creator = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.dreamUpData['creator'])
          .get();

      var name = creator['name'];

      Map<String, dynamic> chatInfo = {
        'id': requestChat.id,
        'images': {
          currentUser: CurrentUser.imageLink,
          widget.dreamUpData['creator']: creator['imageLink'],
        },
        'lastAction': DateTime.now(),
        'lastSender': currentUser,
        'lastLogin': {
          currentUser: DateTime.now(),
          widget.dreamUpData['creator']: DateTime.now(),
        },
        'names': [
          name,
          CurrentUser.name,
        ],
        'new': true,
        'onlineUsers': [],
        'participants': [
          widget.dreamUpData['creator'],
        ],
        'users': {
          widget.dreamUpData['creator']: null,
          currentUser: null,
        },
        'isRequest': true,
      };

      await requestChat.set(chatInfo).then(
            (value) => Fluttertoast.showToast(
              msg: 'Chat created',
            ),
          );

      for (int i = 0; i < contactInfo.length; i++) {
        var entry = contactInfo[i];

        if (entry['isAnswer']) {
          Map<String, dynamic> answerMessage = entry;

          String question = answerMessage['question'];
          DateTime created = answerMessage['createdOn'];
          DateTime questionCreated = DateTime(created.year, created.month,
              created.day, created.hour, created.minute, created.second - 1);
          String creator = widget.dreamUpData['creator'];

          Map<String, dynamic> questionMessage = {
            'content': question,
            'createdOn': questionCreated,
            'creatorId': creator,
            'type': 'requestText',
          };

          answerMessage.remove('isAnswer');
          answerMessage.remove('question');

          var questionDoc = FirebaseFirestore.instance
              .collection('chats')
              .doc(requestChat.id)
              .collection('messages')
              .doc();
          var answerDoc = FirebaseFirestore.instance
              .collection('chats')
              .doc(requestChat.id)
              .collection('messages')
              .doc();

          questionMessage.addAll(
            {
              'messageId': questionDoc.id,
            },
          );
          answerMessage.addAll(
            {
              'messageId': answerDoc.id,
            },
          );

          await questionDoc.set(questionMessage);
          await answerDoc.set(answerMessage);
        } else {
          Map<String, dynamic> answerMessage = entry;
          answerMessage.remove('isAnswer');

          var answerDoc = FirebaseFirestore.instance
              .collection('chats')
              .doc(requestChat.id)
              .collection('messages')
              .doc();

          answerMessage.addAll(
            {
              'messageId': answerDoc.id,
            },
          );

          await answerDoc.set(answerMessage);
        }
      }

      var systemDoc = FirebaseFirestore.instance
          .collection('chats')
          .doc(requestChat.id)
          .collection('messages')
          .doc();

      Map<String, dynamic> systemMessage = {
        'content': '',
        'createdOn': DateTime.now(),
        'creatorId': currentUser,
        'messageId': systemDoc.id,
        'type': 'system',
      };

      await systemDoc.set(systemMessage);
    }

    Fluttertoast.showToast(msg: 'request sent');

    contactInfo.clear();

    uploading = false;
  }

  bool showPopUp = false;

  bool myDreamUp = false;

  GlobalKey titleKey = GlobalKey();
  GlobalKey buttonKey = GlobalKey();
  GlobalKey textKey = GlobalKey();
  GlobalKey readMoreKey = GlobalKey();

  double titleHeight = 0;
  double buttonHeight = 0;
  double textHeight = 0;
  double originalScrollerHeight = 0;
  double expandedScrollerHeight = 0;
  double readMoreHeight = 0;

  String getGender(String? originalGender) {
    String gender = '';

    if (originalGender == 'male') {
      gender = 'männlich';
    } else if (originalGender == 'female') {
      gender = 'weiblich';
    } else if (originalGender == 'diverse') {
      gender = 'divers';
    } else if (originalGender == null) {
      gender = 'unbekannt';
    }

    return gender;
  }

  String getAge(DateTime birthday) {
    String age = '';

    var years = AgeCalculator.age(
      birthday,
    ).years;
    var myAge = AgeCalculator.age(
      CurrentUser.birthday!,
    ).years;

    if (years > myAge + ageRange) {
      age = 'älter';
    } else if (years < myAge - ageRange) {
      age = 'jünger';
    } else {
      age = 'dein Alter';
    }

    return age;
  }

  @override
  void initState() {
    super.initState();

    if (widget.dreamUpData['creator'] == currentUser) {
      myDreamUp = true;
    } else {
      myDreamUp = false;
    }

    connectDragController = DraggableScrollableController();
    profileDragController = DraggableScrollableController();

    if (widget.dreamUpData['keyQuestions'] != null &&
        widget.dreamUpData['keyQuestions'].isNotEmpty) {
      hasKeyQuestions = true;
    } else {
      hasKeyQuestions = false;
    }

    scrollController.addListener(() {
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var titleContext = titleKey.currentContext;
      var buttonContext = buttonKey.currentContext;
      var textContext = textKey.currentContext;
      var readMoreContext = readMoreKey.currentContext;

      if (titleContext != null) {
        titleHeight = titleContext.size!.height;
      }

      if (buttonContext != null) {
        buttonHeight = buttonContext.size!.height;
      }

      if (textContext != null) {
        textHeight = textContext.size!.height;
      }

      if (readMoreContext != null) {
        readMoreHeight = readMoreContext.size!.height;
      }

      originalScrollerHeight = MediaQuery.of(context).size.height -
          MediaQuery.of(context).size.width -
          titleHeight -
          buttonHeight -
          readMoreHeight -
          homeBarHeight;

      var spacing = MediaQuery.of(context).size.width -
          MediaQuery.of(context).padding.top -
          50;

      expandedScrollerHeight = originalScrollerHeight + spacing;

      if (textHeight <= originalScrollerHeight) {
        needsScroller = false;

        originalScrollerHeight = originalScrollerHeight + readMoreHeight;
      }

      if (widget.dreamUpData['content'] == '') {
        needsScroller = false;

        originalScrollerHeight = originalScrollerHeight + readMoreHeight;
      }

      setState(() {});
    });
  }

  @override
  void dispose() {
    connectDragController.dispose();

    scrollController.dispose();

    dreamUpImage = null;
    blurredImage = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () {
          if (showPopUp) {
            showPopUp = false;

            setState(() {});
          }
        },
        child: SizedBox.expand(
          child: Stack(
            children: [
              VibeDetailBackground(
                dreamUpData: widget.dreamUpData,
              ),
              SizedBox.expand(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      key: titleKey,
                      duration: Duration.zero,
                      margin: EdgeInsets.only(
                        left: MediaQuery.of(context).size.width * 0.05,
                      ),
                      width: MediaQuery.of(context).size.width * 0.9,
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.dreamUpData['title'],
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                              shadows: const [
                                Shadow(
                                  color: Colors.black87,
                                  blurRadius: 10,
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            myDreamUp
                                ? 'dein DreamUp'
                                : '${getGender(widget.dreamUpData['creatorGender'])}, ${getAge((widget.dreamUpData['creatorBirthday'].toDate()))}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              shadows: [
                                Shadow(
                                  color: Colors.black87,
                                  blurRadius: 10,
                                  offset: Offset(1, 1),
                                ),
                              ],
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      color: Colors.transparent,
                      height: !descriptionExpanded
                          ? (MediaQuery.of(context).size.width -
                                  (MediaQuery.of(context).size.height * 0.2 -
                                      titleHeight) +
                                  15) *
                              currentSheetHeight /
                              0.8
                          : 0,
                    ),
                    Container(
                      key: buttonKey,
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.1,
                        vertical: MediaQuery.of(context).size.width * 0.05,
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              // connectDragController.animateTo(
                              //   0.8,
                              //   duration: const Duration(milliseconds: 250),
                              //   curve: Curves.fastOutSlowIn,
                              // );
                            },
                            child: SizedBox(
                              height: 25,
                              width: 25,
                              child: Stack(
                                children: [
                                  Positioned(
                                    left: 1,
                                    bottom: 4,
                                    child: Transform.rotate(
                                      angle: -24 * pi / 180,
                                      child: DecoratedIcon(
                                        Icons.send_rounded,
                                        color: Colors.white.withOpacity(0.8),
                                        shadows: const [
                                          Shadow(
                                            color: Colors.black54,
                                            blurRadius: 5,
                                            offset: Offset(
                                              1,
                                              1,
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
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: Duration(
                        milliseconds: animationSpeed,
                      ),
                      padding: EdgeInsets.only(
                        left: MediaQuery.of(context).size.width * 0.1,
                        right: MediaQuery.of(context).size.width * 0.1,
                      ),
                      color: Colors.transparent,
                      clipBehavior: Clip.antiAlias,
                      height: !descriptionExpanded
                          ? originalScrollerHeight
                          : min(textHeight, expandedScrollerHeight),
                      child: widget.dreamUpData['content'] != ''
                          ? GestureDetector(
                              onTap: () {
                                if (needsScroller) {
                                  if (descriptionExpanded) {
                                    descriptionExpanded = false;
                                  } else {
                                    descriptionExpanded = true;
                                  }

                                  counter++;

                                  setState(() {});
                                }
                              },
                              child: ListView(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                key: Key(
                                  counter.toString(),
                                ),
                                physics: descriptionExpanded
                                    ? const BouncingScrollPhysics()
                                    : const NeverScrollableScrollPhysics(),
                                children: [
                                  Column(
                                    key: textKey,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        widget.dreamUpData['content'],
                                        textAlign: TextAlign.start,
                                        style: TextStyle(
                                          fontSize: smallTextSize,
                                          color: Colors.white,
                                          shadows: const [
                                            Shadow(
                                              color: Colors.black87,
                                              blurRadius: 5,
                                              offset: Offset(1, 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                      widget.dreamUpData['hashtags'] != null
                                          ? Container(
                                              margin: EdgeInsets.only(
                                                top: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.05,
                                              ),
                                              alignment: Alignment.centerLeft,
                                              child: Wrap(
                                                spacing: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.02,
                                                runSpacing:
                                                    MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        0.02,
                                                children: (widget.dreamUpData[
                                                            'hashtags']
                                                        as List<dynamic>)
                                                    .map<Widget>(
                                                      (hashtag) => Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                            200,
                                                          ),
                                                        ),
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                          horizontal:
                                                              MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width *
                                                                  0.02,
                                                          vertical: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              0.01,
                                                        ),
                                                        child: Text(
                                                          hashtag,
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.8),
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                              ),
                                            )
                                          : Container(),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          : Center(
                              child: WishAudioPlayer(
                                isFile: false,
                                source: widget.dreamUpData['audioLink'],
                              ),
                            ),
                    ),
                    Visibility(
                      visible: needsScroller,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            if (descriptionExpanded) {
                              descriptionExpanded = false;
                            } else {
                              descriptionExpanded = true;
                            }

                            counter++;

                            setState(() {});
                          },
                          child: Container(
                            key: readMoreKey,
                            color: Colors.transparent,
                            padding: EdgeInsets.only(
                              top: MediaQuery.of(context).size.width * 0.02,
                              bottom: MediaQuery.of(context).size.width * 0.05,
                            ),
                            child: Text(
                              descriptionExpanded ? 'read less' : 'read more',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black87,
                                    blurRadius: 10,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: homeBarHeight,
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                child: NotificationListener<DraggableScrollableNotification>(
                  onNotification: (notification) {
                    setState(() {
                      currentSheetHeight = notification.extent;
                      connectInitSize = notification.extent;
                    });

                    if (notification.extent <= 0.1 && connectInitSize != 0) {
                      connectInitSize = 0;
                      currentSheetHeight = 0;

                      print('called?');

                      if (!uploading && contactInfo.isNotEmpty) {
                        contactCreator();
                      }
                    }

                    if (notification.extent <= 0.02) {
                      FocusManager.instance.primaryFocus?.unfocus();
                    }

                    return true;
                  },
                  child: DraggableScrollableSheet(
                    maxChildSize: 0.8,
                    minChildSize: 0,
                    initialChildSize: connectInitSize,
                    controller: connectDragController,
                    snap: true,
                    builder: (context, scrollController) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(
                              MediaQuery.of(context).size.width * 0.05,
                            ),
                            topLeft: Radius.circular(
                              MediaQuery.of(context).size.width * 0.05,
                            ),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              spreadRadius: 1,
                              offset: Offset(0, -1),
                            ),
                          ],
                        ),
                        child: ListView(
                          padding: EdgeInsets.zero,
                          controller: scrollController,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            Container(),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top,
                left: 0,
                child: AnimatedOpacity(
                  duration: Duration.zero,
                  opacity: 1 - currentSheetHeight / 0.8,
                  child: GestureDetector(
                    onTap: () {
                      if (currentSheetHeight == 0) {
                        Navigator.pop(context);
                      }
                    },
                    child: Container(
                      color: Colors.transparent,
                      height: 50,
                      width: 50,
                      child: const Center(
                        child: DecoratedIcon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black87,
                              blurRadius: 5,
                              offset: Offset(
                                1,
                                1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top,
                right: 0,
                child: Visibility(
                  visible: myDreamUp,
                  child: AnimatedOpacity(
                    duration: Duration.zero,
                    opacity: 1 - currentSheetHeight / 0.8,
                    child: GestureDetector(
                      onTap: () {
                        if (currentSheetHeight == 0) {
                          showPopUp ? showPopUp = false : showPopUp = true;

                          setState(() {});
                        }
                      },
                      child: Container(
                        color: Colors.transparent,
                        height: 50,
                        width: 50,
                        child: const Center(
                          child: DecoratedIcon(
                            Icons.settings_rounded,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black87,
                                blurRadius: 5,
                                offset: Offset(
                                  1,
                                  1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 50,
                right: 5,
                child: Visibility(
                  visible: showPopUp,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 10,
                          spreadRadius: 1,
                          offset: Offset(
                            2,
                            2,
                          ),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            var changed = await Navigator.push(
                              context,
                              changePage(
                                DreamUpEditPage(
                                  dreamUpData: widget.dreamUpData,
                                  dreamUpImage: Image(
                                    image: dreamUpImage!,
                                    width: MediaQuery.of(context).size.width,
                                    height: MediaQuery.of(context).size.width,
                                    fit: BoxFit.fill,
                                  ),
                                  blurredImage: Image(
                                    image: blurredImage!,
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),
                            );

                            if (changed) {
                              setState(() {});
                            }
                          },
                          child: Container(
                            color: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 5,
                            ),
                            child: const Text(
                              'DreamUp bearbeiten',
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            var id = widget.dreamUpData['id'];

                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser?.uid)
                                .update(
                              {
                                'createdVibes': FieldValue.arrayRemove(
                                  [
                                    widget.dreamUpData['id'],
                                  ],
                                ),
                              },
                            );

                            List<dynamic>? vibeHashtags =
                                widget.dreamUpData['hashtags'];

                            if (vibeHashtags != null) {
                              for (var hashtag in vibeHashtags) {
                                var databaseHashtag = await FirebaseFirestore
                                    .instance
                                    .collection('hashtags')
                                    .where('hashtag', isEqualTo: hashtag)
                                    .get();

                                for (var dbHashtag in databaseHashtag.docs) {
                                  var data = dbHashtag.data();

                                  if (data['useCount'] < 2) {
                                    await FirebaseFirestore.instance
                                        .collection('hashtags')
                                        .doc(dbHashtag.id)
                                        .delete();
                                  } else {
                                    await FirebaseFirestore.instance
                                        .collection('hashtags')
                                        .doc(dbHashtag.id)
                                        .update(
                                      {
                                        'useCount': FieldValue.increment(-1),
                                      },
                                    );
                                  }
                                }
                              }
                            }

                            if (widget.dreamUpData['audioLink'] != null) {
                              var audioRef = FirebaseStorage.instance
                                  .refFromURL(widget.dreamUpData['audioLink']);

                              await audioRef.delete();
                            }

                            await FirebaseFirestore.instance
                                .collection('vibes')
                                .doc(id)
                                .delete();

                            await FirebaseFirestore.instance
                                .collection('deleted')
                                .add(
                              {
                                'deleteTime': DateTime.now(),
                                'id': id,
                              },
                            );

                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(currentUser)
                                .update(
                              {
                                'createdVibes': FieldValue.arrayRemove(
                                  [id],
                                ),
                              },
                            );

                            CurrentUser().saveUserInformation();

                            var vibeInList = vibeList.firstWhereOrNull(
                                (element) => element['id'] == id);

                            if (vibeInList != null) {
                              var index = vibeList.indexOf(vibeInList);

                              if (index <= currentIndex) {
                                vibeList.remove(vibeInList);

                                if (currentIndex > 0) {
                                  currentIndex--;
                                }
                              }
                            }

                            Navigator.pop(context);
                          },
                          child: Container(
                            color: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 5,
                            ),
                            child: const Text(
                              'DreamUp löschen',
                              style: TextStyle(
                                fontSize: 20,
                              ),
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
        ),
      ),
    );
  }
}

class VibeDetailBackground extends StatefulWidget {
  final Map<String, dynamic> dreamUpData;

  const VibeDetailBackground({
    required this.dreamUpData,
    Key? key,
  }) : super(key: key);

  @override
  State<VibeDetailBackground> createState() => _VibeDetailBackgroundState();
}

class _VibeDetailBackgroundState extends State<VibeDetailBackground> {
  Future<String> get appDirectory async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      dreamUpImage =
          CachedNetworkImageProvider(widget.dreamUpData['imageLink']);

      var cachedImage = await DefaultCacheManager()
          .getSingleFile(widget.dreamUpData['imageLink']);

      var path = await appDirectory;

      File compressedFile =
          await File('$path/compressedImage/${widget.dreamUpData['id']}.jpg')
              .create(recursive: true);

      var compressed = await FlutterImageCompress.compressAndGetFile(
        cachedImage.path,
        compressedFile.path,
        minHeight: 200,
        minWidth: 200,
        quality: 0,
      );

      File imageFile = File(compressed!.path);

      File file = await File('$path/blurredImage/${widget.dreamUpData['id']}')
          .create(recursive: true);

      var uiImage = await compute(blurImage, imageFile);

      file.writeAsBytesSync(
        img.encodePng(uiImage),
        mode: FileMode.append,
      );

      blurredImage = Image.file(
        file,
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.width,
      ).image;

      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return blurredImage != null
        ? Stack(
            children: [
              Positioned(
                top: 0,
                child: Column(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.width,
                      width: MediaQuery.of(context).size.width,
                      child: Image(
                        image: blurredImage!,
                        height: MediaQuery.of(context).size.width,
                        width: MediaQuery.of(context).size.width,
                        fit: BoxFit.fill,
                        gaplessPlayback: true,
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height * 3,
                      child: Transform.rotate(
                        angle: 180 * pi / 180,
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.rotationY(pi),
                          child: Image(
                            image: blurredImage!,
                            width: MediaQuery.of(context).size.width,
                            fit: BoxFit.fill,
                            gaplessPlayback: true,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).size.width * 0.7,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).size.width * 0.7,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [
                        0,
                        1,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                child: SizedBox(
                  height: MediaQuery.of(context).size.width,
                  width: MediaQuery.of(context).size.width,
                  child: Stack(
                    children: [
                      ShaderMask(
                        shaderCallback: (rect) {
                          return const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black,
                              Colors.transparent,
                            ],
                            stops: [
                              0.4,
                              1,
                            ],
                          ).createShader(rect);
                        },
                        blendMode: BlendMode.dstIn,
                        child: Image(
                          image: dreamUpImage!,
                          height: MediaQuery.of(context).size.width,
                          width: MediaQuery.of(context).size.width,
                          fit: BoxFit.fill,
                          gaplessPlayback: true,
                        ),
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black54,
                              Colors.transparent,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [
                              0,
                              0.5,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )
        : SizedBox.expand(
            child: Container(
              color: Colors.white,
            ),
          );
  }
}
