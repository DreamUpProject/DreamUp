import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:friendivity/main.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({Key? key}) : super(key: key);

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final passwordController = TextEditingController();

  bool passwordObscured = true;

  bool sending = false;

  Future deleteAccount(String password) async {
    setState(() {
      sending = true;
    });

    var user = FirebaseAuth.instance.currentUser!;
    AuthCredential credential =
        EmailAuthProvider.credential(email: user.email!, password: password);

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

    CurrentUser.deleteAccount(context);

    Navigator.pop(context);
    Navigator.pop(context);
    Navigator.pop(context);
    Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();

    passwordController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    passwordController.dispose();

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
          'Konto löschen',
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
              const Text(
                'Du bist gerade dabei dein Konto zu löschen. Dadurch werden alle deine Kontodaten und alle deine erstellten Vibes. Wenn du den Löschvorgang bestätigt hast, kannst du deine Daten nicht wiederherstellen. Wenn du dir sicher bist, dass du deine Daten löschen möchtest, bestätige dies bitte mit deinem Passwort.',
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.width * 0.05,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Passwort',
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
                            controller: passwordController,
                            obscureText: passwordObscured,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Passwort',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal:
                                    MediaQuery.of(context).size.width * 0.03,
                              ),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: passwordController.text.isNotEmpty,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                passwordObscured
                                    ? passwordObscured = false
                                    : passwordObscured = true;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.only(
                                right: MediaQuery.of(context).size.width * 0.03,
                              ),
                              child: Icon(
                                passwordObscured
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
                    await deleteAccount(passwordController.text);
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
                      color: passwordController.text.isNotEmpty
                          ? Colors.red
                          : Colors.black26,
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
                          'Löschen',
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
