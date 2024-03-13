import 'dart:ui';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../main.dart';

class PersonalQuestionPage extends StatefulWidget {
  const PersonalQuestionPage({Key? key}) : super(key: key);

  @override
  State<PersonalQuestionPage> createState() => _PersonalQuestionPageState();
}

class _PersonalQuestionPageState extends State<PersonalQuestionPage> {
  bool blackHumorYes = false;
  bool blackHumorNo = false;

  bool answerFast = false;
  bool answerSlow = false;

  bool criticizingBehaviourYes = false;
  bool criticizingBehaviourNo = false;

  bool initiativeYes = false;
  bool initiativeNo = false;

  List<dynamic> redFlags = [];

  String personalTitle = '';

  late TextEditingController redFlagController;

  late TextEditingController personalTitleController;

  void uploadAttributes() async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.all(
          MediaQuery.of(context).size.width * 0.05,
        ),
        child: Container(
          padding: EdgeInsets.all(
            MediaQuery.of(context).size.width * 0.05,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              SizedBox(
                height: MediaQuery.of(context).size.width * 0.05,
              ),
              const Text(
                'Deine Angaben werden gespeicheert',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Map<String, dynamic> json = {};

    if (blackHumorNo) {
      json.addAll({
        'blackHumor': 'no',
      });
    } else if (blackHumorYes) {
      json.addAll({
        'blackHumor': 'yes',
      });
    }

    if (criticizingBehaviourNo) {
      json.addAll({
        'criticizing': 'no',
      });
    } else if (criticizingBehaviourYes) {
      json.addAll({
        'criticizing': 'yes',
      });
    }

    if (initiativeNo) {
      json.addAll({
        'initiative': 'no',
      });
    } else if (initiativeYes) {
      json.addAll({
        'initiative': 'yes',
      });
    }

    if (answerFast) {
      json.addAll({
        'replyBehaviour': 'fast',
      });
    } else if (answerSlow) {
      json.addAll({
        'replyBehaviour': 'slow',
      });
    }

    if (redFlags.isNotEmpty) {
      json.addAll({
        'redFlags': redFlags,
      });
    }

    if (personalTitle != '') {
      json.addAll({
        'personalTitle': personalTitle,
      });
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .update(
      {
        'personality': json,
      },
    );

    CurrentUser.personality = json;

    CurrentUser().saveUserInformation();

    Navigator.pop(context);
    Navigator.pop(context);
  }

  void getUserInfo() {
    if (CurrentUser.personality.containsKey('blackHumor')) {
      var blackHumor = CurrentUser.personality['blackHumor'];

      blackHumor == 'yes' ? blackHumorYes = true : blackHumorNo = true;
    }

    if (CurrentUser.personality.containsKey('criticizing')) {
      var criticizing = CurrentUser.personality['criticizing'];

      criticizing == 'yes'
          ? criticizingBehaviourYes = true
          : criticizingBehaviourNo = true;
    }

    if (CurrentUser.personality.containsKey('initiative')) {
      var initiative = CurrentUser.personality['initiative'];

      initiative == 'yes' ? initiativeYes = true : initiativeNo = true;
    }

    if (CurrentUser.personality.containsKey('replyBehaviour')) {
      var replyBehaviour = CurrentUser.personality['replyBehaviour'];

      replyBehaviour == 'fast' ? answerFast = true : answerSlow = true;
    }

    if (CurrentUser.personality.containsKey('redFlags')) {
      redFlags = CurrentUser.personality['redFlags'];
    }

    if (CurrentUser.personality.containsKey('personalTitle')) {
      personalTitle = CurrentUser.personality['personalTitle'];
    }
  }

  @override
  void initState() {
    super.initState();

    getUserInfo();

    redFlagController = TextEditingController()
      ..addListener(() {
        setState(() {});
      });

    personalTitleController = TextEditingController()
      ..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    redFlagController.dispose();

    personalTitleController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Background(
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: true,
          leading: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black87,
            ),
          ),
          elevation: 0,
          title: const Text(
            'Persönliche Attribute',
            style: TextStyle(
              color: Colors.black87,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CarouselSlider(
                items: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      MediaQuery.of(context).size.width * 0.05,
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 10,
                        sigmaY: 10,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            MediaQuery.of(context).size.width * 0.05,
                          ),
                          border: Border.all(
                            width: 2,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.2),
                              Colors.white.withOpacity(0.4),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: Column(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.width * 0.05,
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal:
                                    MediaQuery.of(context).size.width * 0.05,
                              ),
                              child: const Text(
                                'Schwarzer Humor?',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(
                                top: MediaQuery.of(context).size.width * 0.05,
                              ),
                              height: 2,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            Expanded(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Row(
                                    children: [
                                      Checkbox(
                                        shape: const CircleBorder(),
                                        value: blackHumorYes,
                                        onChanged: (value) {
                                          if (blackHumorYes) {
                                            blackHumorYes = value!;
                                          } else {
                                            blackHumorYes = value!;
                                            blackHumorNo = !value;
                                          }

                                          setState(() {});
                                        },
                                      ),
                                      const Text(
                                        'Ja gern',
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Checkbox(
                                        shape: const CircleBorder(),
                                        value: blackHumorNo,
                                        onChanged: (value) {
                                          if (blackHumorNo) {
                                            blackHumorNo = value!;
                                          } else {
                                            blackHumorNo = value!;
                                            blackHumorYes = !value;
                                          }

                                          setState(() {});
                                        },
                                      ),
                                      const Text(
                                        'Nicht so mein Fall',
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
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      MediaQuery.of(context).size.width * 0.05,
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 10,
                        sigmaY: 10,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            MediaQuery.of(context).size.width * 0.05,
                          ),
                          border: Border.all(
                            width: 2,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.2),
                              Colors.white.withOpacity(0.4),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: Column(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.width * 0.05,
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal:
                                    MediaQuery.of(context).size.width * 0.05,
                              ),
                              child: const Text(
                                'Kritisierst du konstruktiv?',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(
                                top: MediaQuery.of(context).size.width * 0.05,
                              ),
                              height: 2,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            Expanded(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Row(
                                    children: [
                                      Checkbox(
                                        shape: const CircleBorder(),
                                        value: criticizingBehaviourYes,
                                        onChanged: (value) {
                                          if (criticizingBehaviourYes) {
                                            criticizingBehaviourYes = value!;
                                          } else {
                                            criticizingBehaviourYes = value!;
                                            criticizingBehaviourNo = !value;
                                          }

                                          setState(() {});
                                        },
                                      ),
                                      const Text(
                                        'Ich bin immer konstruktiv',
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Checkbox(
                                        shape: const CircleBorder(),
                                        value: criticizingBehaviourNo,
                                        onChanged: (value) {
                                          if (criticizingBehaviourNo) {
                                            criticizingBehaviourNo = value!;
                                          } else {
                                            criticizingBehaviourNo = value!;
                                            criticizingBehaviourYes = !value;
                                          }

                                          setState(() {});
                                        },
                                      ),
                                      const Text(
                                        'Leben und Leben lassen',
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
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      MediaQuery.of(context).size.width * 0.05,
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 10,
                        sigmaY: 10,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            MediaQuery.of(context).size.width * 0.05,
                          ),
                          border: Border.all(
                            width: 2,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.2),
                              Colors.white.withOpacity(0.4),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: Column(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.width * 0.05,
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal:
                                    MediaQuery.of(context).size.width * 0.05,
                              ),
                              child: const Text(
                                'Ergreifst du die Initiative?',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(
                                top: MediaQuery.of(context).size.width * 0.05,
                              ),
                              height: 2,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            Expanded(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Row(
                                    children: [
                                      Checkbox(
                                        shape: const CircleBorder(),
                                        value: initiativeYes,
                                        onChanged: (value) {
                                          if (initiativeYes) {
                                            initiativeYes = value!;
                                          } else {
                                            initiativeYes = value!;
                                            initiativeNo = !value;
                                          }

                                          setState(() {});
                                        },
                                      ),
                                      const Text(
                                        'Ich mache gern den ersten Schritt',
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Checkbox(
                                        shape: const CircleBorder(),
                                        value: initiativeNo,
                                        onChanged: (value) {
                                          if (initiativeNo) {
                                            initiativeNo = value!;
                                          } else {
                                            initiativeNo = value!;
                                            initiativeYes = !value;
                                          }

                                          setState(() {});
                                        },
                                      ),
                                      const Text(
                                        'Ich werde lieber angeschrieben',
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
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      MediaQuery.of(context).size.width * 0.05,
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 10,
                        sigmaY: 10,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            MediaQuery.of(context).size.width * 0.05,
                          ),
                          border: Border.all(
                            width: 2,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.2),
                              Colors.white.withOpacity(0.4),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: Column(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.width * 0.05,
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal:
                                    MediaQuery.of(context).size.width * 0.05,
                              ),
                              child: const Text(
                                'Wie schnell antwortest du?',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(
                                top: MediaQuery.of(context).size.width * 0.05,
                              ),
                              height: 2,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            Expanded(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Row(
                                    children: [
                                      Checkbox(
                                        shape: const CircleBorder(),
                                        value: answerFast,
                                        onChanged: (value) {
                                          if (answerFast) {
                                            answerFast = value!;
                                          } else {
                                            answerFast = value!;
                                            answerSlow = !value;
                                          }

                                          setState(() {});
                                        },
                                      ),
                                      const Text(
                                        'Immer sofort',
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Checkbox(
                                        shape: const CircleBorder(),
                                        value: answerSlow,
                                        onChanged: (value) {
                                          if (answerSlow) {
                                            answerSlow = value!;
                                          } else {
                                            answerSlow = value!;
                                            answerFast = !value;
                                          }

                                          setState(() {});
                                        },
                                      ),
                                      const Text(
                                        'Wenn mir danach ist',
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
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      MediaQuery.of(context).size.width * 0.05,
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 10,
                        sigmaY: 10,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            MediaQuery.of(context).size.width * 0.05,
                          ),
                          border: Border.all(
                            width: 2,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.2),
                              Colors.white.withOpacity(0.4),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.width * 0.05,
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal:
                                    MediaQuery.of(context).size.width * 0.05,
                              ),
                              child: const Center(
                                child: Text(
                                  'Red Flags?',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.symmetric(
                                vertical:
                                    MediaQuery.of(context).size.width * 0.05,
                              ),
                              height: 2,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            Flexible(
                              child: SingleChildScrollView(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal:
                                        MediaQuery.of(context).size.width *
                                            0.05,
                                  ),
                                  child: Wrap(
                                    spacing: 5,
                                    runSpacing: 10,
                                    children: redFlags
                                        .map<Widget>(
                                          (flag) => Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 5,
                                              horizontal: 7,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    flag,
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: 5,
                                                ),
                                                GestureDetector(
                                                  onTap: () {
                                                    redFlags.remove(flag);

                                                    setState(() {});
                                                  },
                                                  child: const Icon(
                                                    Icons.cancel_outlined,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal:
                                    MediaQuery.of(context).size.width * 0.05,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  TextField(
                                    controller: redFlagController,
                                    decoration: const InputDecoration(
                                      hintText: 'Deine Red Flags',
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      if (redFlagController.text.isNotEmpty) {
                                        redFlags.add(redFlagController.text);

                                        redFlagController.text = '';
                                      }
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical:
                                            MediaQuery.of(context).size.width *
                                                0.03,
                                      ),
                                      child: const Text(
                                        'Bestätigen',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      MediaQuery.of(context).size.width * 0.05,
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 10,
                        sigmaY: 10,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            MediaQuery.of(context).size.width * 0.05,
                          ),
                          border: Border.all(
                            width: 2,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.2),
                              Colors.white.withOpacity(0.4),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: Column(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.width * 0.05,
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal:
                                    MediaQuery.of(context).size.width * 0.05,
                              ),
                              child: const Text(
                                'Gib dir einen Titel',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.symmetric(
                                vertical:
                                    MediaQuery.of(context).size.width * 0.05,
                              ),
                              height: 2,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            Visibility(
                              visible: personalTitle != '',
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal:
                                      MediaQuery.of(context).size.width * 0.05,
                                ),
                                child: Text(
                                  personalTitle,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal:
                                    MediaQuery.of(context).size.width * 0.05,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  TextField(
                                    controller: personalTitleController,
                                    decoration: const InputDecoration(
                                      hintText: 'Dein Titel',
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      if (personalTitleController
                                          .text.isNotEmpty) {
                                        personalTitle =
                                            personalTitleController.text;

                                        personalTitleController.text = '';
                                      }

                                      setState(() {});

                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical:
                                            MediaQuery.of(context).size.width *
                                                0.03,
                                      ),
                                      child: const Text(
                                        'Bestätigen',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                options: CarouselOptions(
                  height: MediaQuery.of(context).size.height * 0.4,
                  viewportFraction: 0.85,
                  enableInfiniteScroll: false,
                  scrollPhysics: const BouncingScrollPhysics(),
                ),
              ),
              GestureDetector(
                onTap: () {
                  uploadAttributes();
                },
                child: Container(
                  margin: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * 0.03,
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: MediaQuery.of(context).size.height * 0.01,
                    horizontal: MediaQuery.of(context).size.height * 0.02,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(
                      MediaQuery.of(context).size.height * 0.05,
                    ),
                  ),
                  child: const Text(
                    'Speichern',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
