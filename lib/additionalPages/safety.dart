import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';

import '../main.dart';
import '../utils/changePassword.dart';

class SafetyPage extends StatefulWidget {
  const SafetyPage({Key? key}) : super(key: key);

  @override
  State<SafetyPage> createState() => _SafetyPageState();
}

class _SafetyPageState extends State<SafetyPage> {
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
          'Sicherheit',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).size.width * 0.05,
        ),
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Fluttertoast.cancel();

                      Fluttertoast.showToast(
                        msg:
                            'This feature will be introduced, when our users will be mail-verified.',
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.05,
                        vertical: MediaQuery.of(context).size.width * 0.05,
                      ),
                      color: Colors.transparent,
                      child: Row(
                        children: [
                          const Text(
                            '2-Stufen-Authentifizierung',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Container(),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.black38,
                            size: 20,
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
      ),
    );
  }
}

class PermissionManagePage extends StatefulWidget {
  const PermissionManagePage({Key? key}) : super(key: key);

  @override
  State<PermissionManagePage> createState() => _PermissionManagePageState();
}

class _PermissionManagePageState extends State<PermissionManagePage> {
  bool locationPermissionGranted = false;
  bool microphonePermissionGranted = false;
  bool cameraPermissionGranted = false;

  void getPermissionStatus() async {
    locationPermissionGranted =
        PermissionStatus.granted == await Permission.location.status;
    microphonePermissionGranted =
        PermissionStatus.granted == await Permission.microphone.status;
    cameraPermissionGranted =
        PermissionStatus.granted == await Permission.camera.status;

    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    getPermissionStatus();
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
          'Berechtigungen verwalten',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).size.width * 0.05,
        ),
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        changePage(
                          const ChangePasswordPage(),
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.05,
                        vertical: MediaQuery.of(context).size.width * 0.05,
                      ),
                      color: Colors.transparent,
                      child: Row(
                        children: [
                          const Text(
                            'Kamera',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Container(),
                          ),
                          Text(
                            cameraPermissionGranted ? 'erteilt' : 'verweigert',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.05,
                        vertical: MediaQuery.of(context).size.width * 0.05,
                      ),
                      color: Colors.transparent,
                      child: Row(
                        children: [
                          const Text(
                            'Audio Aufnahme',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Container(),
                          ),
                          Text(
                            microphonePermissionGranted
                                ? 'erteilt'
                                : 'verweigert',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
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
      ),
    );
  }
}
