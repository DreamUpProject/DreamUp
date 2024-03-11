import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({Key? key}) : super(key: key);

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final newPasswordOneController = TextEditingController();
  final newPasswordTwoController = TextEditingController();
  final oldPasswordController = TextEditingController();

  bool newOneObscured = true;
  bool newTwoObscured = true;
  bool oldObscured = true;

  bool allDone() {
    if (newPasswordOneController.text.isNotEmpty &&
        newPasswordTwoController.text.isNotEmpty &&
        oldPasswordController.text.isNotEmpty &&
        similar()) {
      return true;
    } else {
      return false;
    }
  }

  bool similar() {
    if (newPasswordTwoController.text.isEmpty ||
        newPasswordTwoController.text == newPasswordOneController.text) {
      return true;
    } else {
      return false;
    }
  }

  bool sending = false;

  Future updatePassword(String newPassword, String oldPassword) async {
    setState(() {
      sending = true;
    });

    var user = FirebaseAuth.instance.currentUser!;
    AuthCredential credential =
        EmailAuthProvider.credential(email: user.email!, password: oldPassword);

    try {
      await user.reauthenticateWithCredential(credential);
    } on Exception catch (e) {
      print(e);

      Fluttertoast.cancel();

      Fluttertoast.showToast(msg: '$e');

      setState(() {
        sending = false;
      });

      return;
    }

    await user.updatePassword(newPassword).then((value) {
      Fluttertoast.cancel();

      Fluttertoast.showToast(msg: 'Speichern erfolgreich!');
    });

    setState(() {
      sending = false;
    });

    Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();

    newPasswordOneController.addListener(() {
      setState(() {});
    });
    newPasswordTwoController.addListener(() {
      setState(() {});
    });
    oldPasswordController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    newPasswordOneController.dispose();
    newPasswordTwoController.dispose();
    oldPasswordController.dispose();

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
            Navigator.pop(context);
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
          'Passwort ändern',
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
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Neues Passwort',
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
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: newPasswordOneController,
                            obscureText: newOneObscured,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Neues Passwort',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal:
                                    MediaQuery.of(context).size.width * 0.03,
                              ),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: newPasswordOneController.text.isNotEmpty,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                newOneObscured
                                    ? newOneObscured = false
                                    : newOneObscured = true;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.only(
                                right: MediaQuery.of(context).size.width * 0.03,
                              ),
                              child: Icon(
                                newOneObscured
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Neues Passwort',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(
                      top: MediaQuery.of(context).size.width * 0.02,
                      bottom: MediaQuery.of(context).size.width * 0.1,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        width: 1,
                        color: similar() ? Colors.black54 : Colors.red,
                      ),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: newPasswordTwoController,
                            obscureText: true,
                            cursorColor: similar() ? null : Colors.red,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Neues Passwort wiederholen',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal:
                                    MediaQuery.of(context).size.width * 0.03,
                              ),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: newPasswordTwoController.text.isNotEmpty,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                newTwoObscured
                                    ? newTwoObscured = false
                                    : newTwoObscured = true;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.only(
                                right: MediaQuery.of(context).size.width * 0.03,
                              ),
                              child: Icon(
                                newTwoObscured
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Altes Passwort',
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
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: oldPasswordController,
                            obscureText: oldObscured,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Altes Passwort',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal:
                                    MediaQuery.of(context).size.width * 0.03,
                              ),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: oldPasswordController.text.isNotEmpty,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                oldObscured
                                    ? oldObscured = false
                                    : oldObscured = true;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.only(
                                right: MediaQuery.of(context).size.width * 0.03,
                              ),
                              child: Icon(
                                oldObscured
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Center(
                child: GestureDetector(
                  onTap: () async {
                    if (allDone()) {
                      await updatePassword(
                        newPasswordOneController.text,
                        oldPasswordController.text,
                      );
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
                          'Speichern',
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
            ],
          ),
        ),
      ),
    );
  }
}
