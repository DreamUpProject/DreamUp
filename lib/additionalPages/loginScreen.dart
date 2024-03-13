import 'package:auto_size_text/auto_size_text.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:friendivity/utils/forgotPassword.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../utils/contactSupport.dart';

//region Global Variables
String video = 'assets/videos/JacobVersionCropped.mp4';
//endregion

//region UI Logic
class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String status = 'signUp';
  bool screenTapped = false;
  String chosenProvider = 'email';

  bool typing = false;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  late FocusNode passwordFocus;

  bool isPasswordVisible = false;

  Future signIn() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      print(e);

      if (e.code == 'user-disabled') {
        showDialog(
          context: context,
          builder: (context) {
            return Dialog(
              insetPadding: EdgeInsets.all(
                MediaQuery.of(context).size.width * 0.05,
              ),
              child: Container(
                padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width * 0.05,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Du wurdest gesperrt!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.width * 0.05,
                    ),
                    const Text(
                      'Wie es aussieht, bist du von unserem System gesperrt worden. Wende dich bei Fragen bitte an unseren Support!',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ContactSupportPage(),
                          ),
                        );
                      },
                      child: Container(
                        color: Colors.transparent,
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.width * 0.05,
                        ),
                        child: const Text(
                          'Support kontaktieren',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.width * 0.02,
                          horizontal: MediaQuery.of(context).size.width * 0.05,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            MediaQuery.of(context).size.width * 0.02,
                          ),
                          color: Colors.grey,
                          border: Border.all(
                            color: Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'OK',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else if (e.code == 'user-not-found') {
        showDialog(
          context: context,
          builder: (context) {
            return Dialog(
              insetPadding: EdgeInsets.all(
                MediaQuery.of(context).size.width * 0.05,
              ),
              child: Container(
                padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width * 0.05,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Nutzer nicht gefunden!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.width * 0.05,
                    ),
                    const Text(
                      'Mit der angegebenen Mail-Adresse ist kein Account verknüpft!',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        status = 'signUp';

                        setState(() {});

                        Navigator.pop(context);
                      },
                      child: Container(
                        color: Colors.transparent,
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.width * 0.05,
                        ),
                        child: const Text(
                          'Account erstellen',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.width * 0.02,
                          horizontal: MediaQuery.of(context).size.width * 0.05,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            MediaQuery.of(context).size.width * 0.02,
                          ),
                          color: Colors.grey,
                          border: Border.all(
                            color: Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'OK',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else if (e.code == 'wrong-password') {
        showDialog(
          context: context,
          builder: (context) {
            return Dialog(
              insetPadding: EdgeInsets.all(
                MediaQuery.of(context).size.width * 0.05,
              ),
              child: Container(
                padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width * 0.05,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Falsches Passwort!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.width * 0.05,
                    ),
                    const Text(
                      'Das von dir angegebene Passwort ist nicht korrekt. Bitte überprüfe es auf mögliche Schreibfehler!',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordPage(),
                          ),
                        );
                      },
                      child: Container(
                        color: Colors.transparent,
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.width * 0.05,
                        ),
                        child: const Text(
                          'Passwort zurücksetzen',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.width * 0.02,
                          horizontal: MediaQuery.of(context).size.width * 0.05,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            MediaQuery.of(context).size.width * 0.02,
                          ),
                          color: Colors.grey,
                          border: Border.all(
                            color: Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'OK',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else if (e.code == 'invalid-email') {
        showDialog(
          context: context,
          builder: (context) {
            return Dialog(
              insetPadding: EdgeInsets.all(
                MediaQuery.of(context).size.width * 0.05,
              ),
              child: Container(
                padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width * 0.05,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Ungültige E-Mail!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.width * 0.05,
                    ),
                    const Text(
                      'Die von dir angegebene E-Mail Adresse scheint nicht gültig zu sein. Bitte gib eine gültige Adresse an!',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ContactSupportPage(),
                          ),
                        );
                      },
                      child: Container(
                        color: Colors.transparent,
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.width * 0.05,
                        ),
                        child: const Text(
                          'Support kontaktieren',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.width * 0.02,
                          horizontal: MediaQuery.of(context).size.width * 0.05,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            MediaQuery.of(context).size.width * 0.02,
                          ),
                          color: Colors.grey,
                          border: Border.all(
                            color: Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'OK',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    }
  }

  Future signUp() async {
    try {
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          )
          .then((value) => createUser(mail: emailController.text));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        showDialog(
          context: context,
          builder: (context) {
            return Dialog(
              insetPadding: EdgeInsets.all(
                MediaQuery.of(context).size.width * 0.05,
              ),
              child: Container(
                padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width * 0.05,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'E-Mail wird bereits verwendet!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.width * 0.05,
                    ),
                    const Text(
                      'Die angegebene Mail-Adresse ist bereits mit einem Account verknüpft.',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        status = 'signIn';

                        Navigator.pop(context);
                      },
                      child: Container(
                        color: Colors.transparent,
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.width * 0.05,
                        ),
                        child: const Text(
                          'Ich habe bereits einen Account',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.width * 0.02,
                          horizontal: MediaQuery.of(context).size.width * 0.05,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            MediaQuery.of(context).size.width * 0.02,
                          ),
                          color: Colors.grey,
                          border: Border.all(
                            color: Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'OK',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else if (e.code == 'weak-password') {
        showDialog(
          context: context,
          builder: (context) {
            return Dialog(
              insetPadding: EdgeInsets.all(
                MediaQuery.of(context).size.width * 0.05,
              ),
              child: Container(
                padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width * 0.05,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Passwort zu schwach!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.width * 0.05,
                    ),
                    const Text(
                      'Dein gewähltes Passwort ist nicht stark und somit nicht sicher genug. Bitte wähle ein Passwort, welches aus mindestens sechs Zeichen besteht.',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.width * 0.05,
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.width * 0.02,
                          horizontal: MediaQuery.of(context).size.width * 0.05,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            MediaQuery.of(context).size.width * 0.02,
                          ),
                          color: Colors.grey,
                          border: Border.all(
                            color: Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'OK',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else if (e.code == 'invalid-email') {
        showDialog(
          context: context,
          builder: (context) {
            return Dialog(
              insetPadding: EdgeInsets.all(
                MediaQuery.of(context).size.width * 0.05,
              ),
              child: Container(
                padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width * 0.05,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Ungültige E-Mail',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.width * 0.05,
                    ),
                    const Text(
                      'Bitte gib eine korrekte E-Mail Adresse an.',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.width * 0.05,
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.width * 0.02,
                          horizontal: MediaQuery.of(context).size.width * 0.05,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            MediaQuery.of(context).size.width * 0.02,
                          ),
                          color: Colors.grey,
                          border: Border.all(
                            color: Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'OK',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    }
  }

  Future createUser({required String mail}) async {
    CollectionReference users = FirebaseFirestore.instance.collection('users');

    final FirebaseAuth auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    final id = user?.uid;

    var docs = await users.get();

    var number = docs.docs.length;

    var newUser = users.doc(id);

    final json = {
      'email': mail,
      'id': id,
      'imageLink':
          'https://firebasestorage.googleapis.com/v0/b/activities-with-friends.appspot.com/o/placeholderImages%2FuserPlaceholder.png?alt=media&token=1a4e6423-446d-48b5-8bbf-466900c350ec',
      'name': 'User ${number + 1}',
    };

    await newUser.set(json);
  }

  final Future<SharedPreferences> prefs = SharedPreferences.getInstance();

  String mail = '';
  String password = '';
  bool isSaving = false;
  bool existing = false;

  bool keyBoardOpen = false;

  Future setLogInData() async {
    final SharedPreferences sharedPrefs = await prefs;

    if (isSaving) {
      print('is saving');

      sharedPrefs.setString('mail', emailController.text.trim());
      sharedPrefs.setString('password', passwordController.text.trim());
    } else {
      print('is not saving');

      sharedPrefs.remove('mail');
      sharedPrefs.remove('password');
    }
  }

  Widget LoginProviderWidget(BuildContext context, String provider) {
    double padding = MediaQuery.of(context).size.width / 6 / 4;

    if (provider == 'email') {
      return Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                height: padding * 0.5,
              ),
              SizedBox(
                height: MediaQuery.of(context).size.width / 7,
                width: MediaQuery.of(context).size.width - padding * 4,
                child: TextField(
                  style: const TextStyle(
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black87,
                        blurRadius: 10,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                  autocorrect: false,
                  maxLines: 1,
                  onTap: () {
                    setState(() {
                      typing = true;
                    });
                  },
                  controller: emailController,
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    hoverColor: Colors.white,
                    focusColor: Colors.white,
                    prefixIconColor: Colors.white,
                    labelText: 'Email',
                    labelStyle: const TextStyle(
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black87,
                          blurRadius: 10,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                    prefixIcon: const Icon(
                      Icons.mail,
                      color: Colors.white,
                    ),
                    // suffixIcon: emailController.text.isEmpty
                    //     ? Container(
                    //         width: 0,
                    //       )
                    //     : IconButton(
                    //         icon: const Icon(
                    //           Icons.close,
                    //           color: Colors.white,
                    //         ),
                    //         onPressed: () {
                    //           FocusManager.instance.primaryFocus?.unfocus();
                    //
                    //           emailController.clear();
                    //
                    //           setState(() {
                    //             typing = false;
                    //           });
                    //         },
                    //       ),

                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.white,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.white,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (string) {
                    passwordFocus.requestFocus();
                  },
                ),
              ),
              SizedBox(
                height: padding,
              ),
              SizedBox(
                height: MediaQuery.of(context).size.width / 7,
                width: MediaQuery.of(context).size.width - padding * 4,
                child: TextField(
                  focusNode: passwordFocus,
                  style: const TextStyle(
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black87,
                        blurRadius: 10,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                  autocorrect: false,
                  onTap: () {
                    setState(() {
                      typing = true;
                    });
                  },
                  onSubmitted: (string) {
                    setState(() {
                      typing = false;
                    });

                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  controller: passwordController,
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    prefixIconColor: Colors.white,
                    labelText: 'Passwort',
                    labelStyle: const TextStyle(
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black87,
                          blurRadius: 10,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                    prefixIcon: const Icon(
                      Icons.vpn_key_rounded,
                      color: Colors.white,
                    ),
                    suffixIcon: passwordController.text.isEmpty
                        ? Container(
                            width: 0,
                          )
                        : IconButton(
                            icon: isPasswordVisible
                                ? const Icon(
                                    Icons.visibility_off,
                                    color: Colors.white,
                                  )
                                : const Icon(
                                    Icons.visibility,
                                    color: Colors.white,
                                  ),
                            onPressed: () => setState(
                              () => isPasswordVisible = !isPasswordVisible,
                            ),
                          ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: Colors.white, width: 3),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: Colors.white, width: 3),
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  obscureText: !isPasswordVisible,
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.done,
                ),
              ),
              GestureDetector(
                onTap: () async {
                  setState(() {
                    isSaving ? isSaving = false : isSaving = true;
                  });

                  final SharedPreferences sharedPrefs = await prefs;

                  sharedPrefs.setBool('saving', isSaving);
                },
                child: Container(
                  color: Colors.transparent,
                  padding: EdgeInsets.only(
                    bottom: padding,
                  ),
                  width: MediaQuery.of(context).size.width - padding * 4,
                  child: Row(
                    children: [
                      Checkbox(
                        value: isSaving,
                        onChanged: (value) async {
                          setState(() {
                            isSaving = value!;
                          });

                          final SharedPreferences sharedPrefs = await prefs;

                          sharedPrefs.setBool('saving', value!);
                        },
                        side: const BorderSide(
                          color: Colors.white,
                          width: 2,
                        ),
                        shape: const CircleBorder(),
                        activeColor: Colors.white,
                        checkColor: Colors.black,
                        focusColor: Colors.white,
                        hoverColor: Colors.white,
                      ),
                      const Text(
                        'Einlogdaten speichern',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          shadows: [
                            Shadow(
                              color: Colors.black87,
                              blurRadius: 10,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  if (status == 'signIn') {
                    await setLogInData();

                    signIn();
                  } else {
                    await setLogInData();

                    signUp();
                  }
                },
                child: Container(
                  margin: EdgeInsets.only(
                    left: padding * 2,
                    right: padding * 2,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Container(
                      color: const Color(0xFF5E70EC),
                      padding: EdgeInsets.symmetric(
                        vertical: MediaQuery.of(context).size.width * 0.05,
                      ),
                      child: Center(
                        child: AutoSizeText(
                          status == 'signUp' ? 'Registrieren' : 'Einloggen',
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.width * 0.1,
              ),
            ],
          ),
        ],
      );
    } else {
      return Container();
    }
  }

  final CarouselController carouselController = CarouselController();

  @override
  void initState() {
    super.initState();

    emailController.addListener(() => setState(() {}));
    passwordController.addListener(() => setState(() {}));

    passwordFocus = FocusNode();

    prefs.then((value) {
      mail = value.getString('mail') ?? '';
      password = value.getString('password') ?? '';
      isSaving = value.getBool('saving') ?? false;

      if (mounted && mail != '' && password != '') {
        existing = true;

        emailController.text = mail;
        passwordController.text = password;

        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();

    passwordFocus.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(
              child: AssetPlayerWidget(),
            ),
            Positioned.fill(
              child: Container(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: () {
                    if (!screenTapped) {
                      screenTapped = true;
                    }

                    FocusManager.instance.primaryFocus?.unfocus();

                    setState(() {
                      typing = false;
                    });
                  },
                ),
              ),
            ),
            Positioned.fill(
              child: Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).padding.top,
                  ),
                  Visibility(
                    visible: !typing,
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      padding: EdgeInsets.only(
                        left: MediaQuery.of(context).size.width * 0.1,
                        right: MediaQuery.of(context).size.width * 0.1,
                        top: MediaQuery.of(context).size.width * 0.05,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Do things \nyou enjoy.',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: <Shadow>[
                                Shadow(
                                  offset: Offset(3.0, 3.0),
                                  blurRadius: 3.0,
                                  color: Colors.black87,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 500),
                            opacity: screenTapped ? 1 : 0,
                            child: const Text(
                              'But do them \ntogether.',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: <Shadow>[
                                  Shadow(
                                    offset: Offset(3.0, 3.0),
                                    blurRadius: 3.0,
                                    color: Colors.black87,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (!screenTapped) {
                          screenTapped = true;
                        }

                        FocusManager.instance.primaryFocus?.unfocus();

                        setState(() {
                          typing = false;
                        });
                      },
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 500),
                        opacity: screenTapped ? 1 : 0,
                        child: CarouselSlider(
                          carouselController: carouselController,
                          items: [
                            Container(
                              alignment: Alignment.bottomCenter,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.width / 7,
                                    width:
                                        MediaQuery.of(context).size.width * 0.8,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        !existing
                                            ? status = 'signUp'
                                            : 'signIn';

                                        setState(() {});

                                        if (!existing) {
                                          status = 'signUp';

                                          emailController.text = '';
                                          passwordController.text = '';

                                          setState(() {});

                                          carouselController.animateToPage(1);
                                        } else {
                                          status = 'signIn';

                                          setState(() {});

                                          carouselController.animateToPage(1);
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        enableFeedback: false,
                                        backgroundColor:
                                            const Color(0xFF1E1E1E),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: Text(
                                        !existing ? 'SIGN UP' : 'LOGIN',
                                        style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: MediaQuery.of(context).size.width *
                                        0.03,
                                  ),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.width / 7,
                                    width:
                                        MediaQuery.of(context).size.width * 0.8,
                                    child: TextButton(
                                      onPressed: () {
                                        !existing
                                            ? status = 'signIn'
                                            : 'signUp';

                                        setState(() {});

                                        if (!existing) {
                                          status = 'signIn';

                                          setState(() {});

                                          carouselController.animateToPage(1);
                                        } else {
                                          status = 'signUp';

                                          emailController.text = '';
                                          passwordController.text = '';

                                          setState(() {});

                                          carouselController.animateToPage(1);
                                        }
                                      },
                                      style: TextButton.styleFrom(
                                        enableFeedback: false,
                                      ),
                                      child: Text(
                                        !existing ? 'LOGIN' : 'SIGN UP',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
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
                                    ),
                                  ),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.width * 0.1,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              alignment: Alignment.bottomCenter,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      chosenProvider = 'email';

                                      setState(() {});

                                      carouselController.animateToPage(2);
                                    },
                                    child: Container(
                                      margin: EdgeInsets.only(
                                        top: MediaQuery.of(context).size.width *
                                            0.05,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal:
                                            MediaQuery.of(context).size.width *
                                                0.05,
                                      ),
                                      height:
                                          MediaQuery.of(context).size.width *
                                              0.175,
                                      width: MediaQuery.of(context).size.width *
                                          0.8,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          MediaQuery.of(context).size.width *
                                              0.03,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.mail_rounded,
                                            size: 30,
                                          ),
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.05,
                                          ),
                                          Text(
                                            status == 'signUp'
                                                ? 'SignUp mit Email'
                                                : 'Login mit Email',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      // not functional on iPhone yet, so disabled

                                      // final provider = Provider.of<
                                      //     GoogleAuthenticationProvider>(
                                      //   context,
                                      //   listen: false,
                                      // );
                                      //
                                      // provider.googleLogin();
                                    },
                                    child: Container(
                                      margin: EdgeInsets.only(
                                        top: MediaQuery.of(context).size.width *
                                            0.05,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal:
                                            MediaQuery.of(context).size.width *
                                                0.05,
                                      ),
                                      height:
                                          MediaQuery.of(context).size.width *
                                              0.175,
                                      width: MediaQuery.of(context).size.width *
                                          0.8,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          MediaQuery.of(context).size.width *
                                              0.03,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const FaIcon(
                                            FontAwesomeIcons.google,
                                            size: 30,
                                          ),
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.05,
                                          ),
                                          Text(
                                            status == 'signUp'
                                                ? 'SignUp mit Google'
                                                : 'Login mit Google',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(
                                      top: MediaQuery.of(context).size.width *
                                          0.05,
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal:
                                          MediaQuery.of(context).size.width *
                                              0.05,
                                    ),
                                    height: MediaQuery.of(context).size.width *
                                        0.175,
                                    width:
                                        MediaQuery.of(context).size.width * 0.8,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                        MediaQuery.of(context).size.width *
                                            0.03,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const FaIcon(
                                          FontAwesomeIcons.apple,
                                          size: 35,
                                        ),
                                        SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.05,
                                        ),
                                        Text(
                                          status == 'signUp'
                                              ? 'SignUp mit Apple'
                                              : 'Login mit Apple',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.width * 0.1,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              alignment: Alignment.bottomCenter,
                              child:
                                  LoginProviderWidget(context, chosenProvider),
                            ),
                          ],
                          options: CarouselOptions(
                            height: double.infinity,
                            viewportFraction: 1,
                            enableInfiniteScroll: false,
                          ),
                        ),
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

//region Widgets
class AssetPlayerWidget extends StatefulWidget {
  const AssetPlayerWidget({Key? key}) : super(key: key);

  @override
  _AssetPlayerWidgetState createState() => _AssetPlayerWidgetState();
}

class _AssetPlayerWidgetState extends State<AssetPlayerWidget> {
  late VideoPlayerController controller;

  @override
  void initState() {
    super.initState();
    controller = VideoPlayerController.asset(video)
      ..addListener(() => setState(() {}))
      ..setLooping(true)
      ..setVolume(1)
      ..initialize().then((_) => setState(() {}))
      ..play();
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VideoPlayerWidget(controller: controller);
  }
}

class VideoPlayerWidget extends StatelessWidget {
  final VideoPlayerController controller;

  const VideoPlayerWidget({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topCenter,
      child: buildVideo(),
    );
  }

  Widget buildVideo() => buildVideoPlayer();

  Widget buildVideoPlayer() => VideoPlayer(controller);
}
//endregion

//region Business Logic
class GoogleAuthenticationProvider extends ChangeNotifier {
  final googleSignIn = GoogleSignIn();

  GoogleSignInAccount? _user;

  GoogleSignInAccount get user => _user!;

  Future googleLogin() async {
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return;
    _user = googleUser;

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    var result = await FirebaseAuth.instance.signInWithCredential(credential);

    if (result.additionalUserInfo!.isNewUser) {
      await createUser(mail: _user!.email);
    }

    notifyListeners();
  }

  Future googleLogOut() async {
    await googleSignIn.disconnect();
  }

  Future createUser({required String mail}) async {
    CollectionReference users = FirebaseFirestore.instance.collection('users');

    final FirebaseAuth auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    final id = user?.uid;

    var docs = await users.get();

    var number = docs.docs.length;

    var newUser = users.doc(id);

    final json = {
      'email': mail,
      'id': id,
      'imageLink':
          'https://firebasestorage.googleapis.com/v0/b/activities-with-friends.appspot.com/o/userPlaceholder.png?alt=media&token=1a4e6423-446d-48b5-8bbf-466900c350ec',
      'name': 'User ${number + 1}',
      'bio': 'Hi! Ich freue mich hier auf coole Leute zu treffen!',
    };

    await newUser.set(json);
  }
}
//endregion
