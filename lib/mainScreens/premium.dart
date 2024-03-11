import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:friendivity/main.dart';

class DatePreferenceScreen extends StatefulWidget {
  const DatePreferenceScreen({Key? key}) : super(key: key);

  @override
  State<DatePreferenceScreen> createState() => _DatePreferenceScreenState();
}

class _DatePreferenceScreenState extends State<DatePreferenceScreen> {
  bool hasGender = CurrentUser.gender != null && CurrentUser.gender != '';

  int currentStep = 0;

  String changedGender = '';

  List<String> PotentialPartners = [];

  bool settingsDone = false;

  String preferences() {
    if (PotentialPartners.length == 1) {
      return 'ausschließlich ${PotentialPartners[0]}e';
    } else if (PotentialPartners.length == 2) {
      return '${PotentialPartners[0]}e und ${PotentialPartners[1]}e';
    } else {
      return '${PotentialPartners[0]}e, ${PotentialPartners[1]}e und ${PotentialPartners[2]}e';
    }
  }

  String gender() {
    var gender = CurrentUser.gender;

    if (changedGender != '') {
      return changedGender;
    }

    if (gender == 'male') {
      return 'männlich';
    } else if (gender == 'female') {
      return 'weiblich';
    } else if (gender == 'diverse') {
      return 'divers';
    } else {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    print(CurrentUser.gender);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(
              context,
              true,
            );
          },
          child: Container(
            color: Colors.transparent,
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black87,
            ),
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Date Präferenzen',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        padding: EdgeInsets.all(
          MediaQuery.of(context).size.width * 0.05,
        ),
        child: Column(
          children: [
            const Text(
              'Vielen Dank, dass du unser Premium-Paket erworben hast! Du bist dadurch nun in der Lage, die Datings- und Beziehungsservices von DreamUp zu nutzen. Beantworte dazu bitte noch ein paar Fragen.',
              style: TextStyle(
                fontSize: 18,
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.width * 0.05,
            ),
            !settingsDone
                ? Expanded(
                    child: Stepper(
                      currentStep: currentStep,
                      onStepTapped: (index) {
                        currentStep = index;

                        setState(() {});
                      },
                      controlsBuilder: (context, details) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Visibility(
                              visible: currentStep == 0
                                  ? hasGender
                                  : PotentialPartners.isNotEmpty,
                              child: GestureDetector(
                                onTap: () {
                                  if (currentStep == 0) {
                                    currentStep++;
                                  } else {
                                    settingsDone = true;
                                  }

                                  setState(() {});
                                },
                                child: Container(
                                  margin: EdgeInsets.only(
                                    top: MediaQuery.of(context).size.width *
                                        0.05,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.blueAccent,
                                  ),
                                  child: const Text(
                                    'Bestätigen',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: hasGender && currentStep != 1,
                              child: GestureDetector(
                                onTap: () {
                                  hasGender = false;

                                  setState(() {});
                                },
                                child: Container(
                                  margin: EdgeInsets.only(
                                    top: MediaQuery.of(context).size.width *
                                        0.05,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.transparent,
                                  ),
                                  child: const Text(
                                    'Ändern',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                      steps: [
                        Step(
                          title: const Text(
                            'Dein Geschlecht',
                            style: TextStyle(
                              fontSize: 20,
                            ),
                          ),
                          content: hasGender
                              ? Text(
                                  'Laut deiner Angaben identifizierst du dich selbst als "${gender()}". Ist das richtig?',
                                  style: const TextStyle(
                                    fontSize: 16,
                                  ),
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Bitte gib das Geschlecht an, mit welchem du dich identifizierst.',
                                      style: TextStyle(
                                        fontSize: 16,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        hasGender = true;

                                        changedGender = 'männlich';

                                        setState(() {});
                                      },
                                      child: Row(
                                        children: [
                                          Radio(
                                            value: 'männlich',
                                            groupValue: changedGender,
                                            onChanged: (String? value) {
                                              hasGender = true;

                                              changedGender = value!;

                                              setState(() {});
                                            },
                                          ),
                                          const Text(
                                            'männlich',
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        hasGender = true;

                                        changedGender = 'weiblich';

                                        setState(() {});
                                      },
                                      child: Row(
                                        children: [
                                          Radio(
                                            value: 'weiblich',
                                            groupValue: changedGender,
                                            onChanged: (String? value) {
                                              hasGender = true;

                                              changedGender = value!;

                                              setState(() {});
                                            },
                                          ),
                                          const Text(
                                            'weiblich',
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        hasGender = true;

                                        changedGender = 'divers';

                                        setState(() {});
                                      },
                                      child: Row(
                                        children: [
                                          Radio(
                                            value: 'divers',
                                            groupValue: changedGender,
                                            onChanged: (String? value) {
                                              hasGender = true;

                                              changedGender = value!;

                                              setState(() {});
                                            },
                                          ),
                                          const Text(
                                            'divers',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        Step(
                          title: const Text(
                            'Wen suchst du?',
                            style: TextStyle(
                              fontSize: 20,
                            ),
                          ),
                          content: Column(
                            children: [
                              const Text(
                                'Sehr gut. Nun teile uns bitte mit, nach welchen Geschlechtern wir für dich suchen sollen. Du kannst mehrere Optionen auswählen.',
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  if (!PotentialPartners.contains('männlich')) {
                                    PotentialPartners.add('männlich');
                                  } else {
                                    PotentialPartners.remove('männlich');
                                  }

                                  setState(() {});
                                },
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: PotentialPartners.contains(
                                          'männlich'),
                                      onChanged: (value) {
                                        if (value != null) {
                                          if (value) {
                                            if (!PotentialPartners.contains(
                                                'männlich')) {
                                              PotentialPartners.add('männlich');
                                            }
                                          } else {
                                            PotentialPartners.remove(
                                                'männlich');
                                          }
                                          setState(() {});
                                        }
                                      },
                                    ),
                                    const Text(
                                      'männlich',
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  if (!PotentialPartners.contains('weiblich')) {
                                    PotentialPartners.add('weiblich');
                                  } else {
                                    PotentialPartners.remove('weiblich');
                                  }

                                  setState(() {});
                                },
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: PotentialPartners.contains(
                                          'weiblich'),
                                      onChanged: (value) {
                                        if (value != null) {
                                          if (value) {
                                            if (!PotentialPartners.contains(
                                                'weiblich')) {
                                              PotentialPartners.add('weiblich');
                                            }
                                          } else {
                                            PotentialPartners.remove(
                                                'weiblich');
                                          }
                                          setState(() {});
                                        }
                                      },
                                    ),
                                    const Text(
                                      'weiblich',
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  if (!PotentialPartners.contains('divers')) {
                                    PotentialPartners.add('divers');
                                  } else {
                                    PotentialPartners.remove('divers');
                                  }

                                  setState(() {});
                                },
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value:
                                          PotentialPartners.contains('divers'),
                                      onChanged: (value) {
                                        if (value != null) {
                                          if (value) {
                                            if (!PotentialPartners.contains(
                                                'divers')) {
                                              PotentialPartners.add('divers');
                                            }
                                          } else {
                                            PotentialPartners.remove('divers');
                                          }

                                          setState(() {});
                                        }
                                      },
                                    ),
                                    const Text(
                                      'divers',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Danke! Hier sind noch einmal deine Angaben zusammengefasst:',
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.width * 0.03,
                      ),
                      Text(
                        'Du identifizierst dich selbst als ${gender()} und möchtest ${preferences()} Nutzer angezeigt bekommen.',
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              Map<String, dynamic> userData = {};

                              if (changedGender != '') {
                                if (changedGender == 'weiblich') {
                                  userData.addAll({'gender': 'female'});

                                  CurrentUser.gender = 'female';
                                } else if (changedGender == 'männlich') {
                                  userData.addAll({'gender': 'male'});

                                  CurrentUser.gender = 'male';
                                } else if (changedGender == 'divers') {
                                  userData.addAll({'gender': 'diverse'});

                                  CurrentUser.gender = 'diverse';
                                }
                              }

                              List prefs = [];

                              CurrentUser.genderPrefs.clear();

                              for (var pref in PotentialPartners) {
                                if (pref == 'weiblich') {
                                  prefs.addAll({'female'});

                                  CurrentUser.genderPrefs.add('female');
                                } else if (pref == 'männlich') {
                                  prefs.addAll({'male'});

                                  CurrentUser.genderPrefs.add('male');
                                } else if (pref == 'divers') {
                                  prefs.addAll({'diverse'});

                                  CurrentUser.genderPrefs.add('diverse');
                                }
                              }

                              userData.addAll(
                                {
                                  'genderPrefs': prefs,
                                  'hasPremium': true,
                                },
                              );

                              CurrentUser.hasPremium = true;

                              CurrentUser().saveUserInformation();

                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(FirebaseAuth.instance.currentUser!.uid)
                                  .update(userData);

                              Navigator.pop(
                                context,
                                true,
                              );
                            },
                            child: Container(
                              margin: EdgeInsets.only(
                                top: MediaQuery.of(context).size.width * 0.05,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.blueAccent,
                              ),
                              child: const Text(
                                'Bestätigen',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              settingsDone = false;

                              currentStep = 0;

                              setState(() {});
                            },
                            child: Container(
                              margin: EdgeInsets.only(
                                top: MediaQuery.of(context).size.width * 0.05,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.transparent,
                              ),
                              child: const Text(
                                'Ändern',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
