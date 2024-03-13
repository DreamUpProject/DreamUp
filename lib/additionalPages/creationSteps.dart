import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:friendivity/additionalPages/creationOverview.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../main.dart';
import '../utils/audioWidgets.dart';

//region Global Variables
int maxKeyQuestions = 3;
//endregion

//region UI Logic
class CreationStepPage extends StatefulWidget {
  final String vibeType;

  const CreationStepPage({
    Key? key,
    required this.vibeType,
  }) : super(key: key);

  @override
  State<CreationStepPage> createState() => _CreationStepPageState();
}

class _CreationStepPageState extends State<CreationStepPage>
    with TickerProviderStateMixin {
  String placeholderDescription =
      'Hi! Ich finde es absolut super hier endlich mal genau beschreiben zu können was ich suche. Wie im Titel schon steht wäre es mega schön endlich mal Leute für solch ein Vorhaben zu finden. Eigentlich ist mir auch vollkommen egal ob jetzt eine einzelne Person oder eine Gruppe, liket einfach den Status und wir schauen mal was draus wird. Ich will nur endlich mal wieder was starten. Es ist halt super schwer heutzutage neue Leute oder gar Freunde zu finden deswegen freu ich mich auf jeden der Bock auf so eine gemeinsame Aktion hätte. Zeit oder Datum spielt auch an sich keine Rolle, das können wir gerne in einem Gespräch  ausmachen wie es am besten passt. Wer du bist oder wie du aussiehst ist mir auch ziemlich egal, Mensch ist Mensch. Wenn du aber mehr über mich rausfinden möchtest schau dir einfach mein Profil an, bin aber wirklich allen offen gegenüber. Du kannst mir auch sehr gerne erstmal schreiben, ein Treffen entwickelt sich daraus ja eh erst später. Kleine Randnotiz muss ich aber noch hinzufügen: mir gehts wirklich um die Aktion an sich beziehungsweise natürlich Freundschaften zu schließen. Beziehungskram wäre hier fehl am Platz, nur ums gleich vorweg zu nehmen. Freue mich ansonsten aber auf alle Anfragen.';

  String placeholderTitle = 'Treffen und Quatschen';

  int creationStep = 0;

  String description = '';
  File? audioDescription;
  String redFlags = '';
  String title = '';
  String category = 'Einfach Quatschen';
  File? croppedImage;
  List<Map<String, String>> openQuestions = [];

  ImageProvider placeholderImage =
      Image.asset('assets/images/ucImages/ostseeQuadrat.jpg').image;

  Future pickImage(bool fromGallery) async {
    File? image;

    final pickedImage = await ImagePicker().pickImage(
      source: fromGallery ? ImageSource.gallery : ImageSource.camera,
      maxHeight: 1080,
      maxWidth: 1080,
    );

    if (pickedImage == null) return;

    final imageTemporary = File(pickedImage.path);
    image = imageTemporary;

    await cropImage(image);

    setState(() {});
  }

  Future<File?> cropImage(File? image) async {
    var cropped = await ImageCropper().cropImage(
      sourcePath: image!.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      aspectRatioPresets: [CropAspectRatioPreset.square],
    );

    setState(() {
      croppedImage = File(cropped!.path);
    });

    return null;
  }

  late TextEditingController descriptionController;
  late TextEditingController redFlagController;
  late TextEditingController titleController;
  late TextEditingController questionController;

  late FocusNode descriptionFocus;
  late FocusNode redFlagFocus;
  late FocusNode titleFocus;
  late FocusNode questionFocus;

  late TextEditingController landscapeController;
  late FocusNode landscapeFocus;

  bool textExpanded = false;

  bool loading = false;

  String landscapeText = '';

  late DraggableScrollableController dragController;

  String sheetContent = '';

  double dragInitSize = 0;

  late TextEditingController keyWordController;
  late FocusNode keyWordFocus;

  late TextEditingController keyQuestionController;
  late FocusNode keyQuestionFocus;

  RangeValues sliderValues = const RangeValues(18, 100);
  bool genderSwitch = false;

  bool editTitle = false;
  bool editDescription = false;

  late TextEditingController openQuestionController;
  late TextEditingController openAnswerController;

  late FocusNode openQuestionFocus;
  late FocusNode openAnswerFocus;

  late TextEditingController descriptionEditController;
  late TextEditingController titleEditController;

  late FocusNode descriptionEditFocus;
  late FocusNode titleEditFocus;

  List<String> keyWords = [];

  bool recordingAudio = false;

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

  Widget DescriptionTextWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        description == ''
            ? Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      MediaQuery.of(context).size.width * 0.05,
                    ),
                  ),
                  child: GestureDetector(
                    onDoubleTap: () {
                      var jacobId = '5HW31VMcRZdiMeYgJwbQqAiL5w82';
                      var fabiId = 'Wjrh9Zg3vPcrTOJrgTWtYgwzELC3';

                      if (FirebaseAuth.instance.currentUser?.uid == fabiId) {
                        descriptionController.text = placeholderDescription;

                        description = placeholderDescription;
                      } else if (FirebaseAuth.instance.currentUser?.uid ==
                          jacobId) {
                        descriptionController.text = placeholderDescription;

                        description = placeholderDescription;
                      }

                      setState(() {});
                    },
                    child: TextField(
                      controller: descriptionController,
                      focusNode: descriptionFocus,
                      textCapitalization: TextCapitalization.sentences,
                      enableSuggestions: true,
                      autocorrect: true,
                      autofocus: true,
                      expands: true,
                      minLines: null,
                      maxLines: null,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(
                          MediaQuery.of(context).size.width * 0.05,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : Flexible(
                child: GestureDetector(
                  onTap: () {
                    description = '';

                    setState(() {});
                  },
                  child: Container(
                    alignment: Alignment.topLeft,
                    color: Colors.white,
                    padding: EdgeInsets.all(
                      MediaQuery.of(context).size.width * 0.05,
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Text(
                        description,
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
        description == ''
            ? Visibility(
                visible: descriptionController.text.isNotEmpty,
                child: GestureDetector(
                  onTap: () {
                    description = descriptionController.text;

                    setState(() {});
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
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      description = '';

                      setState(() {});
                    },
                    child: Container(
                      color: Colors.transparent,
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).size.width * 0.05,
                        right: MediaQuery.of(context).size.width * 0.05,
                      ),
                      child: const Text(
                        'Bearbeiten',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      landscapeController.text = '';
                      landscapeText = '';

                      creationStep = 1;

                      setState(() {});

                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                    child: Container(
                      color: Colors.transparent,
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).size.width * 0.05,
                        left: MediaQuery.of(context).size.width * 0.05,
                      ),
                      child: const Text(
                        'Weiter',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                  )
                ],
              ),
      ],
    );
  }

  int recordDuration = 0;

  bool recording = false;
  Timer? timer;
  final audioRecorder = Record();
  String audioPath = '';

  void startTimer() {
    timer?.cancel();

    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) async {
      setState(() => recordDuration++);
    });
  }

  Future startRecord() async {
    try {
      if (await audioRecorder.hasPermission()) {
        final isSupported = await audioRecorder.isEncoderSupported(
          AudioEncoder.aacLc,
        );
        if (kDebugMode) {
          print('${AudioEncoder.aacLc.name} supported: $isSupported');
        }

        await audioRecorder.start();
        recordDuration = 0;

        setState(() {});

        startTimer();
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future stopRecord() async {
    timer?.cancel();

    audioPath = (await audioRecorder.stop())!;

    File file = File.fromUri(Uri.parse(audioPath));

    audioDescription = file;
  }

  Future pauseRecord() async {
    timer?.cancel();
    await audioRecorder.pause();
  }

  Future resumeRecord() async {
    startTimer();
    await audioRecorder.resume();
  }

  Future cancelRecord() async {
    recordVoice = false;

    right = 0;

    setState(() {});

    timer?.cancel();
    recordDuration = 0;

    await audioRecorder.stop();
  }

  String direction = '';

  double right = 0;
  double rightStart = 0;
  double bottom = 0;
  double bottomStart = 0;

  bool recordVoice = false;

  bool locked = false;

  var color = const Color(0xFF485868);

  Widget TimerWidget() {
    final String minutes = (recordDuration ~/ 60).toString();
    final String seconds = _formatNumber(recordDuration % 60);

    return Text(
      '$minutes:$seconds',
      style: TextStyle(
        color: color,
        fontSize: 48,
      ),
    );
  }

  String _formatNumber(int number) {
    String numberStr = number.toString();
    if (number < 10) {
      numberStr = '0$numberStr';
    }

    return numberStr;
  }

  Widget DescriptionAudioWidget() {
    return SizedBox.expand(
      child: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.width * 0.1,
          ),
          TimerWidget(),
          Expanded(
            child: !locked
                ? Stack(
                    alignment: Alignment.bottomCenter,
                    clipBehavior: Clip.none,
                    children: [
                      Visibility(
                        visible: recordVoice && !locked,
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.725,
                          height: MediaQuery.of(context).size.width * 0.1,
                          margin: EdgeInsets.only(
                            bottom: MediaQuery.of(context).size.width * 0.025,
                          ),
                          alignment: Alignment.centerLeft,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3E3E3),
                              borderRadius: BorderRadius.circular(500),
                            ),
                            height: MediaQuery.of(context).size.width * 0.1,
                            width: MediaQuery.of(context).size.width * 0.4,
                            alignment: Alignment.centerLeft,
                            padding: EdgeInsets.only(
                              top: MediaQuery.of(context).size.width * 0.02,
                              left: MediaQuery.of(context).size.width * 0.02,
                            ),
                            child: const Column(
                              children: [
                                Icon(
                                  Icons.cancel_outlined,
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: recordVoice && !locked,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3E3E3),
                            borderRadius: BorderRadius.circular(500),
                          ),
                          height: MediaQuery.of(context).size.width * 0.27,
                          width: min(
                            MediaQuery.of(context).size.width * 0.1,
                            MediaQuery.of(context).size.height * 0.1,
                          ),
                          padding: EdgeInsets.only(
                            top: min(
                              MediaQuery.of(context).size.width * 0.025,
                              MediaQuery.of(context).size.height * 0.025,
                            ),
                          ),
                          margin: EdgeInsets.only(
                            bottom: MediaQuery.of(context).size.width * 0.025,
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Listener(
                        onPointerDown: (event) async {
                          recordVoice = true;

                          recording = true;

                          setState(() {});

                          Vibrate.vibrate();

                          await startRecord().then((value) async {
                            if (!recordVoice && recordDuration <= 1) {
                              await cancelRecord();
                            }
                          });
                        },
                        onPointerUp: (event) async {
                          recordVoice = false;

                          right = 0;

                          bottom = 0;

                          setState(() {});

                          if (recordDuration >= 1 && !locked) {
                            await stopRecord();

                            recording = false;

                            setState(() {});

                            print('stopped!');
                          } else if (!locked) {
                            await cancelRecord();

                            recording = false;

                            setState(() {});

                            print('canceled!');
                          }
                        },
                        onPointerMove: (event) async {
                          if (direction == '') {
                            var deltaX = rightStart - event.localPosition.dx;
                            var deltaY = bottomStart - event.localPosition.dy;

                            if (deltaX > deltaY) {
                              direction = 'horizontal';
                            } else if (deltaX < deltaY) {
                              direction = 'vertical';
                            }

                            setState(() {});
                          } else if (direction == 'horizontal') {
                            right = max(0, rightStart - event.localPosition.dx)
                                    .abs()
                                    .toDouble() *
                                2;
                            bottom = 0;

                            setState(() {});

                            if (right <= 10 && bottom <= 10) {
                              direction = '';

                              setState(() {});
                            } else if (right >=
                                MediaQuery.of(context).size.width * 0.5) {
                              await cancelRecord();
                            }
                          } else if (direction == 'vertical') {
                            right = 0;
                            bottom =
                                max(0, bottomStart - event.localPosition.dy)
                                    .abs()
                                    .toDouble();

                            if (right <= 10 && bottom <= 10) {
                              direction = '';

                              setState(() {});
                            } else if (bottom >=
                                MediaQuery.of(context).size.width * 0.15) {
                              locked = true;

                              print('locked!');
                            }

                            setState(() {});
                          }
                        },
                        child: Container(
                          color: Colors.transparent,
                          child: AnimatedContainer(
                            padding: EdgeInsets.only(
                              right: right,
                              bottom: bottom,
                            ),
                            duration: Duration.zero,
                            color: Colors.transparent,
                            child: CircleAvatar(
                              radius: MediaQuery.of(context).size.width * 0.075,
                              backgroundColor: color.withOpacity(0.4),
                              child: Center(
                                child: Icon(
                                  Icons.mic_rounded,
                                  color: color,
                                  size:
                                      MediaQuery.of(context).size.width * 0.075,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          recordVoice = false;
                          locked = false;

                          bottom = 0;

                          setState(() {});

                          await cancelRecord();
                        },
                        child: SizedBox(
                          height: max(
                            MediaQuery.of(context).size.width * 0.075,
                            MediaQuery.of(context).size.height * 0.075,
                          ),
                          width: max(
                            MediaQuery.of(context).size.width * 0.075,
                            MediaQuery.of(context).size.height * 0.075,
                          ),
                          child: Icon(
                            Icons.delete_forever_rounded,
                            size: max(
                              MediaQuery.of(context).size.width * 0.04,
                              MediaQuery.of(context).size.height * 0.04,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          if (recording) {
                            recording = false;

                            setState(() {});

                            await pauseRecord();
                          } else {
                            recording = true;

                            setState(() {});

                            await resumeRecord();
                          }
                        },
                        child: SizedBox(
                          height: max(
                            MediaQuery.of(context).size.width * 0.075,
                            MediaQuery.of(context).size.height * 0.075,
                          ),
                          width: max(
                            MediaQuery.of(context).size.width * 0.075,
                            MediaQuery.of(context).size.height * 0.075,
                          ),
                          child: Icon(
                            recording
                                ? Icons.pause_circle_outline_rounded
                                : Icons.mic_none_outlined,
                            size: max(
                              MediaQuery.of(context).size.width * 0.04,
                              MediaQuery.of(context).size.height * 0.04,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          await stopRecord();

                          locked = false;

                          bottom = 0;
                          right = 0;
                          recordVoice = false;

                          setState(() {});
                        },
                        child: SizedBox(
                          height: max(
                            MediaQuery.of(context).size.width * 0.075,
                            MediaQuery.of(context).size.height * 0.075,
                          ),
                          width: max(
                            MediaQuery.of(context).size.width * 0.075,
                            MediaQuery.of(context).size.height * 0.075,
                          ),
                          child: Icon(
                            Icons.send_rounded,
                            size: max(
                              MediaQuery.of(context).size.width * 0.04,
                              MediaQuery.of(context).size.height * 0.04,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future askForMicPermission() async {
    var status = await Permission.microphone.status;

    if (status != PermissionStatus.granted) {
      await Permission.microphone.request();
    } else {
      print('Permission granted!');
    }
  }

  Future checkCameraPermission() async {
    var status = await Permission.camera.status;

    if (!status.isGranted) {
      await Permission.camera.request();
    }
  }

  Future checkGalleryPermission() async {
    var status = await Permission.storage.status;

    if (!status.isGranted) {
      await Permission.storage.request();
    }
  }

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

    setState(() {});
  }

  List<Widget> PanelContent(String contentType) {
    if (contentType == 'keyWords') {
      return [
        const Text(
          'Füge Hashtags hinzu',
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
          decoration: InputDecoration(
            hintText: '#hashtag',
            errorText: keyWordController.text.contains(' ')
                ? 'Hashtags enthalten keine Leerzeichen'
                : null,
          ),
        ),
        SizedBox(
          height: MediaQuery.of(context).size.width * 0.05,
        ),
        Wrap(
          spacing: MediaQuery.of(context).size.width * 0.03,
          runSpacing: MediaQuery.of(context).size.width * 0.02,
          children: keyWords
              .map<Widget>(
                (word) => GestureDetector(
                  onTap: () async {
                    keyWords.remove(word);

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
                      vertical: MediaQuery.of(context).size.width * 0.02,
                      horizontal: MediaQuery.of(context).size.width * 0.03,
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
                          width: MediaQuery.of(context).size.width * 0.01,
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
        ),
        SizedBox(
          height: MediaQuery.of(context).size.width * 0.05,
        ),
        Column(
          children: [
            Visibility(
              visible: keyWordController.text.length >= 2 &&
                  !keyWordController.text.contains(' '),
              child: GestureDetector(
                onTap: () async {
                  var entry = keyWordController.text;

                  keyWords.add(entry);

                  keyWordController.text = '#';

                  keyWordController.selection = TextSelection.fromPosition(
                    TextPosition(
                      offset: keyWordController.text.length,
                    ),
                  );

                  setState(() {});
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
              ),
            ),
            keyWordController.text.length >= 2
                ? StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('hashtags')
                        .where('start', isEqualTo: keyWordController.text[1])
                        .orderBy('hashtag', descending: false)
                        .snapshots(),
                    builder: (context,
                        AsyncSnapshot<QuerySnapshot> hashtagSnapshot) {
                      if (hashtagSnapshot.hasData) {
                        var hashtags = hashtagSnapshot.data!.docs;

                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: hashtags.length,
                          padding: EdgeInsets.zero,
                          itemBuilder: (context, index) {
                            var thisHashtag = hashtags[index];

                            return Visibility(
                              visible:
                                  !keyWords.contains(thisHashtag['hashtag']),
                              child: GestureDetector(
                                onTap: () async {
                                  keyWords.add(thisHashtag['hashtag']);

                                  keyWordController.text = '#';

                                  keyWordController.selection =
                                      TextSelection.fromPosition(TextPosition(
                                          offset:
                                              keyWordController.text.length));

                                  setState(() {});
                                },
                                child: Container(
                                  color: Colors.white,
                                  height:
                                      MediaQuery.of(context).size.width * 0.1,
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
                                      Text(
                                        thisHashtag['useCount'].toString(),
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
                      } else if (hashtagSnapshot.hasError) {
                        return Text(
                            'An Error has occured: ${hashtagSnapshot.error}');
                      } else {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                    },
                  )
                : StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('hashtags')
                        .orderBy('useCount', descending: true)
                        .limit(5)
                        .snapshots(),
                    builder: (context,
                        AsyncSnapshot<QuerySnapshot> hashtagSnapshot) {
                      if (hashtagSnapshot.hasData) {
                        var hashtags = hashtagSnapshot.data!.docs;

                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: hashtags.length,
                          padding: EdgeInsets.zero,
                          itemBuilder: (context, index) {
                            var thisHashtag = hashtags[index];

                            return Visibility(
                              visible:
                                  !keyWords.contains(thisHashtag['hashtag']),
                              child: GestureDetector(
                                onTap: () async {
                                  keyWords.add(thisHashtag['hashtag']);

                                  keyWordController.text = '#';

                                  keyWordController.selection =
                                      TextSelection.fromPosition(TextPosition(
                                          offset:
                                              keyWordController.text.length));

                                  setState(() {});
                                },
                                child: Container(
                                  color: Colors.white,
                                  height:
                                      MediaQuery.of(context).size.width * 0.1,
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
                                      Text(
                                        '${thisHashtag['useCount']} Wishes',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.02,
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
      ];
    } else if (sheetContent == 'keyQuestion') {
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
    } else if (sheetContent == 'filter') {
      return [
        const Text(
          'Nimm Einstellungen vor',
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
        Text(
          'Alter  ${sliderValues.start.round()} - ${sliderValues.end.round()}',
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
        RangeSlider(
          values: sliderValues,
          min: 18,
          max: 100,
          onChanged: (RangeValues newValues) {
            sliderValues = newValues;

            setState(() {});
          },
        ),
        Container(
          margin: EdgeInsets.only(
            top: MediaQuery.of(context).size.width * 0.03,
          ),
          child: Row(
            children: [
              Switch(
                value: genderSwitch,
                onChanged: (value) {
                  genderSwitch = value;

                  setState(() {});
                },
              ),
              const Text(
                'nur meinem Geschlecht anzeigen',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ];
    } else {
      return [];
    }
  }

  List<String> keyQuestions = [];

  bool lovePremium = false;

  bool validateTitle = false;
  bool validateDescription = false;

  @override
  void initState() {
    super.initState();

    getTextControllers();

    tabController = TabController(
      length: keyQuestions.length,
      vsync: this,
      initialIndex: 0,
    );

    if (widget.vibeType == 'Beziehung' || widget.vibeType == 'Date') {
      lovePremium = true;
    }

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

    descriptionController = TextEditingController();
    descriptionController.addListener(() {
      setState(() {});
    });

    redFlagController = TextEditingController();
    redFlagController.addListener(() {
      setState(() {});
    });

    titleController = TextEditingController();
    titleController.addListener(() {
      if (titleController.text.length <= 40) {
        validateTitle = false;
      } else {
        validateTitle = true;

        print('too long');
      }

      setState(() {});
    });

    questionController = TextEditingController();
    questionController.addListener(() {
      setState(() {});
    });

    descriptionFocus = FocusNode();
    redFlagFocus = FocusNode();
    titleFocus = FocusNode();
    questionFocus = FocusNode();

    openQuestionController = TextEditingController();
    openQuestionController.addListener(() {
      setState(() {});
    });

    openAnswerController = TextEditingController();
    openAnswerController.addListener(() {
      setState(() {});
    });

    openQuestionFocus = FocusNode();

    openAnswerFocus = FocusNode();

    landscapeController = TextEditingController();
    landscapeFocus = FocusNode();

    titleEditController = TextEditingController()
      ..addListener(() {
        if (titleEditController.text.length <= 40) {
          validateTitle = false;
        } else {
          validateTitle = true;

          print('too long');
        }

        setState(() {});
      });

    descriptionEditController = TextEditingController()
      ..addListener(() {
        description = descriptionEditController.text;

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

    descriptionController.dispose();
    redFlagController.dispose();
    titleController.dispose();
    questionController.dispose();

    descriptionFocus.dispose();
    redFlagFocus.dispose();
    titleFocus.dispose();
    questionFocus.dispose();

    landscapeController.dispose();
    landscapeFocus.dispose();

    openAnswerController.dispose();
    openQuestionController.dispose();

    openAnswerFocus.dispose();
    openQuestionFocus.dispose();

    titleEditController.dispose();
    descriptionEditController.dispose();

    titleEditFocus.dispose();
    descriptionEditFocus.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (creationStep <= 4) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SizedBox.expand(
        child: Column(
          children: [
            Container(
              height: 55,
              margin: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (creationStep == 0) {
                        if (!recordingAudio) {
                          FocusManager.instance.primaryFocus?.unfocus();

                          SystemChrome.setPreferredOrientations([
                            DeviceOrientation.portraitUp,
                          ]);

                          Future.delayed(const Duration(milliseconds: 100), () {
                            Navigator.pop(context);
                          });
                        } else {
                          recordingAudio = false;

                          setState(() {});
                        }
                      } else if (creationStep == 1) {
                        creationStep = 0;

                        setState(() {});
                      } else if (creationStep == 2) {
                        creationStep = 1;

                        setState(() {});
                      } else if (creationStep == 3) {
                        creationStep = 2;

                        setState(() {});
                      } else if (creationStep == 4) {
                        creationStep = 3;

                        setState(() {});
                      }
                    },
                    child: const Row(
                      children: [
                        SizedBox(
                          height: 55,
                          width: 55,
                          child: Center(
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          'Zurück',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(),
                  ),
                  GestureDetector(
                    onTap: () {
                      FocusManager.instance.primaryFocus?.unfocus();

                      SystemChrome.setPreferredOrientations([
                        DeviceOrientation.portraitUp,
                      ]);

                      Future.delayed(const Duration(milliseconds: 100), () {
                        Navigator.pop(context);
                      });
                    },
                    child: const SizedBox(
                      height: 55,
                      width: 55,
                      child: Center(
                        child: Icon(
                          Icons.cancel_outlined,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  AnimatedPositioned(
                    // Description
                    top: 0,
                    bottom: 0,
                    duration: const Duration(milliseconds: 250),
                    child: Opacity(
                      opacity: creationStep == 0 ? 1 : 0,
                      child: !recordingAudio
                          ? Container(
                              width: MediaQuery.of(context).size.width,
                              height: MediaQuery.of(context).size.height * 0.4,
                              padding: EdgeInsets.all(
                                MediaQuery.of(context).size.width * 0.05,
                              ),
                              color: Colors.grey.withOpacity(0.3),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(
                                      bottom:
                                          MediaQuery.of(context).size.width *
                                              0.05,
                                    ),
                                    child: Center(
                                      child: Text(
                                        widget.vibeType == 'Date'
                                            ? 'Beschreibe dein ${widget.vibeType}'
                                            : 'Beschreibe deine ${widget.vibeType}',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    child: DescriptionTextWidget(),
                                  ),
                                  Center(
                                    child: Visibility(
                                      visible:
                                          descriptionController.text.isEmpty,
                                      child: GestureDetector(
                                        onTap: () async {
                                          recordingAudio
                                              ? recordingAudio = false
                                              : recordingAudio = true;

                                          await askForMicPermission();

                                          setState(() {});
                                        },
                                        child: Container(
                                          padding: EdgeInsets.only(
                                            top: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.05,
                                          ),
                                          child: Icon(
                                            Icons.mic_rounded,
                                            size: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.1,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(
                              width: MediaQuery.of(context).size.width,
                              color: Colors.grey.withOpacity(0.3),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(
                                      MediaQuery.of(context).size.width * 0.05,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Beschreibe deine ${widget.vibeType}',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.3,
                                    child: audioPath != ''
                                        ? Center(
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal:
                                                    MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        0.05,
                                              ),
                                              margin: EdgeInsets.symmetric(
                                                horizontal:
                                                    MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        0.05,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.05,
                                                ),
                                              ),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceAround,
                                                children: [
                                                  AudioPlayer(
                                                    duration: recordDuration,
                                                    source: audioPath,
                                                    onDelete: () {},
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      GestureDetector(
                                                        onTap: () {
                                                          audioPath = '';

                                                          recordDuration = 0;

                                                          setState(() {});
                                                        },
                                                        child: Container(
                                                          color: Colors
                                                              .transparent,
                                                          padding:
                                                              EdgeInsets.only(
                                                            bottom: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.03,
                                                          ),
                                                          child: Text(
                                                            'Löschen',
                                                            style: TextStyle(
                                                              color: color,
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      GestureDetector(
                                                        onTap: () {
                                                          creationStep = 1;

                                                          setState(() {});
                                                        },
                                                        child: Container(
                                                          color: Colors
                                                              .transparent,
                                                          padding:
                                                              EdgeInsets.only(
                                                            bottom: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.03,
                                                          ),
                                                          child: Text(
                                                            'Weiter',
                                                            style: TextStyle(
                                                              color: color,
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                        : Container(),
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(
                                      milliseconds: 200,
                                    ),
                                    height: audioPath != ''
                                        ? MediaQuery.of(context).size.height *
                                            0.7
                                        : 0,
                                  ),
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.all(
                                        MediaQuery.of(context).size.width *
                                            0.05,
                                      ),
                                      width: MediaQuery.of(context).size.width,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(
                                            MediaQuery.of(context).size.width *
                                                0.075,
                                          ),
                                          topRight: Radius.circular(
                                            MediaQuery.of(context).size.width *
                                                0.075,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          const Text(
                                            'Hold to Record',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.05,
                                          ),
                                          Expanded(
                                            child: DescriptionAudioWidget(),
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
                  AnimatedPositioned(
                    // Image
                    top: 0,
                    bottom: 0,
                    right: creationStep > 0
                        ? 0
                        : -MediaQuery.of(context).size.width,
                    duration: const Duration(milliseconds: 250),
                    child: Opacity(
                      opacity: creationStep == 1 ? 1 : 0,
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height * 0.4,
                        padding: EdgeInsets.all(
                          MediaQuery.of(context).size.width * 0.05,
                        ),
                        color: Colors.grey.withOpacity(0.3),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              margin: EdgeInsets.only(
                                bottom:
                                    MediaQuery.of(context).size.width * 0.05,
                              ),
                              child: Center(
                                child: Text(
                                  lovePremium
                                      ? 'Wähle ein Bild von dir'
                                      : 'Wähle ein Bild',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: croppedImage == null,
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      GestureDetector(
                                        onTap: () async {
                                          await checkCameraPermission();

                                          pickImage(false);
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(
                                            MediaQuery.of(context).size.width *
                                                0.05,
                                          ),
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.4,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.02,
                                            ),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              'Kamera',
                                              style: TextStyle(
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () async {
                                          checkGalleryPermission();

                                          pickImage(true);
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(
                                            MediaQuery.of(context).size.width *
                                                0.05,
                                          ),
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.4,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.02,
                                            ),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              'Gallerie',
                                              style: TextStyle(
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      croppedImage = null;

                                      creationStep = 2;

                                      setState(() {});

                                      titleFocus.requestFocus();
                                    },
                                    child: Container(
                                      margin: EdgeInsets.only(
                                        top: MediaQuery.of(context).size.width *
                                            0.05,
                                      ),
                                      padding: EdgeInsets.all(
                                        MediaQuery.of(context).size.width *
                                            0.03,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          MediaQuery.of(context).size.width *
                                              0.02,
                                        ),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'Überspringen',
                                          style: TextStyle(
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            croppedImage == null
                                ? Container()
                                : Container(
                                    margin: EdgeInsets.only(
                                      top: MediaQuery.of(context).size.width *
                                          0.05,
                                    ),
                                    height:
                                        MediaQuery.of(context).size.width * 0.9,
                                    width:
                                        MediaQuery.of(context).size.width * 0.9,
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: Image.file(
                                          croppedImage!,
                                          fit: BoxFit.fill,
                                        ).image,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        MediaQuery.of(context).size.width *
                                            0.05,
                                      ),
                                    ),
                                  ),
                            Visibility(
                              visible: croppedImage != null,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      croppedImage = null;

                                      setState(() {});
                                    },
                                    child: Container(
                                      color: Colors.transparent,
                                      padding: EdgeInsets.only(
                                        top: MediaQuery.of(context).size.width *
                                            0.05,
                                        right:
                                            MediaQuery.of(context).size.width *
                                                0.05,
                                      ),
                                      child: const Text(
                                        'Bearbeiten',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blueAccent,
                                        ),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      creationStep = 2;

                                      setState(() {});

                                      titleFocus.requestFocus();
                                    },
                                    child: Container(
                                      color: Colors.transparent,
                                      padding: EdgeInsets.only(
                                        top: MediaQuery.of(context).size.width *
                                            0.05,
                                        left:
                                            MediaQuery.of(context).size.width *
                                                0.05,
                                      ),
                                      child: const Text(
                                        'Weiter',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blueAccent,
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    // Title
                    top: 0,
                    bottom: 0,
                    right: creationStep > 1
                        ? 0
                        : -MediaQuery.of(context).size.width,
                    duration: const Duration(milliseconds: 250),
                    child: Opacity(
                      opacity: creationStep == 2 ? 1 : 0,
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height * 0.4,
                        padding: EdgeInsets.all(
                          MediaQuery.of(context).size.width * 0.05,
                        ),
                        color: Colors.grey.withOpacity(0.3),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              margin: EdgeInsets.only(
                                bottom:
                                    MediaQuery.of(context).size.width * 0.05,
                              ),
                              child: const Center(
                                child: Text(
                                  'Bestimme einen Titel',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            title == ''
                                ? Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                        MediaQuery.of(context).size.width *
                                            0.05,
                                      ),
                                    ),
                                    child: GestureDetector(
                                      onDoubleTap: () {
                                        var jacobId =
                                            '5HW31VMcRZdiMeYgJwbQqAiL5w82';
                                        var fabiId =
                                            'Wjrh9Zg3vPcrTOJrgTWtYgwzELC3';

                                        if (FirebaseAuth
                                                .instance.currentUser?.uid ==
                                            fabiId) {
                                          titleController.text =
                                              placeholderTitle;

                                          title = placeholderTitle;
                                        } else if (FirebaseAuth
                                                .instance.currentUser?.uid ==
                                            jacobId) {
                                          titleController.text =
                                              placeholderTitle;

                                          title = placeholderTitle;
                                        }

                                        setState(() {});
                                      },
                                      child: TextField(
                                        controller: titleController,
                                        focusNode: titleFocus,
                                        onSubmitted: (text) {
                                          if (titleController.text.isNotEmpty &&
                                              titleController.text.length <=
                                                  40) {
                                            title = titleController.text;

                                            validateTitle = false;

                                            setState(() {});
                                          } else {
                                            validateTitle = true;
                                          }
                                        },
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                        enableSuggestions: true,
                                        autocorrect: true,
                                        autofocus: true,
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          errorText: validateTitle
                                              ? 'Der Titel ist zu lang'
                                              : null,
                                          contentPadding: EdgeInsets.all(
                                            MediaQuery.of(context).size.width *
                                                0.05,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : GestureDetector(
                                    onTap: () {
                                      title = '';

                                      setState(() {});
                                    },
                                    child: Container(
                                      alignment: Alignment.topLeft,
                                      color: Colors.white,
                                      padding: EdgeInsets.all(
                                        MediaQuery.of(context).size.width *
                                            0.05,
                                      ),
                                      child: Text(
                                        title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                            title == ''
                                ? Visibility(
                                    visible: titleController.text
                                            .trim()
                                            .isNotEmpty &&
                                        !validateTitle,
                                    child: GestureDetector(
                                      onTap: () {
                                        title = titleController.text;

                                        setState(() {});
                                      },
                                      child: Container(
                                        color: Colors.transparent,
                                        padding: EdgeInsets.only(
                                          top: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.05,
                                          left: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.05,
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
                                  )
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          title = '';

                                          setState(() {});
                                        },
                                        child: Container(
                                          color: Colors.transparent,
                                          padding: EdgeInsets.only(
                                            top: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.05,
                                            right: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.05,
                                          ),
                                          child: const Text(
                                            'Bearbeiten',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blueAccent,
                                            ),
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          landscapeController.text = '';
                                          landscapeText = '';

                                          creationStep = 3;

                                          FocusManager.instance.primaryFocus
                                              ?.unfocus();

                                          setState(() {});
                                        },
                                        child: Container(
                                          color: Colors.transparent,
                                          padding: EdgeInsets.only(
                                            top: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.05,
                                            left: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.05,
                                          ),
                                          child: const Text(
                                            'Weiter',
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
                          ],
                        ),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    top: 0,
                    bottom: 0,
                    right: creationStep > 2
                        ? 0
                        : -MediaQuery.of(context).size.width,
                    duration: const Duration(milliseconds: 250),
                    child: Opacity(
                      opacity: creationStep == 3 ? 1 : 0,
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height * 0.4,
                        padding: EdgeInsets.fromLTRB(
                          MediaQuery.of(context).size.width * 0.05,
                          MediaQuery.of(context).size.width * 0.05,
                          MediaQuery.of(context).size.width * 0.05,
                          0,
                        ),
                        color: Colors.grey.withOpacity(0.1),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height:
                                          MediaQuery.of(context).size.width *
                                              0.4,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              editTitle = true;

                                              titleEditController.text = title;

                                              setState(() {});
                                            },
                                            child: Container(
                                              padding: EdgeInsets.only(
                                                bottom: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.02,
                                              ),
                                              child: editTitle
                                                  ? TextField(
                                                      autocorrect: true,
                                                      enableSuggestions: true,
                                                      textCapitalization:
                                                          TextCapitalization
                                                              .sentences,
                                                      controller:
                                                          titleEditController,
                                                      autofocus: true,
                                                      onSubmitted: (text) {
                                                        if (text != '') {
                                                          title = text;

                                                          titleEditController
                                                              .text = text;

                                                          editTitle = false;

                                                          validateTitle = false;

                                                          setState(() {});
                                                        } else {
                                                          validateTitle = true;

                                                          setState(() {});
                                                        }
                                                      },
                                                      decoration:
                                                          InputDecoration(
                                                        suffixIcon:
                                                            GestureDetector(
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
                                                                        .text
                                                                        .length <=
                                                                    40
                                                                ? 'Bitte gib einen Titel an'
                                                                : 'Der Titel ist zu lang'
                                                            : null,
                                                      ),
                                                    )
                                                  : Text(
                                                      title,
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Container(
                                              color: Colors.transparent,
                                              child: GestureDetector(
                                                onTap: () {
                                                  editDescription = true;

                                                  descriptionEditController
                                                      .text = description;

                                                  setState(() {});
                                                },
                                                child: editDescription
                                                    ? TextField(
                                                        autocorrect: true,
                                                        enableSuggestions: true,
                                                        textCapitalization:
                                                            TextCapitalization
                                                                .sentences,
                                                        controller:
                                                            descriptionEditController,
                                                        focusNode:
                                                            descriptionEditFocus,
                                                        autofocus: true,
                                                        minLines: null,
                                                        maxLines: null,
                                                        expands: true,
                                                        decoration:
                                                            InputDecoration(
                                                          suffixIcon:
                                                              GestureDetector(
                                                            onTap: () {
                                                              descriptionEditController
                                                                  .text = '';

                                                              setState(() {});
                                                            },
                                                            child: const Icon(
                                                              Icons.cancel,
                                                            ),
                                                          ),
                                                          errorText:
                                                              validateDescription
                                                                  ? 'Bitte füge eine Beschreibung hinzu'
                                                                  : null,
                                                        ),
                                                      )
                                                    : SingleChildScrollView(
                                                        physics:
                                                            const BouncingScrollPhysics(),
                                                        child: Text(
                                                          description,
                                                          overflow:
                                                              TextOverflow.fade,
                                                          style:
                                                              const TextStyle(
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
                                                      validateDescription =
                                                          true;
                                                    } else {
                                                      FocusManager
                                                          .instance.primaryFocus
                                                          ?.unfocus();

                                                      validateDescription =
                                                          false;

                                                      editDescription = false;
                                                    }

                                                    setState(() {});
                                                  },
                                                  child: Container(
                                                    color: Colors.transparent,
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      vertical:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.025,
                                                    ),
                                                    child: const Text(
                                                      'Fertig',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Colors.blueAccent,
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
                                        : MediaQuery.of(context).size.width *
                                            0.05,
                                  ),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.width * 0.4,
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
                                            if (!validateTitle &&
                                                !validateDescription) {
                                              Map<String, dynamic> vibeData = {
                                                'title': title,
                                                'category': category,
                                                'type': widget.vibeType,
                                                'content': description,
                                              };

                                              if (redFlags.isNotEmpty) {
                                                vibeData.addAll({
                                                  'redFlags': redFlags,
                                                });
                                              }

                                              if (keyQuestions.isNotEmpty) {
                                                vibeData.addAll({
                                                  'keyQuestions': keyQuestions,
                                                });
                                              }

                                              if (openQuestions.isNotEmpty) {
                                                vibeData.addAll({
                                                  'openQuestions':
                                                      openQuestions,
                                                });
                                              }

                                              if (keyWords.isNotEmpty) {
                                                vibeData.addAll({
                                                  'hashtags': keyWords,
                                                });
                                              }

                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      CreationOverview(
                                                    dreamUpData: vibeData,
                                                    vibeImage: croppedImage,
                                                    audioDescription:
                                                        audioDescription,
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          child: SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.3,
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.3,
                                            child: Stack(
                                              children: [
                                                Hero(
                                                  tag: 'overviewImage',
                                                  child: croppedImage != null
                                                      ? Image.file(
                                                          croppedImage!,
                                                          fit: BoxFit.fill,
                                                        )
                                                      : lovePremium
                                                          ? Image.file(
                                                              CurrentUser
                                                                  .imageFile!,
                                                              fit: BoxFit.fill,
                                                            )
                                                          : Image.asset(
                                                              'assets/images/ucImages/ostseeQuadrat.jpg',
                                                              fit: BoxFit.fill,
                                                            ),
                                                ),
                                                Container(
                                                  decoration:
                                                      const BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Colors.transparent,
                                                        Colors.black54,
                                                      ],
                                                      begin:
                                                          Alignment.topCenter,
                                                      end: Alignment
                                                          .bottomCenter,
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
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.3 *
                                                            0.25,
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.3,
                                                    child: const Center(
                                                      child: Text(
                                                        'Vorschau',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          shadows: [
                                                            Shadow(
                                                              color: Colors
                                                                  .black87,
                                                              blurRadius: 5,
                                                              offset:
                                                                  Offset(1, 1),
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
                                  vertical:
                                      MediaQuery.of(context).size.width * 0.05,
                                ),
                              ),
                              Column(
                                children: [
                                  GestureDetector(
                                    onTap: () async {
                                      sheetContent = 'keyQuestion';

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

                                        setState(() {});
                                      });
                                    },
                                    child: Container(
                                      padding: EdgeInsets.only(
                                        bottom:
                                            MediaQuery.of(context).size.width *
                                                0.075,
                                      ),
                                      color: Colors.transparent,
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.key_rounded,
                                            color: Colors.black54,
                                          ),
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.02,
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
                                        bottom:
                                            MediaQuery.of(context).size.width *
                                                0.075,
                                      ),
                                      color: Colors.transparent,
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.numbers_rounded,
                                            color: Colors.black54,
                                          ),
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.02,
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
                                  Center(
                                    child: GestureDetector(
                                      onTap: () async {
                                        if (!validateTitle &&
                                            !validateDescription) {
                                          Map<String, dynamic> vibeData = {
                                            'title': title,
                                            'category': category,
                                            'type': widget.vibeType,
                                            'content': description,
                                          };

                                          if (redFlags.isNotEmpty) {
                                            vibeData.addAll({
                                              'redFlags': redFlags,
                                            });
                                          }

                                          if (keyQuestions.isNotEmpty) {
                                            vibeData.addAll({
                                              'keyQuestions': keyQuestions,
                                            });
                                          }

                                          if (openQuestions.isNotEmpty) {
                                            vibeData.addAll({
                                              'openQuestions': openQuestions,
                                            });
                                          }

                                          if (keyWords.isNotEmpty) {
                                            vibeData.addAll({
                                              'hashtags': keyWords,
                                            });
                                          }

                                          print(audioDescription?.path);

                                          var close = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  CreationOverview(
                                                dreamUpData: vibeData,
                                                vibeImage: croppedImage,
                                                audioDescription:
                                                    audioDescription,
                                              ),
                                            ),
                                          );

                                          if (close) {
                                            Navigator.pop(context);
                                          }
                                        }
                                      },
                                      child: Container(
                                        margin: EdgeInsets.symmetric(
                                          vertical: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.05,
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
                                        decoration: BoxDecoration(
                                          color: (!validateTitle &&
                                                  !validateDescription)
                                              ? Colors.blueAccent
                                              : Colors.grey,
                                          borderRadius: BorderRadius.circular(
                                            MediaQuery.of(context).size.width *
                                                0.05,
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
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child:
                        NotificationListener<DraggableScrollableNotification>(
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
                        maxChildSize: 0.9,
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
          ],
        ),
      ),
    );
  }
}
//endregion
