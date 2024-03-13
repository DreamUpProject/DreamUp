import 'dart:io';
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:friendivity/additionalPages/editOverview.dart';
import 'package:friendivity/main.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

//region Global Variables
int maxKeyQuestions = 3;
//endregion

//region UI Logic
class DreamUpEditPage extends StatefulWidget {
  final Map<String, dynamic> dreamUpData;
  final Image dreamUpImage;
  final Image blurredImage;

  const DreamUpEditPage({
    Key? key,
    required this.dreamUpData,
    required this.dreamUpImage,
    required this.blurredImage,
  }) : super(key: key);

  @override
  State<DreamUpEditPage> createState() => _DreamUpEditPageState();
}

class _DreamUpEditPageState extends State<DreamUpEditPage>
    with TickerProviderStateMixin {
  late DraggableScrollableController dragController;

  File? croppedImage;

  String sheetContent = '';

  double dragInitSize = 0;

  late TextEditingController keyQuestionController;
  late FocusNode keyQuestionFocus;

  bool editTitle = false;
  bool editDescription = false;
  bool editRedFlags = false;

  late TextEditingController descriptionEditController;
  late TextEditingController titleEditController;

  late FocusNode descriptionEditFocus;
  late FocusNode titleEditFocus;

  late TextEditingController keyWordController;
  late FocusNode keyWordFocus;

  Future pickImage(bool fromGallery) async {
    final pickedImage = await ImagePicker().pickImage(
      source: fromGallery ? ImageSource.gallery : ImageSource.camera,
    );

    if (pickedImage == null) return;

    final imageTemporary = File(pickedImage.path);

    await cropImage(imageTemporary);
  }

  Future<void> cropImage(File? image) async {
    var cropped = await ImageCropper().cropImage(
      maxHeight: 1080,
      maxWidth: 1080,
      sourcePath: image!.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      aspectRatioPresets: [CropAspectRatioPreset.square],
    );

    setState(() {
      croppedImage = File(cropped!.path);
    });
  }

  void showImageDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.all(
          MediaQuery.of(context).size.width * 0.05,
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.05,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  pickImage(false).then(
                    (value) => Navigator.pop(context),
                  );
                },
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.width * 0.05,
                    bottom: MediaQuery.of(context).size.width * 0.025,
                  ),
                  child: const Text(
                    'Kamera öffnen',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  pickImage(true).then(
                    (value) => Navigator.pop(context),
                  );
                },
                child: Container(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).size.width * 0.05,
                    top: MediaQuery.of(context).size.width * 0.025,
                  ),
                  child: const Text(
                    'Gallerie öffnen',
                    style: TextStyle(
                      fontSize: 18,
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

  List<String> keyQuestions = [];

  int tabIndex = 0;

  late TabController tabController;

  final viewInsets = EdgeInsets.fromWindowPadding(
      WidgetsBinding.instance.window.viewInsets,
      WidgetsBinding.instance.window.devicePixelRatio);

  List<TextEditingController> TextFieldControllers = [];
  List<FocusNode> TextFocuses = [];

  void getTextControllers() {
    for (var question in keyQuestions) {
      final textController = TextEditingController()
        ..addListener(() {
          setState(() {});
        });

      TextFieldControllers.add(textController);

      final textFocus = FocusNode();

      TextFocuses.add(textFocus);
    }

    if (keyQuestions.length < maxKeyQuestions) {
      print('should get one controller');

      keyQuestions.add('I want to add a new question!');

      final textController = TextEditingController()
        ..addListener(() {
          setState(() {});
        });

      TextFieldControllers.add(textController);

      final textFocus = FocusNode();

      TextFocuses.add(textFocus);
    } else {
      print(keyQuestions.length);
    }

    print(keyQuestions.length);
  }

  bool editing = false;

  void updateKeyQuestion(TextEditingController controller) async {
    String newQuestion = controller.text;

    controller.text = '';
    keyQuestions[tabIndex] = newQuestion;

    var questionsCopy = List.from(keyQuestions);

    questionsCopy.remove('I want to add a new question!');

    editing = false;

    setState(() {});
  }

  void addKeyQuestion(TextEditingController controller) async {
    String newQuestion = controller.text;

    controller.text = '';
    keyQuestions.insert(keyQuestions.length - 1, newQuestion);

    if (keyQuestions.length > maxKeyQuestions) {
      keyQuestions.remove('I want to add a new question!');
    }

    tabController.dispose();

    tabIndex = min(2, tabIndex + 1);

    tabController = TabController(
      length: keyQuestions.length,
      vsync: this,
      initialIndex: tabIndex,
    );

    tabController.addListener(() {
      tabIndex = tabController.index;
    });

    if (TextFieldControllers.length < keyQuestions.length) {
      TextFieldControllers.add(TextEditingController());

      final textFocus = FocusNode();

      TextFocuses.add(textFocus);
    }

    setState(() {});

    var questionsCopy = List.from(keyQuestions);

    questionsCopy.remove('I want to add a new question!');

    setState(() {});
  }

  void deleteKeyQuestion(String question) async {
    keyQuestions.remove(question);

    if (keyQuestions.length < maxKeyQuestions &&
        !keyQuestions.contains('I want to add a new question!')) {
      keyQuestions.add('I want to add a new question!');
    }

    tabIndex = max(0, tabIndex - 1);

    tabController.dispose();

    tabController = TabController(
      length: keyQuestions.length,
      vsync: this,
      initialIndex: tabIndex,
    );

    tabController.addListener(() {
      tabIndex = tabController.index;
    });

    setState(() {});
  }

  List<Widget> PanelContent(String sheetContent) {
    if (sheetContent == 'keyWords') {
      return [
        Container(
          padding: EdgeInsets.all(
            MediaQuery.of(context).size.width * 0.05,
          ),
          child: Column(
            children: [
              const Text(
                'Füge Hashtags hinzu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(
                  vertical: MediaQuery.of(context).size.width * 0.05,
                ),
                height: 1,
                color: Colors.black26,
              ),
              widget.dreamUpData['hashtags'] != null
                  ? Wrap(
                      spacing: MediaQuery.of(context).size.width * 0.03,
                      runSpacing: MediaQuery.of(context).size.width * 0.02,
                      children: widget.dreamUpData['hashtags']
                          .map<Widget>(
                            (word) => GestureDetector(
                              onTap: () {
                                widget.dreamUpData['hashtags'].remove(word);

                                setState(() {});
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(
                                    MediaQuery.of(context).size.width * 0.1,
                                  ),
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical:
                                      MediaQuery.of(context).size.width * 0.02,
                                  horizontal:
                                      MediaQuery.of(context).size.width * 0.03,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      word,
                                      style: const TextStyle(
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          0.01,
                                    ),
                                    const Icon(
                                      Icons.cancel_outlined,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    )
                  : Container(),
              TextField(
                controller: keyWordController,
                focusNode: keyWordFocus,
                onTap: () {
                  keyWordController.text = '#';
                },
                onChanged: (text) {
                  if (text.isEmpty) {
                    FocusManager.instance.primaryFocus?.unfocus();
                  }
                },
                enableSuggestions: true,
                autocorrect: true,
                textCapitalization: TextCapitalization.none,
                decoration: const InputDecoration(
                  hintText: '#hashtag',
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.width * 0.05,
              ),
              StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('hashtags')
                    .orderBy('hashtag', descending: false)
                    .snapshots(),
                builder:
                    (context, AsyncSnapshot<QuerySnapshot> hashtagSnapshot) {
                  if (hashtagSnapshot.hasData) {
                    var hashtags = hashtagSnapshot.data!.docs;

                    bool matching = false;

                    for (var doc in hashtags) {
                      var data = doc.data() as Map;

                      if (data['hashtag'].contains(keyWordController.text)) {
                        matching = true;

                        break;
                      }
                    }

                    if (hashtags.isNotEmpty &&
                        matching &&
                        keyWordController.text.length > 1 &&
                        keyWordController.text.startsWith('#')) {
                      return ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: hashtags.length,
                        physics: const BouncingScrollPhysics(),
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          var thisHashtag = hashtags[index];

                          return Visibility(
                            visible: thisHashtag['hashtag']
                                .contains(keyWordController.text),
                            child: GestureDetector(
                              onTap: () {
                                widget.dreamUpData['hashtags']
                                    .add(thisHashtag['hashtag']);

                                keyWordController.text = '#';

                                keyWordController.selection =
                                    TextSelection.fromPosition(TextPosition(
                                        offset: keyWordController.text.length));

                                setState(() {});
                              },
                              child: Container(
                                color: Colors.white,
                                height: MediaQuery.of(context).size.width * 0.1,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      thisHashtag['hashtag'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    } else if (!matching &&
                        keyWordController.text.length > 1 &&
                        keyWordController.text.startsWith('#')) {
                      return GestureDetector(
                        onTap: () async {
                          var entry = keyWordController.text;

                          if (widget.dreamUpData['hashtags'] == null) {
                            widget.dreamUpData.addAll(
                              {
                                'hashtags': [],
                              },
                            );
                          }

                          widget.dreamUpData['hashtags'].add(entry);
                          newHashtags.add(entry);

                          keyWordController.text = '#';

                          keyWordController.selection =
                              TextSelection.fromPosition(TextPosition(
                                  offset: keyWordController.text.length));

                          setState(() {});

                          var newKeyWord = FirebaseFirestore.instance
                              .collection('hashtags')
                              .doc();

                          await newKeyWord.set({
                            'hashtag': entry,
                            'start': entry[1],
                            'content': entry.substring(1),
                          });
                        },
                        child: Container(
                          color: Colors.white,
                          height: MediaQuery.of(context).size.width * 0.1,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                keyWordController.text,
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                              const Text(
                                'Hinzufügen',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.blueAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      return Container();
                    }
                  } else if (hashtagSnapshot.hasError) {
                    return Text(
                        'An Error has occured: ${hashtagSnapshot.error}');
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ];
    } else if (sheetContent == 'keyQuestions') {
      return [
        const Text(
          'Stelle eine Schlüsselfrage',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          margin: EdgeInsets.only(
            top: MediaQuery.of(context).size.width * 0.05,
          ),
          height: 1,
          color: Colors.black26,
        ),
        Row(
          children: [
            Expanded(
              child: Container(),
            ),
            GestureDetector(
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();

                dragController
                    .animateTo(
                  0,
                  duration: const Duration(
                    milliseconds: 250,
                  ),
                  curve: Curves.fastOutSlowIn,
                )
                    .then((value) {
                  dragInitSize = 0;

                  sheetContent = '';

                  FocusManager.instance.primaryFocus?.unfocus();

                  setState(() {});
                });
              },
              child: Container(
                color: Colors.transparent,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.width * 0.05,
                  left: MediaQuery.of(context).size.width * 0.05,
                ),
                child: const Text(
                  'Fertig',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.1,
          child: TabBar(
            controller: tabController,
            tabs: keyQuestions.map<Widget>(
              (question) {
                bool add = false;

                if (question == 'I want to add a new question!') {
                  add = true;
                }

                return SizedBox.expand(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.25,
                    child: Center(
                      child: Icon(
                        !add ? Icons.key_rounded : Icons.add_rounded,
                        color: !add ? Colors.black54 : Colors.black26,
                      ),
                    ),
                  ),
                );
              },
            ).toList(),
            indicatorColor: Colors.black26,
          ),
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: TabBarView(
            controller: tabController,
            children: keyQuestions.map<Widget>(
              (question) {
                bool add = false;

                if (question == 'I want to add a new question!') {
                  add = true;
                }

                int index = keyQuestions.indexOf(question);

                return Container(
                  color: Colors.transparent,
                  height: MediaQuery.of(context).size.height * 0.7,
                  alignment: Alignment.topCenter,
                  child: AnimatedContainer(
                    duration: Duration.zero,
                    height: MediaQuery.of(context).size.height * 0.8 -
                        viewInsets.bottom,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.05,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.1,
                          ),
                          editing || add
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(7),
                                          color: Colors.black.withOpacity(0.1),
                                        ),
                                        margin: EdgeInsets.only(
                                          top: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.02,
                                          bottom: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.02,
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.03,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                enableSuggestions: true,
                                                autocorrect: true,
                                                textCapitalization:
                                                    TextCapitalization
                                                        .sentences,
                                                controller:
                                                    TextFieldControllers[index],
                                                onChanged: (text) {
                                                  setState(() {});
                                                },
                                                focusNode: TextFocuses[index],
                                                decoration: InputDecoration(
                                                  border: InputBorder.none,
                                                  hintText: !add
                                                      ? question
                                                      : 'Neue Schlüsselfrage',
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                TextFieldControllers[index]
                                                    .clear();

                                                setState(() {});
                                              },
                                              child: AnimatedContainer(
                                                duration: Duration(
                                                  milliseconds: animationSpeed,
                                                ),
                                                color: Colors.transparent,
                                                width:
                                                    TextFieldControllers[index]
                                                            .text
                                                            .isNotEmpty
                                                        ? 20
                                                        : 0,
                                                margin: EdgeInsets.only(
                                                  left: TextFieldControllers[
                                                              index]
                                                          .text
                                                          .isNotEmpty
                                                      ? MediaQuery.of(context)
                                                              .size
                                                              .width *
                                                          0.01
                                                      : 0,
                                                ),
                                                child: AnimatedOpacity(
                                                  duration: Duration(
                                                    milliseconds:
                                                        (animationSpeed * 0.5)
                                                            .toInt(),
                                                  ),
                                                  opacity: TextFieldControllers[
                                                              index]
                                                          .text
                                                          .isNotEmpty
                                                      ? 1
                                                      : 0,
                                                  child: const Icon(
                                                    Icons.cancel_outlined,
                                                    size: 20,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        add
                                            ? addKeyQuestion(
                                                TextFieldControllers[index])
                                            : updateKeyQuestion(
                                                TextFieldControllers[index]);

                                        FocusManager.instance.primaryFocus
                                            ?.unfocus();
                                      },
                                      child: AnimatedContainer(
                                        duration: Duration(
                                          milliseconds: animationSpeed,
                                        ),
                                        height: 50,
                                        width: TextFieldControllers[index]
                                                    .text
                                                    .isNotEmpty &&
                                                TextFieldControllers[index]
                                                        .text
                                                        .trim() !=
                                                    question.trim()
                                            ? 50
                                            : 0,
                                        color: Colors.transparent,
                                        padding: EdgeInsets.only(
                                          left: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.02,
                                        ),
                                        child: Center(
                                          child: AnimatedOpacity(
                                            duration: Duration(
                                              milliseconds: animationSpeed,
                                            ),
                                            opacity: TextFieldControllers[index]
                                                        .text
                                                        .isNotEmpty &&
                                                    TextFieldControllers[index]
                                                            .text
                                                            .trim() !=
                                                        question.trim()
                                                ? 1
                                                : 0,
                                            child: const Icon(
                                              Icons.send,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  question,
                                  textAlign: TextAlign.start,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 18,
                                  ),
                                ),
                          SizedBox(
                            height: MediaQuery.of(context).size.width * 0.03,
                          ),
                          Visibility(
                            visible: !add,
                            child: Column(
                              children: [
                                Container(
                                  height: 1,
                                  color: Colors.black38,
                                  margin: EdgeInsets.only(
                                    top: MediaQuery.of(context).size.width *
                                        0.03,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        deleteKeyQuestion(question);
                                      },
                                      child: Container(
                                        color: Colors.transparent,
                                        padding: EdgeInsets.symmetric(
                                          vertical: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.03,
                                        ),
                                        child: const Text(
                                          'Löschen',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          if (!editing) {
                                            editing = true;

                                            TextFieldControllers[
                                                    tabController.index]
                                                .text = question;

                                            TextFocuses[tabController.index]
                                                .requestFocus();
                                          } else {
                                            editing = false;
                                          }
                                        });
                                      },
                                      child: Container(
                                        color: Colors.transparent,
                                        padding: EdgeInsets.symmetric(
                                          vertical: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.03,
                                        ),
                                        child: Text(
                                          editing ? 'Abbrechen' : 'Bearbeiten',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.blueAccent,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ).toList(),
          ),
        ),
        // keyQuestion != ''
        //     ? Text(
        //         keyQuestion,
        //         style: const TextStyle(
        //           fontSize: 18,
        //           fontWeight: FontWeight.bold,
        //         ),
        //       )
        //     : Container(),
        // keyQuestion == ''
        //     ? TextField(
        //         controller: keyQuestionController,
        //         focusNode: keyQuestionFocus,
        //         enableSuggestions: true,
        //         autocorrect: true,
        //         textCapitalization: TextCapitalization.sentences,
        //         decoration: const InputDecoration(
        //           hintText: 'Deine Frage',
        //         ),
        //       )
        //     : Container(),
        // Visibility(
        //   visible: keyQuestionController.text.isNotEmpty,
        //   child: Row(
        //     children: [
        //       Expanded(
        //         child: Container(),
        //       ),
        //       GestureDetector(
        //         onTap: () {
        //           keyQuestion = keyQuestionController.text;
        //
        //           keyQuestions.add(keyQuestion);
        //
        //           keyQuestionController.text = '';
        //
        //           setState(() {});
        //         },
        //         child: Container(
        //           padding: EdgeInsets.only(
        //             top: MediaQuery.of(context).size.width * 0.05,
        //           ),
        //           child: const Text(
        //             'Bestätigen',
        //             style: TextStyle(
        //               fontSize: 16,
        //               color: Colors.blueAccent,
        //             ),
        //           ),
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
        // Visibility(
        //   visible: keyQuestion != '',
        //   child: Row(
        //     children: [
        //       Expanded(
        //         child: Container(),
        //       ),
        //       GestureDetector(
        //         onTap: () {
        //           keyQuestion = '';
        //
        //           keyQuestionFocus.requestFocus();
        //
        //           setState(() {});
        //         },
        //         child: Container(
        //           padding: EdgeInsets.only(
        //             top: MediaQuery.of(context).size.width * 0.05,
        //           ),
        //           child: const Text(
        //             'Bearbeiten',
        //             style: TextStyle(
        //               fontSize: 16,
        //               color: Colors.blueAccent,
        //             ),
        //           ),
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
      ];
    } else {
      return [
        Container(),
      ];
    }
  }

  bool validateTitle = false;
  bool validateDescription = false;

  List<String> newHashtags = [];

  Map<String, dynamic> editedDreamUpInfo = {};

  @override
  void initState() {
    super.initState();
    editedDreamUpInfo = Map.from(widget.dreamUpData);

    getTextControllers();

    tabController = TabController(
      length: keyQuestions.length,
      vsync: this,
      initialIndex: 0,
    );

    keyWordController = TextEditingController()
      ..addListener(() {
        setState(() {});
      });

    keyWordFocus = FocusNode();

    keyQuestionController = TextEditingController()
      ..addListener(() {
        setState(() {});
      });

    keyQuestionFocus = FocusNode();

    dragController = DraggableScrollableController();

    titleEditController = TextEditingController()
      ..addListener(() {
        editedDreamUpInfo['title'] = titleEditController.text;

        setState(() {});
      });

    descriptionEditController = TextEditingController()
      ..addListener(() {
        editedDreamUpInfo['content'] = descriptionEditController.text;

        setState(() {});
      });

    titleEditFocus = FocusNode();

    descriptionEditFocus = FocusNode();
  }

  @override
  void dispose() {
    keyWordController.dispose();

    keyWordFocus.dispose();

    keyQuestionController.dispose();

    keyQuestionFocus.dispose();

    dragController.dispose();

    titleEditController.dispose();
    descriptionEditController.dispose();

    titleEditFocus.dispose();
    descriptionEditFocus.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.white,
        title: const Text(
          'Bearbeiten',
          style: TextStyle(
            color: Colors.black87,
          ),
        ),
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context, true);
          },
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
          ),
        ),
      ),
      body: SizedBox.expand(
        child: Stack(
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.fromLTRB(
                MediaQuery.of(context).size.width * 0.05,
                MediaQuery.of(context).size.width * 0.05,
                MediaQuery.of(context).size.width * 0.05,
                0,
              ),
              color: Colors.grey.withOpacity(0.1),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: MediaQuery.of(context).size.width * 0.4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  editTitle
                                      ? editTitle = false
                                      : editTitle = true;

                                  setState(() {});
                                },
                                child: Container(
                                  padding: EdgeInsets.only(
                                    bottom: MediaQuery.of(context).size.width *
                                        0.02,
                                  ),
                                  child: editTitle
                                      ? TextField(
                                          controller: titleEditController,
                                          autofocus: true,
                                          onSubmitted: (text) {
                                            if (text != '') {
                                              titleEditController.text = text;

                                              editTitle = false;

                                              validateTitle = false;

                                              widget.dreamUpData['title'] =
                                                  text;
                                            } else {
                                              validateTitle = true;
                                            }

                                            setState(() {});
                                          },
                                          decoration: InputDecoration(
                                            suffixIcon: GestureDetector(
                                              onTap: () {
                                                editTitle = false;

                                                setState(() {});
                                              },
                                              child: const Icon(
                                                Icons.cancel,
                                              ),
                                            ),
                                            errorText: validateTitle
                                                ? titleEditController
                                                            .text.length <=
                                                        40
                                                    ? 'Bitte gib einen Titel an'
                                                    : 'Der Titel ist zu lang'
                                                : null,
                                          ),
                                        )
                                      : Text(
                                          editedDreamUpInfo['title'],
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    editDescription = true;

                                    setState(() {});
                                  },
                                  child: Container(
                                    color: Colors.transparent,
                                    child: editDescription
                                        ? TextField(
                                            controller:
                                                descriptionEditController,
                                            focusNode: descriptionEditFocus,
                                            autofocus: true,
                                            minLines: null,
                                            maxLines: null,
                                            expands: true,
                                            decoration: InputDecoration(
                                              suffixIcon: GestureDetector(
                                                onTap: () {
                                                  descriptionEditController
                                                      .text = '';

                                                  setState(() {});
                                                },
                                                child: const Icon(
                                                  Icons.cancel,
                                                ),
                                              ),
                                              errorText: validateDescription
                                                  ? 'Bitte füge eine Beschreibung hinzu'
                                                  : null,
                                            ),
                                          )
                                        : SingleChildScrollView(
                                            physics:
                                                const BouncingScrollPhysics(),
                                            child: Text(
                                              editedDreamUpInfo['content'],
                                              overflow: TextOverflow.fade,
                                              style: const TextStyle(
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              Visibility(
                                visible: editDescription,
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        if (descriptionEditController
                                            .text.isEmpty) {
                                          validateDescription = true;
                                        } else {
                                          print(descriptionEditController.text);

                                          editedDreamUpInfo['content'] =
                                              descriptionEditController.text;

                                          FocusManager.instance.primaryFocus
                                              ?.unfocus();

                                          validateDescription = false;

                                          editDescription = false;
                                        }

                                        print(editedDreamUpInfo['content']);

                                        setState(() {});
                                      },
                                      child: Container(
                                        color: Colors.transparent,
                                        padding: EdgeInsets.symmetric(
                                          vertical: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.025,
                                        ),
                                        child: const Text(
                                          'Fertig',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blueAccent,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        width: editDescription
                            ? 0
                            : MediaQuery.of(context).size.width * 0.05,
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.width * 0.4,
                        child: Column(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  showImageDialog();
                                },
                                child: Container(
                                  color: Colors.transparent,
                                  child: const AutoSizeText(
                                    'Bild bearbeiten',
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: Colors.blueAccent,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                if (!validateTitle && !validateDescription) {}
                              },
                              child: SizedBox(
                                height: MediaQuery.of(context).size.width * 0.3,
                                width: MediaQuery.of(context).size.width * 0.3,
                                child: Stack(
                                  children: [
                                    Hero(
                                      tag: 'overviewImage',
                                      child: croppedImage != null
                                          ? Image.file(
                                              croppedImage!,
                                              fit: BoxFit.fill,
                                            )
                                          : widget.dreamUpImage,
                                    ),
                                    Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            Colors.black54,
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          stops: [
                                            0,
                                            0.8,
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      child: SizedBox(
                                        height:
                                            MediaQuery.of(context).size.width *
                                                0.3 *
                                                0.25,
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.3,
                                        child: const Center(
                                          child: Text(
                                            'Vorschau',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black87,
                                                  blurRadius: 5,
                                                  offset: Offset(1, 1),
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
                          ],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: 1,
                    color: Colors.black26,
                    margin: EdgeInsets.symmetric(
                      vertical: MediaQuery.of(context).size.width * 0.05,
                    ),
                  ),
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          sheetContent = 'keyQuestions';

                          setState(() {});

                          dragController
                              .animateTo(
                            0.95,
                            duration: const Duration(
                              milliseconds: 250,
                            ),
                            curve: Curves.fastOutSlowIn,
                          )
                              .then((value) {
                            dragInitSize = 0.95;

                            setState(() {});
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).size.width * 0.075,
                          ),
                          color: Colors.transparent,
                          child: Row(
                            children: [
                              const Icon(
                                Icons.key_rounded,
                                color: Colors.black54,
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.02,
                              ),
                              const Expanded(
                                child: Text(
                                  'Schlüsselfrage hinzufügen',
                                  style: TextStyle(
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          sheetContent = 'keyWords';

                          setState(() {});

                          dragController
                              .animateTo(
                            0.9,
                            duration: const Duration(
                              milliseconds: 250,
                            ),
                            curve: Curves.fastOutSlowIn,
                          )
                              .then((value) {
                            dragInitSize = 0.9;

                            keyWordController.text = '#';

                            keyWordFocus.requestFocus();

                            setState(() {});
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).size.width * 0.075,
                          ),
                          color: Colors.transparent,
                          child: Row(
                            children: [
                              const Icon(
                                Icons.numbers_rounded,
                                color: Colors.black54,
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.02,
                              ),
                              const Expanded(
                                child: Text(
                                  'Hashtags hinzufügen',
                                  style: TextStyle(
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.push(
                          context,
                          changePage(
                            EditOverview(
                              dreamUpData: editedDreamUpInfo,
                              dreamUpImage: widget.dreamUpImage,
                              blurredImage: widget.blurredImage,
                              newImage: croppedImage,
                              newHashtags: newHashtags,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.width * 0.05,
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.width * 0.02,
                          horizontal: MediaQuery.of(context).size.width * 0.03,
                        ),
                        decoration: BoxDecoration(
                          color: (!validateTitle && !validateDescription)
                              ? Colors.blueAccent
                              : Colors.grey,
                          borderRadius: BorderRadius.circular(
                            MediaQuery.of(context).size.width * 0.05,
                          ),
                        ),
                        child: const Text(
                          'Fertig',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: NotificationListener<DraggableScrollableNotification>(
                onNotification: (note) {
                  if (dragInitSize != 0 && note.extent <= 0.1) {
                    dragInitSize = 0;

                    sheetContent = '';

                    FocusManager.instance.primaryFocus?.unfocus();
                  }

                  return true;
                },
                child: DraggableScrollableSheet(
                  controller: dragController,
                  initialChildSize: dragInitSize,
                  minChildSize: 0,
                  maxChildSize: 0.95,
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
                          MediaQuery.of(context).size.width * 0.075,
                          MediaQuery.of(context).size.width * 0.05,
                          MediaQuery.of(context).size.width * 0.075,
                        ),
                        controller: scrollController,
                        physics: const BouncingScrollPhysics(),
                        children: PanelContent(sheetContent),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
//endregion
