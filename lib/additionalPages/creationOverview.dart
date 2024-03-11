import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:decorated_icon/decorated_icon.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:friendivity/additionalPages/dreamUpDetail.dart';
import 'package:image/image.dart' as img;
import 'package:just_audio/just_audio.dart' as justAudio;
import 'package:path_provider/path_provider.dart';

import '../main.dart';
import '../utils/audioWidgets.dart';
import '../utils/imageEditingIsolate.dart';

Map creatorInfo = {};
List creatorWishes = [];

class CreationOverview extends StatefulWidget {
  final Map<String, dynamic> dreamUpData;
  final File? vibeImage;
  final File? audioDescription;

  const CreationOverview({
    Key? key,
    required this.dreamUpData,
    this.vibeImage,
    this.audioDescription,
  }) : super(key: key);

  @override
  State<CreationOverview> createState() => _CreationOverviewState();
}

class _CreationOverviewState extends State<CreationOverview>
    with TickerProviderStateMixin {
  final currentUser = FirebaseAuth.instance.currentUser?.uid;

  bool loading = false;

  int counter = 0;

  bool liked = false;

  bool hasKeyQuestions = true;

  bool closing = true;

  final scrollController = ScrollController();

  Future getCreatorInfoContent() async {
    loading = true;

    var creator = currentUser;

    var userDoc =
        await FirebaseFirestore.instance.collection('users').doc(creator).get();

    creatorInfo = userDoc.data() ?? {};

    print('got creator info');

    var userWishes = await FirebaseFirestore.instance
        .collection('vibes')
        .where('creator', isEqualTo: creator)
        .orderBy('createdOn', descending: true)
        .get();

    for (var doc in userWishes.docs) {
      var data = doc.data();

      var existing = creatorWishes
          .firstWhereOrNull((element) => element['id'] == data['id']);

      if (existing == null) {
        creatorWishes.add(data);
      }
    }

    print('got creator wishes');

    loading = false;
  }

  GlobalKey titleKey = GlobalKey();
  Size? titleSize;
  GlobalKey textKey = GlobalKey();
  GlobalKey scrollerKey = GlobalKey();

  bool needsScroller = false;

  bool descriptionExpanded = false;

  int tabIndex = 0;

  bool showFontSlider = false;

  late DraggableScrollableController connectDragController;
  late DraggableScrollableController profileDragController;

  double connectInitSize = 0;
  double profileInitSize = 0;

  double currentSheetHeight = 0;

  bool uploading = false;

  List<Map<String, dynamic>> contactInfo = [];
  Map<String, dynamic> answerContent = {};

  bool showPopUp = false;

  bool myDreamUp = false;

  bool lovePremium = false;

  String city = '';

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

    if (widget.dreamUpData['type'] == 'Date' ||
        widget.dreamUpData['type'] == 'Beziehung') {
      print(widget.dreamUpData['type']);

      lovePremium = true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      var titleContext = titleKey.currentContext;
      var textContext = textKey.currentContext;
      var scrollContext = scrollerKey.currentContext;

      if (titleContext != null) {
        titleSize = titleContext.size;
      }

      if (textContext != null && scrollContext != null) {
        var textSize = textContext.size;
        var scrollSize = scrollContext.size;

        if (textSize!.height > scrollSize!.height) {
          needsScroller = true;

          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    profileDragController.dispose();
    connectDragController.dispose();

    scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: SizedBox.expand(
        child: Stack(
          children: [
            CreationOverviewBackground(
              dreamUpImage: widget.vibeImage,
              title: widget.dreamUpData['title'],
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Stack(
                children: [
                  Column(
                    children: [
                      AnimatedContainer(
                        duration: currentSheetHeight > 0
                            ? Duration.zero
                            : const Duration(milliseconds: 200),
                        height: descriptionExpanded
                            ? MediaQuery.of(context).padding.top + 55
                            : (MediaQuery.of(context).size.width -
                                        MediaQuery.of(context).padding.top) *
                                    (1 - currentSheetHeight / 0.8) +
                                MediaQuery.of(context).padding.top,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedContainer(
                              key: titleKey,
                              duration: Duration.zero,
                              margin: EdgeInsets.only(
                                left: MediaQuery.of(context).size.width * 0.05,
                              ),
                              width: MediaQuery.of(context).size.width * 0.9,
                              height: currentSheetHeight > 0
                                  ? (MediaQuery.of(context).size.height * 0.2 -
                                          MediaQuery.of(context).padding.top) *
                                      (currentSheetHeight / 0.8)
                                  : null,
                              constraints: BoxConstraints(
                                minHeight: titleSize?.height ?? 0,
                              ),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                widget.dreamUpData['title'],
                                textAlign: TextAlign.start,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black87,
                                      blurRadius: 10,
                                      offset: Offset(1, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.symmetric(
                                horizontal:
                                    MediaQuery.of(context).size.width * 0.1,
                                vertical:
                                    MediaQuery.of(context).size.width * 0.05,
                              ),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () async {
                                      connectDragController.animateTo(
                                        0.8,
                                        duration:
                                            const Duration(milliseconds: 250),
                                        curve: Curves.fastOutSlowIn,
                                      );
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
                                                color: Colors.white
                                                    .withOpacity(0.8),
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
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.08,
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      profileDragController.animateTo(
                                        0.8,
                                        duration:
                                            const Duration(milliseconds: 250),
                                        curve: Curves.fastOutSlowIn,
                                      );

                                      if (creatorInfo.isEmpty) {
                                        await getCreatorInfoContent();
                                      }
                                    },
                                    child: Center(
                                      child: DecoratedIcon(
                                        Icons.person_rounded,
                                        color: Colors.white.withOpacity(0.8),
                                        size: 28,
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
                            Expanded(
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
                                      child: Container(
                                        padding: EdgeInsets.only(
                                          left: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.1,
                                          right: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.1,
                                        ),
                                        child: SizedBox(
                                          key: scrollerKey,
                                          child: SingleChildScrollView(
                                            key: ObjectKey(counter),
                                            controller: scrollController,
                                            padding: EdgeInsets.only(
                                              bottom: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.05,
                                            ),
                                            physics: descriptionExpanded
                                                ? const BouncingScrollPhysics()
                                                : const NeverScrollableScrollPhysics(),
                                            child: Column(
                                              key: textKey,
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  widget.dreamUpData['content'],
                                                  textAlign: TextAlign.start,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.white,
                                                    shadows: [
                                                      Shadow(
                                                        color: Colors.black87,
                                                        blurRadius: 10,
                                                        offset: Offset(1, 1),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                widget.dreamUpData[
                                                            'hashtags'] !=
                                                        null
                                                    ? Container(
                                                        margin: EdgeInsets.only(
                                                          top: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              0.05,
                                                        ),
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child: Wrap(
                                                          spacing: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              0.02,
                                                          runSpacing:
                                                              MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width *
                                                                  0.02,
                                                          children: (widget
                                                                          .dreamUpData[
                                                                      'hashtags']
                                                                  as List<
                                                                      dynamic>)
                                                              .map<Widget>(
                                                                (hashtag) =>
                                                                    Container(
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Colors
                                                                        .white,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            200),
                                                                  ),
                                                                  padding:
                                                                      EdgeInsets
                                                                          .symmetric(
                                                                    horizontal: MediaQuery.of(context)
                                                                            .size
                                                                            .width *
                                                                        0.02,
                                                                    vertical: MediaQuery.of(context)
                                                                            .size
                                                                            .width *
                                                                        0.01,
                                                                  ),
                                                                  child: Text(
                                                                    hashtag,
                                                                    style:
                                                                        TextStyle(
                                                                      fontSize:
                                                                          16,
                                                                      color: Colors
                                                                          .black
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
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: WishAudioPlayer(
                                        isFile: true,
                                        source: widget.audioDescription!.path,
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
                                    padding: EdgeInsets.symmetric(
                                      vertical:
                                          MediaQuery.of(context).size.width *
                                              0.025,
                                    ),
                                    color: Colors.transparent,
                                    child: Text(
                                      descriptionExpanded
                                          ? 'read less'
                                          : 'read more',
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
                            Center(
                              child: Container(
                                margin: EdgeInsets.only(
                                  top: MediaQuery.of(context).size.width * 0.05,
                                  bottom:
                                      MediaQuery.of(context).size.width * 0.1,
                                ),
                                width: MediaQuery.of(context).size.width * 0.8,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: () async {
                                        if (!loading) {
                                          showDialog(
                                            context: context,
                                            builder: (context) => Dialog(
                                              insetPadding: EdgeInsets.all(
                                                MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.05,
                                              ),
                                              child: Container(
                                                padding: EdgeInsets.all(
                                                  MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.05,
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const CircularProgressIndicator(),
                                                    SizedBox(
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.03,
                                                    ),
                                                    const Text(
                                                      'Dein DreamUp wird hochgeladen',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );

                                          loading = true;

                                          if (!lovePremium) {
                                            var vibe = FirebaseFirestore
                                                .instance
                                                .collection('vibes')
                                                .doc();

                                            var id = vibe.id;

                                            String imageLink = '';

                                            widget.dreamUpData.addAll({
                                              'id': id,
                                              'fake': false,
                                            });

                                            if (widget.vibeImage != null) {
                                              try {
                                                await FirebaseStorage.instance
                                                    .ref('vibeMedia/images/$id')
                                                    .putFile(widget.vibeImage!);
                                              } on FirebaseException catch (e) {
                                                print(e);
                                              }

                                              imageLink = await FirebaseStorage
                                                  .instance
                                                  .ref('vibeMedia/images/$id')
                                                  .getDownloadURL();

                                              widget.dreamUpData.addAll({
                                                'imageLink': imageLink,
                                              });
                                            } else {
                                              imageLink =
                                                  'https://firebasestorage.googleapis.com/v0/b/activities-with-friends.appspot.com/o/placeholderImages%2FDreamUpPlaceholderImage.jpg?alt=media&token=5f710f4b-0831-4cf2-9ad0-2e39f6d70f2b';

                                              widget.dreamUpData.addAll({
                                                'imageLink':
                                                    'https://firebasestorage.googleapis.com/v0/b/activities-with-friends.appspot.com/o/placeholderImages%2FDreamUpPlaceholderImage.jpg?alt=media&token=5f710f4b-0831-4cf2-9ad0-2e39f6d70f2b'
                                              });
                                            }

                                            if (widget
                                                    .dreamUpData['hashtags'] !=
                                                null) {
                                              var hashtags = widget
                                                  .dreamUpData['hashtags'];

                                              for (var hashtag in hashtags) {
                                                var docs =
                                                    await FirebaseFirestore
                                                        .instance
                                                        .collection('hashtags')
                                                        .where('hashtag',
                                                            isEqualTo: hashtag)
                                                        .get();

                                                if (docs.docs.isNotEmpty) {
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('hashtags')
                                                      .doc(docs.docs.first.id)
                                                      .update(
                                                    {
                                                      'useCount':
                                                          FieldValue.increment(
                                                              1),
                                                    },
                                                  );
                                                } else {
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('hashtags')
                                                      .doc()
                                                      .set(
                                                    {
                                                      'useCount': 1,
                                                      'hashtag': hashtag,
                                                      'start': hashtag[1],
                                                      'content':
                                                          hashtag.substring(1),
                                                    },
                                                  );
                                                }
                                              }
                                            }

                                            var currentUser = FirebaseAuth
                                                .instance.currentUser?.uid;

                                            widget.dreamUpData.addAll(
                                              {
                                                'creator': currentUser,
                                                'creatorBirthday':
                                                    CurrentUser.birthday!,
                                                'creatorGender':
                                                    CurrentUser.gender!,
                                                'createdOn': DateTime.now(),
                                              },
                                            );

                                            String audioLink = '';

                                            if (widget.audioDescription !=
                                                null) {
                                              try {
                                                await FirebaseStorage.instance
                                                    .ref('vibeMedia/audios/$id')
                                                    .putFile(
                                                      widget.audioDescription!,
                                                      SettableMetadata(
                                                        contentType:
                                                            'audio/x-m4a',
                                                      ),
                                                    );
                                              } on FirebaseException catch (e) {
                                                print(e);

                                                Fluttertoast.showToast(
                                                    msg: 'error: $e');
                                              }

                                              audioLink = await FirebaseStorage
                                                  .instance
                                                  .ref('vibeMedia/audios/$id')
                                                  .getDownloadURL();

                                              final player =
                                                  justAudio.AudioPlayer();
                                              var duration = await player
                                                  .setFilePath(widget
                                                      .audioDescription!.path);

                                              widget.dreamUpData.addAll(
                                                {
                                                  'audioLink': audioLink,
                                                  'audioDuration':
                                                      duration!.inSeconds,
                                                },
                                              );
                                            }

                                            if (widget.dreamUpData[
                                                        'keyQuestions'] !=
                                                    null &&
                                                widget
                                                    .dreamUpData['keyQuestions']
                                                    .isNotEmpty) {
                                              widget.dreamUpData['keyQuestions']
                                                  .remove(
                                                      'I want to add a new question!');

                                              widget.dreamUpData.addAll({
                                                'keyQuestions':
                                                    FieldValue.arrayUnion(
                                                        widget.dreamUpData[
                                                            'keyQuestions'])
                                              });
                                            }

                                            if (city != '') {
                                              widget.dreamUpData
                                                  .addAll({'city': city});
                                            } else {
                                              widget.dreamUpData
                                                  .addAll({'city': 'Berlin'});
                                            }

                                            var splitTitle = widget
                                                .dreamUpData['title']
                                                .toLowerCase()
                                                .split(' ');

                                            List<String> searchCharacters = [];

                                            for (var split in splitTitle) {
                                              var characters =
                                                  split.trim().split('');

                                              String previous = '';

                                              for (int i = 0;
                                                  i < characters.length;
                                                  i++) {
                                                String entry =
                                                    previous + characters[i];

                                                searchCharacters.add(entry);

                                                previous = entry;
                                              }
                                            }

                                            widget.dreamUpData.addAll({
                                              'searchCharacters':
                                                  searchCharacters
                                            });

                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(FirebaseAuth
                                                    .instance.currentUser?.uid)
                                                .update(
                                              {
                                                'createdVibes':
                                                    FieldValue.arrayUnion(
                                                  [
                                                    vibe.id,
                                                  ],
                                                ),
                                              },
                                            );

                                            CurrentUser().saveUserInformation();

                                            await vibe
                                                .set(widget.dreamUpData)
                                                .then((value) {
                                              Fluttertoast.showToast(
                                                msg: 'DreamUp veröffentlicht!',
                                              );
                                            });

                                            Navigator.pop(context);

                                            loading = false;

                                            setState(() {});

                                            Navigator.pop(context, true);
                                          } else {
                                            var vibe = FirebaseFirestore
                                                .instance
                                                .collection('vibes')
                                                .doc();

                                            var id = vibe.id;

                                            String imageLink = '';

                                            widget.dreamUpData.addAll({
                                              'id': id,
                                              'fake': false,
                                            });

                                            if (widget.vibeImage != null) {
                                              try {
                                                await FirebaseStorage.instance
                                                    .ref('vibeMedia/images/$id')
                                                    .putFile(widget.vibeImage!);
                                              } on FirebaseException catch (e) {
                                                print(e);
                                              }

                                              imageLink = await FirebaseStorage
                                                  .instance
                                                  .ref('vibeMedia/images/$id')
                                                  .getDownloadURL();

                                              widget.dreamUpData.addAll({
                                                'imageLink': imageLink,
                                              });
                                            } else {
                                              imageLink =
                                                  CurrentUser.imageLink!;

                                              widget.dreamUpData.addAll({
                                                'imageLink': imageLink,
                                              });
                                            }

                                            if (widget
                                                    .dreamUpData['hashtags'] !=
                                                null) {
                                              var hashtags = widget
                                                  .dreamUpData['hashtags'];

                                              for (var hashtag in hashtags) {
                                                var docs =
                                                    await FirebaseFirestore
                                                        .instance
                                                        .collection('hashtags')
                                                        .where('hashtag',
                                                            isEqualTo: hashtag)
                                                        .get();

                                                if (docs.docs.isNotEmpty) {
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('hashtags')
                                                      .doc(docs.docs.first.id)
                                                      .update(
                                                    {
                                                      'useCount':
                                                          FieldValue.increment(
                                                              1),
                                                    },
                                                  );
                                                } else {
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('hashtags')
                                                      .doc()
                                                      .set(
                                                    {
                                                      'useCount': 1,
                                                      'hashtag': hashtag,
                                                      'start': hashtag[1],
                                                      'content':
                                                          hashtag.substring(1),
                                                    },
                                                  );
                                                }
                                              }
                                            }

                                            var currentUser = FirebaseAuth
                                                .instance.currentUser?.uid;

                                            widget.dreamUpData.addAll(
                                              {
                                                'creator': currentUser,
                                                'createdOn': DateTime.now(),
                                                'creatorBirthday':
                                                    CurrentUser.birthday!,
                                                'creatorGender':
                                                    CurrentUser.gender!,
                                                'genderPrefs':
                                                    CurrentUser.genderPrefs,
                                              },
                                            );

                                            String audioLink = '';

                                            if (widget.audioDescription !=
                                                null) {
                                              try {
                                                await FirebaseStorage.instance
                                                    .ref('vibeMedia/audios/$id')
                                                    .putFile(
                                                      widget.audioDescription!,
                                                      SettableMetadata(
                                                        contentType:
                                                            'audio/x-m4a',
                                                      ),
                                                    );
                                              } on FirebaseException catch (e) {
                                                print(e);

                                                Fluttertoast.showToast(
                                                    msg: 'error: $e');
                                              }

                                              audioLink = await FirebaseStorage
                                                  .instance
                                                  .ref('vibeMedia/audios/$id')
                                                  .getDownloadURL();

                                              final player =
                                                  justAudio.AudioPlayer();
                                              var duration = await player
                                                  .setFilePath(widget
                                                      .audioDescription!.path);

                                              widget.dreamUpData.addAll(
                                                {
                                                  'audioLink': audioLink,
                                                  'audioDuration':
                                                      duration!.inSeconds,
                                                },
                                              );
                                            }

                                            if (widget.dreamUpData[
                                                        'keyQuestions'] !=
                                                    null &&
                                                widget
                                                    .dreamUpData['keyQuestions']
                                                    .isNotEmpty) {
                                              widget.dreamUpData['keyQuestions']
                                                  .remove(
                                                      'I want to add a new question!');

                                              widget.dreamUpData.addAll({
                                                'keyQuestions':
                                                    FieldValue.arrayUnion(
                                                        widget.dreamUpData[
                                                            'keyQuestions'])
                                              });
                                            }

                                            if (city != '') {
                                              widget.dreamUpData
                                                  .addAll({'city': city});
                                            } else {
                                              widget.dreamUpData
                                                  .addAll({'city': 'Berlin'});
                                            }

                                            var splitTitle = widget
                                                .dreamUpData['title']
                                                .toLowerCase()
                                                .split(' ');

                                            List<String> searchCharacters = [];

                                            for (var split in splitTitle) {
                                              var characters =
                                                  split.trim().split('');

                                              String previous = '';

                                              for (int i = 0;
                                                  i < characters.length;
                                                  i++) {
                                                String entry =
                                                    previous + characters[i];

                                                searchCharacters.add(entry);

                                                previous = entry;
                                              }
                                            }

                                            widget.dreamUpData.addAll({
                                              'searchCharacters':
                                                  searchCharacters
                                            });

                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(FirebaseAuth
                                                    .instance.currentUser?.uid)
                                                .update(
                                              {
                                                'createdVibes':
                                                    FieldValue.arrayUnion(
                                                  [
                                                    vibe.id,
                                                  ],
                                                ),
                                              },
                                            );

                                            CurrentUser().saveUserInformation();

                                            await vibe
                                                .set(widget.dreamUpData)
                                                .then((value) {
                                              Fluttertoast.showToast(
                                                msg: 'veröffentlicht!',
                                              );
                                            });

                                            Navigator.pop(context);

                                            loading = false;

                                            setState(() {});

                                            Navigator.pop(context, true);
                                          }
                                        }
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.blueAccent,
                                          borderRadius: BorderRadius.circular(
                                            MediaQuery.of(context).size.width *
                                                0.05,
                                          ),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          vertical: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.02,
                                          horizontal: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.03,
                                        ),
                                        child: const Text(
                                          'Veröffentlichen',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.pop(context, false);
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withOpacity(0.6),
                                          borderRadius: BorderRadius.circular(
                                            MediaQuery.of(context).size.width *
                                                0.05,
                                          ),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          vertical: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.02,
                                          horizontal: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.03,
                                        ),
                                        child: const Text(
                                          'Bearbeiten',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.width * 0.025,
                            ),
                          ],
                        ),
                      ),
                    ],
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
            Positioned.fill(
              child: NotificationListener<DraggableScrollableNotification>(
                onNotification: (notification) {
                  setState(() {
                    currentSheetHeight = notification.extent;
                    profileInitSize = notification.extent;
                  });

                  if (notification.extent <= 0.1 && profileInitSize != 0) {
                    profileInitSize = 0;
                    currentSheetHeight = 0;

                    print('called?');
                  }

                  return true;
                },
                child: DraggableScrollableSheet(
                  maxChildSize: 0.8,
                  minChildSize: 0,
                  initialChildSize: profileInitSize,
                  controller: profileDragController,
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
                        padding: EdgeInsets.fromLTRB(
                          MediaQuery.of(context).size.width * 0.05,
                          MediaQuery.of(context).size.width * 0.1,
                          MediaQuery.of(context).size.width * 0.05,
                          0,
                        ),
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        controller: scrollController,
                        children: [
                          creatorInfo.isNotEmpty
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'über mich',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.width *
                                              0.05,
                                    ),
                                    Text(
                                      creatorInfo['bio'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 18,
                                      ),
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(
                                        top: MediaQuery.of(context).size.width *
                                            0.05,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          creatorInfo['blackHumor'] != null
                                              ? creatorInfo['blackHumor'] ==
                                                      'yes'
                                                  ? const Text(
                                                      'Ich bin für Schwarzen Humor zu haben.',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                      ),
                                                    )
                                                  : const Text(
                                                      'Schwarzer Humor ist nicht so mein Ding.',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                      ),
                                                    )
                                              : Container(),
                                          creatorInfo['criticizing'] != null
                                              ? creatorInfo['criticizing'] ==
                                                      'yes'
                                                  ? const Text(
                                                      'In einer Freundschaft versuche ich immer konstruktive Kritik zu üben.',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                      ),
                                                    )
                                                  : const Text(
                                                      'Mein Vorsatz ist: leben und leben lassen.',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                      ),
                                                    )
                                              : Container(),
                                          creatorInfo['initiative'] != null
                                              ? creatorInfo['initiative'] ==
                                                      'yes'
                                                  ? const Text(
                                                      'Wahrscheinlich werde ich dich von mir aus anschreiben.',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                      ),
                                                    )
                                                  : const Text(
                                                      'Ich bin zwar etwas schüchtern, aber du kannst mich trotzdem gern anschreiben.',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                      ),
                                                    )
                                              : Container(),
                                          creatorInfo['replyBehaviour'] != null
                                              ? creatorInfo['replyBehaviour'] ==
                                                      'fast'
                                                  ? const Text(
                                                      'Wenn du mir schreibst, antworte ich dir so schnell wie möglich.',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                      ),
                                                    )
                                                  : const Text(
                                                      'Es kann sein, dass du auf eine Antwort von mir eine Weile warten musst.',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                      ),
                                                    )
                                              : Container(),
                                          creatorInfo['personalTitle'] != null
                                              ? creatorInfo['personalTitle'] !=
                                                      ''
                                                  ? Text(
                                                      'Ich würde mich selbst als "${creatorInfo['personalTitle']}" bezeichnen.',
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                      ),
                                                    )
                                                  : Container()
                                              : Container(),
                                          creatorInfo['redFlags'] != null
                                              ? creatorInfo['redFlags']
                                                      .isNotEmpty
                                                  ? Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        const Text(
                                                          'Das sind meine persönlichen Red Flags:',
                                                          style: TextStyle(
                                                            fontSize: 18,
                                                          ),
                                                        ),
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: creatorInfo[
                                                                  'redFlags']
                                                              .map<Widget>(
                                                                (flag) => Text(
                                                                  '- $flag',
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        18,
                                                                  ),
                                                                ),
                                                              )
                                                              .toList(),
                                                        ),
                                                      ],
                                                    )
                                                  : Container()
                                              : Container(),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.width *
                                              0.075,
                                    ),
                                    GridView.count(
                                      shrinkWrap: true,
                                      crossAxisCount: 3,
                                      padding: EdgeInsets.zero,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      crossAxisSpacing:
                                          MediaQuery.of(context).size.width *
                                              0.05,
                                      mainAxisSpacing:
                                          MediaQuery.of(context).size.width *
                                              0.05,
                                      children:
                                          creatorWishes.map<Widget>((vibe) {
                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              changePage(
                                                DreamUpDetailPage(
                                                  dreamUpData: vibe,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.02,
                                              ),
                                              image: DecorationImage(
                                                image:
                                                    CachedNetworkImageProvider(
                                                  vibe['imageLink'],
                                                ),
                                                fit: BoxFit.fill,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    )
                                  ],
                                )
                              : loading
                                  ? Container(
                                      margin: EdgeInsets.only(
                                        top: MediaQuery.of(context).size.width *
                                            0.1,
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  : Container(),
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
          ],
        ),
      ),
    );
  }
}

class CreationOverviewBackground extends StatefulWidget {
  final File? dreamUpImage;
  final String title;

  const CreationOverviewBackground({
    required this.dreamUpImage,
    required this.title,
    Key? key,
  }) : super(key: key);

  @override
  State<CreationOverviewBackground> createState() =>
      _CreationOverviewBackgroundState();
}

class _CreationOverviewBackgroundState
    extends State<CreationOverviewBackground> {
  Future<String> get appDirectory async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  File? blurredAsset;

  bool noCustomImage = false;

  @override
  void initState() {
    super.initState();

    if (widget.dreamUpImage == null) {
      noCustomImage = true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (noCustomImage) {
        var path = await appDirectory;

        final byteData =
            await rootBundle.load('assets/images/ucImages/ostseeQuadrat.jpg');

        File assetFile = await File('$path/assetFile/${widget.title}.jpg')
            .create(recursive: true);

        File compressedFile =
            await File('$path/compressedImage/${widget.title}.jpg')
                .create(recursive: true);

        await assetFile.writeAsBytes(byteData.buffer
            .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

        var compressed = await FlutterImageCompress.compressAndGetFile(
          assetFile.path,
          compressedFile.path,
          minHeight: 200,
          minWidth: 200,
          quality: 0,
        );

        File imageFile = File(compressed!.path);

        File file = await File('$path/blurredImage/${widget.title}')
            .create(recursive: true);

        var uiImage = await compute(blurImage, imageFile);

        file.writeAsBytesSync(
          img.encodePng(uiImage),
          mode: FileMode.append,
        );

        blurredAsset = file;

        setState(() {});
      } else {
        var path = await appDirectory;

        var now = DateTime.now();

        File compressedFile = await File('$path/compressedImage/$now.jpg')
            .create(recursive: true);

        var compressed = await FlutterImageCompress.compressAndGetFile(
          widget.dreamUpImage!.path,
          compressedFile.path,
          minHeight: 200,
          minWidth: 200,
          quality: 0,
        );

        File imageFile = File(compressed!.path);

        File file =
            await File('$path/blurredImage/$now').create(recursive: true);

        var uiImage = await compute(blurImage, imageFile);

        file.writeAsBytesSync(
          img.encodePng(uiImage),
          mode: FileMode.append,
        );

        blurredAsset = file;

        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return blurredAsset != null
        ? Stack(
            children: [
              Positioned(
                top: 0,
                child: Column(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.width,
                      width: MediaQuery.of(context).size.width,
                      child: Image.file(
                        blurredAsset!,
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
                          child: Image.file(
                            blurredAsset!,
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
                        child: noCustomImage
                            ? Image.asset(
                                'assets/images/ucImages/ostseeQuadrat.jpg',
                                height: MediaQuery.of(context).size.width,
                                width: MediaQuery.of(context).size.width,
                                fit: BoxFit.fill,
                                gaplessPlayback: true,
                              )
                            : Image.file(
                                widget.dreamUpImage!,
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
