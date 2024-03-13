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
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:friendivity/additionalPages/dreamUpDetail.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../main.dart';
import '../utils/imageEditingIsolate.dart';

Map creatorInfo = {};
List creatorWishes = [];

class EditOverview extends StatefulWidget {
  final Map<String, dynamic> dreamUpData;
  final Image dreamUpImage;
  final Image blurredImage;
  final File? newImage;
  final List<String> newHashtags;

  const EditOverview({
    Key? key,
    required this.dreamUpData,
    required this.dreamUpImage,
    required this.blurredImage,
    required this.newImage,
    required this.newHashtags,
  }) : super(key: key);

  @override
  State<EditOverview> createState() => _EditOverviewState();
}

class _EditOverviewState extends State<EditOverview>
    with SingleTickerProviderStateMixin {
  final currentUser = FirebaseAuth.instance.currentUser?.uid;

  int counter = 0;

  bool hasKeyQuestions = true;

  final scrollController = ScrollController();

  bool loading = false;

  Future getCreatorInfoContent() async {
    loading = true;

    var creator = widget.dreamUpData['creator'];

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

  late DraggableScrollableController connectDragController;
  late DraggableScrollableController profileDragController;

  double connectInitSize = 0;
  double profileInitSize = 0;

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
            'type': 'text',
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
        'new': true,
      });
    } else {
      print('chat is not there');

      var requestChat = FirebaseFirestore.instance.collection('chats').doc();

      Map<String, dynamic> chatInfo = {
        'id': requestChat.id,
        'images': {
          currentUser: CurrentUser.imageLink,
          widget.dreamUpData['creator']: widget.dreamUpData['imageLink'],
        },
        'lastAction': DateTime.now(),
        'lastSender': currentUser,
        'lastLogin': {
          currentUser: DateTime.now(),
          widget.dreamUpData['creator']: DateTime.now(),
        },
        'names': [
          widget.dreamUpData['title'],
          CurrentUser.name,
        ],
        'new': true,
        'onlineUsers': [],
        'participants': [
          widget.dreamUpData['creator'],
        ],
        'isRequest': true,
      };

      await requestChat.set(chatInfo);

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
            'type': 'text',
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
    }

    Fluttertoast.showToast(msg: 'request sent');

    contactInfo.clear();

    uploading = false;
  }

  bool showPopUp = false;

  Future<String> get appDirectory async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  @override
  void initState() {
    super.initState();

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

    creatorInfo.clear();
    creatorWishes.clear();

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
              widget.newImage == null
                  ? DreamUpDetailBackground(
                      dreamUpData: widget.dreamUpData,
                    )
                  : EditOverviewBackground(
                      imageFile: widget.newImage,
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
                                  left:
                                      MediaQuery.of(context).size.width * 0.05,
                                ),
                                width: MediaQuery.of(context).size.width * 0.9,
                                height: currentSheetHeight > 0
                                    ? (MediaQuery.of(context).size.height *
                                                0.2 -
                                            MediaQuery.of(context)
                                                .padding
                                                .top) *
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
                                child: GestureDetector(
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
                                  child: ShaderMask(
                                    shaderCallback: (rect) {
                                      return LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: const [
                                          Colors.black,
                                          Colors.transparent,
                                        ],
                                        stops: [
                                          descriptionExpanded || !needsScroller
                                              ? 1
                                              : 0.1,
                                          1,
                                        ],
                                      ).createShader(rect);
                                    },
                                    blendMode: BlendMode.dstIn,
                                    child: Container(
                                      padding: EdgeInsets.only(
                                        left:
                                            MediaQuery.of(context).size.width *
                                                0.1,
                                        right:
                                            MediaQuery.of(context).size.width *
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
                                              widget.dreamUpData['hashtags'] !=
                                                      null
                                                  ? Container(
                                                      margin: EdgeInsets.only(
                                                        top: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width *
                                                            0.05,
                                                      ),
                                                      alignment:
                                                          Alignment.centerLeft,
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
                                                        children:
                                                            (widget.dreamUpData[
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
                                                                      horizontal:
                                                                          MediaQuery.of(context).size.width *
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
                                                                            .withOpacity(0.8),
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
                                    top: MediaQuery.of(context).size.width *
                                        0.05,
                                    bottom:
                                        MediaQuery.of(context).size.width * 0.1,
                                  ),
                                  width:
                                      MediaQuery.of(context).size.width * 0.8,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      GestureDetector(
                                        onTap: () async {
                                          if (!loading) {
                                            loading = true;

                                            setState(() {});

                                            var id = widget.dreamUpData['id'];

                                            for (var hashtag
                                                in widget.newHashtags) {
                                              var docs = await FirebaseFirestore
                                                  .instance
                                                  .collection('hashtags')
                                                  .where('hashtag',
                                                      isEqualTo: hashtag)
                                                  .get();

                                              if (docs.docs.isNotEmpty) {
                                                await FirebaseFirestore.instance
                                                    .collection('hashtags')
                                                    .doc(docs.docs.first.id)
                                                    .update(
                                                  {
                                                    'useCount':
                                                        FieldValue.increment(1),
                                                  },
                                                );
                                              } else {
                                                await FirebaseFirestore.instance
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

                                            if (widget.newImage != null) {
                                              var oldImage =
                                                  await DefaultCacheManager()
                                                      .getSingleFile(
                                                          widget.dreamUpData[
                                                              'imageLink']);

                                              await oldImage.delete();

                                              if (widget.dreamUpData[
                                                      'imageLink'] !=
                                                  'https://firebasestorage.googleapis.com/v0/b/activities-with-friends.appspot.com/o/placeholderImages%2FDreamUpPlaceholderImage.jpg?alt=media&token=5f710f4b-0831-4cf2-9ad0-2e39f6d70f2b') {
                                                var oldImage = FirebaseStorage
                                                    .instance
                                                    .refFromURL(
                                                        widget.dreamUpData[
                                                            'imageLink']);

                                                await oldImage.delete();
                                              }

                                              String imageLink = '';

                                              try {
                                                await FirebaseStorage.instance
                                                    .ref('vibeMedia/images/$id')
                                                    .putFile(widget.newImage!);
                                              } on FirebaseException catch (e) {
                                                print(e);
                                              }

                                              imageLink = await FirebaseStorage
                                                  .instance
                                                  .ref('vibeMedia/images/$id')
                                                  .getDownloadURL();

                                              widget.dreamUpData['imageLink'] =
                                                  imageLink;

                                              var image =
                                                  CachedNetworkImageProvider(
                                                imageLink,
                                                errorListener: (object) {
                                                  print('image error!');
                                                },
                                              );

                                              await precacheImage(
                                                image,
                                                context,
                                                size: Size(
                                                  MediaQuery.of(context)
                                                      .size
                                                      .width,
                                                  MediaQuery.of(context)
                                                      .size
                                                      .width,
                                                ),
                                              );

                                              var path = await appDirectory;

                                              var isThere = await File(
                                                      '$path/compressedImage/$id.jpg')
                                                  .exists();

                                              if (isThere) {
                                                await File(
                                                        '$path/compressedImage/$id.jpg')
                                                    .delete();
                                              }

                                              File compressedFile = await File(
                                                      '$path/compressedImage/$id.jpg')
                                                  .create(recursive: true);

                                              var cachedImage =
                                                  await DefaultCacheManager()
                                                      .getSingleFile(imageLink);

                                              var compressed =
                                                  await FlutterImageCompress
                                                      .compressAndGetFile(
                                                cachedImage.path,
                                                compressedFile.path,
                                                minHeight: 200,
                                                minWidth: 200,
                                                quality: 0,
                                              );

                                              File imageFile =
                                                  File(compressed!.path);

                                              await File(
                                                      '$path/blurredImage/$id')
                                                  .delete();

                                              File file = await File(
                                                      '$path/blurredImage/$id')
                                                  .create(recursive: true);

                                              var uiImage = await compute(
                                                  blurImage, imageFile);

                                              file.writeAsBytesSync(
                                                img.encodePng(uiImage),
                                                mode: FileMode.append,
                                              );

                                              var blurredImage = Image.file(
                                                file,
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                height: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                              ).image;

                                              await precacheImage(
                                                blurredImage,
                                                context,
                                                size: Size(
                                                  MediaQuery.of(context)
                                                      .size
                                                      .width,
                                                  MediaQuery.of(context)
                                                      .size
                                                      .width,
                                                ),
                                              );

                                              var existing =
                                                  LoadedImages.containsKey(id);

                                              if (existing) {
                                                LoadedImages[id] = image;
                                              } else {
                                                LoadedImages.addAll(
                                                  {
                                                    id: image,
                                                  },
                                                );
                                              }

                                              var exists =
                                                  BlurImages.containsKey(id);

                                              if (exists) {
                                                BlurImages[id] = blurredImage;
                                              } else {
                                                BlurImages.addAll(
                                                  {
                                                    id: blurredImage,
                                                  },
                                                );
                                              }
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

                                            widget.dreamUpData[
                                                    'searchCharacters'] =
                                                searchCharacters;

                                            await FirebaseFirestore.instance
                                                .collection('vibes')
                                                .doc(id)
                                                .update(widget.dreamUpData);

                                            widget.dreamUpData.addAll(
                                              {
                                                'editTime': DateTime.now(),
                                              },
                                            );

                                            await FirebaseFirestore.instance
                                                .collection('edited')
                                                .add(widget.dreamUpData);

                                            loading = false;

                                            Navigator.pop(context);
                                            Navigator.pop(context, true);
                                            Navigator.pop(context);
                                          }
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.blueAccent,
                                            borderRadius: BorderRadius.circular(
                                              MediaQuery.of(context)
                                                      .size
                                                      .width *
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
                                          child: Row(
                                            children: [
                                              const Text(
                                                'Veröffentlichen',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                ),
                                              ),
                                              Visibility(
                                                visible: loading,
                                                child: const SizedBox(
                                                  width: 10,
                                                ),
                                              ),
                                              Visibility(
                                                visible: loading,
                                                child: const SizedBox(
                                                  height: 10,
                                                  width: 10,
                                                  child:
                                                      CircularProgressIndicator(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
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
                                              MediaQuery.of(context)
                                                      .size
                                                      .width *
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                          top: MediaQuery.of(context)
                                                  .size
                                                  .width *
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
                                            creatorInfo['replyBehaviour'] !=
                                                    null
                                                ? creatorInfo[
                                                            'replyBehaviour'] ==
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
                                                ? creatorInfo[
                                                            'personalTitle'] !=
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
                                                                  (flag) =>
                                                                      Text(
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
                                                          vibe['imageLink']),
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
                                          top: MediaQuery.of(context)
                                                  .size
                                                  .width *
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
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
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
            ],
          ),
        ),
      ),
    );
  }
}

class EditOverviewBackground extends StatefulWidget {
  final File? imageFile;

  const EditOverviewBackground({
    required this.imageFile,
    Key? key,
  }) : super(key: key);

  @override
  State<EditOverviewBackground> createState() => _EditOverviewBackgroundState();
}

class _EditOverviewBackgroundState extends State<EditOverviewBackground> {
  Future<String> get appDirectory async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  ImageProvider? blurredImage;
  ImageProvider? dreamUpImage;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      dreamUpImage = Image.file(
        widget.imageFile!,
      ).image;

      var path = await appDirectory;

      File compressedFile =
          await File('$path/compressedImage/${widget.imageFile!.path}.jpg')
              .create(recursive: true);

      var compressed = await FlutterImageCompress.compressAndGetFile(
        widget.imageFile!.path,
        compressedFile.path,
        minHeight: 200,
        minWidth: 200,
        quality: 0,
      );

      File imageFile = File(compressed!.path);

      File file = await File('$path/blurredImage/${widget.imageFile!.path}')
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
