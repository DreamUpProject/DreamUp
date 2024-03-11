import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:friendivity/main.dart';
import 'package:http/http.dart';

/// Dieses Feature ist funktional, jedoch momentan noch nicht auf viele User
/// ausgelegt. Hierbei handelt es sich eher um einen Test, als um die spätere,
/// tatsächliche Umsetzung.

class ContactSupportPage extends StatefulWidget {
  const ContactSupportPage({Key? key}) : super(key: key);

  @override
  State<ContactSupportPage> createState() => _ContactSupportPageState();
}

class _ContactSupportPageState extends State<ContactSupportPage> {
  final nameController = TextEditingController();
  final mailController = TextEditingController();
  final subjectController = TextEditingController();
  final messageController = TextEditingController();

  String activeField = '';

  bool loggedIn = FirebaseAuth.instance.currentUser != null;

  bool allDone() {
    if (loggedIn) {
      if (subjectController.text.isNotEmpty &&
          messageController.text.isNotEmpty) {
        return true;
      } else {
        return false;
      }
    } else {
      if (nameController.text.isNotEmpty &&
          mailController.text.isNotEmpty &&
          subjectController.text.isNotEmpty &&
          messageController.text.isNotEmpty) {
        return true;
      } else {
        return false;
      }
    }
  }

  bool sending = false;

  Future sendMail(
      {required String name,
      required String mail,
      required String subject,
      required String message}) async {
    var serviceId = 'service_8dc7x3u';
    var templateId = 'template_dljk07g';
    var userId = 'VZSd8MBe07PWUZK6E';

    setState(() {
      sending = true;
    });

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    await post(
      url,
      headers: {
        'origin': 'https://localhost',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'service_id': serviceId,
        'template_id': templateId,
        'template_params': {
          'name': name,
          'mail': mail,
          'subject': subject,
          'message': message,
          'id': loggedIn ? FirebaseAuth.instance.currentUser?.uid : '',
        },
        'user_id': userId,
      }),
    ).then((value) => setState(() {
          sending = false;
        }));
  }

  @override
  void initState() {
    super.initState();

    nameController.addListener(() {
      setState(() {});
    });
    mailController.addListener(() {
      setState(() {});
    });
    subjectController.addListener(() {
      setState(() {});
    });
    messageController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    mailController.dispose();
    subjectController.dispose();
    messageController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white.withOpacity(0.95),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            if (activeField == '') {
              Navigator.pop(context);
            } else {
              FocusManager.instance.primaryFocus?.unfocus();

              setState(() {
                activeField = '';
              });
            }
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
          'Kontaktformular',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SizedBox.expand(
        child: Container(
          padding: EdgeInsets.fromLTRB(
            MediaQuery.of(context).size.width * 0.05,
            MediaQuery.of(context).size.width * 0.05,
            MediaQuery.of(context).size.width * 0.05,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Visibility(
                visible: activeField == '' || activeField == 'name',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Name',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(
                        top: MediaQuery.of(context).size.width * 0.02,
                        bottom: MediaQuery.of(context).size.width * 0.05,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          width: 1,
                          color: Colors.black54,
                        ),
                        color: Colors.white,
                      ),
                      child: TextField(
                        controller: nameController,
                        onTap: () {
                          setState(() {
                            activeField = 'name';
                          });
                        },
                        onSubmitted: (text) {
                          setState(() {
                            activeField = '';
                          });
                        },
                        enableSuggestions: true,
                        autocorrect: true,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: loggedIn ? CurrentUser.name : 'Name',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal:
                                MediaQuery.of(context).size.width * 0.03,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Visibility(
                visible: activeField == '' || activeField == 'mail',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(
                        top: MediaQuery.of(context).size.width * 0.02,
                        bottom: MediaQuery.of(context).size.width * 0.05,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          width: 1,
                          color: Colors.black54,
                        ),
                        color: Colors.white,
                      ),
                      child: TextField(
                        controller: mailController,
                        onTap: () {
                          setState(() {
                            activeField = 'mail';
                          });
                        },
                        onSubmitted: (text) {
                          setState(() {
                            activeField = '';
                          });
                        },
                        keyboardType: TextInputType.emailAddress,
                        enableSuggestions: true,
                        autocorrect: true,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: loggedIn
                              ? FirebaseAuth.instance.currentUser?.email
                              : 'Email',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal:
                                MediaQuery.of(context).size.width * 0.03,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Visibility(
                visible: activeField == '' || activeField == 'subject',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Anliegen',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(
                        top: MediaQuery.of(context).size.width * 0.02,
                        bottom: MediaQuery.of(context).size.width * 0.05,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          width: 1,
                          color: Colors.black54,
                        ),
                        color: Colors.white,
                      ),
                      child: TextField(
                        controller: subjectController,
                        onTap: () {
                          setState(() {
                            activeField = 'subject';
                          });
                        },
                        onSubmitted: (text) {
                          setState(() {
                            activeField = '';
                          });
                        },
                        enableSuggestions: true,
                        autocorrect: true,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Anliegen',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal:
                                MediaQuery.of(context).size.width * 0.03,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Visibility(
                  visible: activeField == '' || activeField == 'message',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nachricht',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.only(
                            top: MediaQuery.of(context).size.width * 0.02,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              width: 1,
                              color: Colors.black54,
                            ),
                            color: Colors.white,
                          ),
                          child: TextField(
                            controller: messageController,
                            onTap: () {
                              setState(() {
                                activeField = 'message';
                              });
                            },
                            onSubmitted: (text) {
                              setState(() {
                                activeField = '';
                              });
                            },
                            enableSuggestions: true,
                            autocorrect: true,
                            textCapitalization: TextCapitalization.sentences,
                            expands: true,
                            minLines: null,
                            maxLines: null,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Nachricht',
                              contentPadding: EdgeInsets.all(
                                MediaQuery.of(context).size.width * 0.03,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: activeField == 'message',
                        child: GestureDetector(
                          onTap: () {
                            FocusManager.instance.primaryFocus?.unfocus();

                            setState(() {
                              activeField = '';
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical:
                                  MediaQuery.of(context).size.width * 0.05,
                            ),
                            color: Colors.transparent,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(),
                                ),
                                const Text(
                                  'Fertig',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                    fontSize: 16,
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
              Visibility(
                visible: activeField == '',
                child: Center(
                  child: GestureDetector(
                    onTap: () async {
                      if (allDone()) {
                        await sendMail(
                          name: loggedIn
                              ? CurrentUser.name!
                              : nameController.text,
                          mail: loggedIn
                              ? FirebaseAuth.instance.currentUser!.email!
                              : mailController.text,
                          subject: subjectController.text,
                          message: messageController.text,
                        ).then((value) {
                          Fluttertoast.cancel();

                          Fluttertoast.showToast(
                              msg: 'Nachricht wurde gesendet!');

                          Navigator.pop(context);
                        });
                      }
                    },
                    child: Container(
                      margin: EdgeInsets.all(
                        MediaQuery.of(context).size.width * 0.05,
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: MediaQuery.of(context).size.width * 0.02,
                        horizontal: MediaQuery.of(context).size.width * 0.05,
                      ),
                      decoration: BoxDecoration(
                        color: allDone() ? Colors.blue : Colors.black26,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Visibility(
                            visible: sending,
                            child: Container(
                              margin: EdgeInsets.only(
                                right: MediaQuery.of(context).size.width * 0.02,
                              ),
                              child: const Center(
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Text(
                            'Abschicken',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
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
