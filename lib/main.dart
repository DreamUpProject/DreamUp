import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:friendivity/mainScreens/contacts.dart';
import 'package:friendivity/mainScreens/profile.dart';
import 'package:friendivity/mainScreens/thread.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

import 'additionalPages/chat.dart';
import 'additionalPages/loginScreen.dart';
import 'mainScreens/creation.dart';
import 'utils/imageEditingIsolate.dart';

double spacing = 0;

double homeBarHeight = 0;

Map<String, CachedNetworkImageProvider> LoadedImages = {};
Map<String, ImageProvider> BlurImages = {};

int animationSpeed = 250;

DateTime? logInTime;

bool gotUserData = false;

class CurrentUser {
  static String? id;
  static String? mail;

  static String? imageLink;
  static File? imageFile;
  static File? blurredImage;

  static bool? hasPremium;

  static String? name;
  static String? bio;
  static DateTime? birthday;
  static String? gender;
  static String? city;

  static Map<String, dynamic> personality = {};

  static Map<String, dynamic> dreamUpImages = {};

  static Map<String, dynamic> icebreakers = {};

  static List<dynamic> genderPrefs = [];

  static Map<String, dynamic> chatPartnerImages = {};

  static List<dynamic> recentlySearched = [];

  static Map<String, dynamic> requestedCreators = {};

  Future<String> get appDirectory async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Map<String, dynamic> toJson() => {
        'id': id ?? '',
        'email': mail ?? '',
        'imageLink': imageLink ?? '',
        'hasPremium': hasPremium ?? false,
        'name': name ?? '',
        'bio': bio ?? '',
        'birthday': birthday != null ? birthday.toString() : '',
        'gender': gender ?? '',
        'city': city ?? '',
        'dreamUpImages': dreamUpImages,
        'givenAnswers': icebreakers,
        'genderPrefs': genderPrefs,
        'chatPartnerImages': chatPartnerImages,
        'recentlySearched': recentlySearched,
        'requestedCreators': requestedCreators,
        'personality': personality,
      };

  Future<void> getUserData() async {
    final path = await appDirectory;
    final userId = FirebaseAuth.instance.currentUser!.uid;

    bool existing = await File('$path/userInformation/$userId').exists();

    if (existing) {
      var file = File('$path/userInformation/$userId');
      var json = await file.readAsString();

      var userMap = jsonDecode(json);

      getFromFile(userMap);
    } else {
      print('needs Database!');

      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      var data = userDoc.data()!;

      getFromDatabase(data);

      saveUserInformation();
    }

    bool imageExisting =
        await File('$path/userInformation/images/$userId').exists();

    if (!imageExisting) {
      await Dio().download(
        CurrentUser.imageLink!,
        '$path/userInformation/images/$userId',
      );

      CurrentUser.imageFile = File('$path/userInformation/images/$userId');

      print('download success!');
    } else {
      CurrentUser.imageFile = File('$path/userInformation/images/$userId');
    }

    bool blurExisting =
        await File('$path/userInformation/images/blurredImage/$userId')
            .exists();

    if (!blurExisting) {
      File compressedFile = await File('$path/compressedImage/$userId.jpg')
          .create(recursive: true);

      var compressed = await FlutterImageCompress.compressAndGetFile(
        CurrentUser.imageFile!.path,
        compressedFile.path,
        minHeight: 200,
        minWidth: 200,
        quality: 0,
      );

      File imageFile = File(compressed!.path);

      File file =
          await File('$path/userInformation/images/blurredImage/$userId')
              .create(recursive: true);

      var uiImage = await compute(blurImage, imageFile);

      file.writeAsBytesSync(
        img.encodePng(uiImage),
        mode: FileMode.append,
      );

      CurrentUser.blurredImage = file;

      print('image was blurred');
    } else {
      CurrentUser.blurredImage =
          File('$path/userInformation/images/blurredImage/$userId');

      print('got blurred image');
    }
  }

  void getFromFile(Map<String, dynamic> json) async {
    id = json['id'] ?? '';
    userInfoSteps.add(
        'got user Id; ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}:${DateTime.now().millisecond}');

    hasPremium = json['hasPremium'] ?? false;
    userInfoSteps.add(
        'got user premium; ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}:${DateTime.now().millisecond}');

    mail = json['email'] ?? '';
    userInfoSteps.add(
        'got user mail; ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}:${DateTime.now().millisecond}');

    name = json['name'] ?? '';
    userInfoSteps.add(
        'got user name; ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}:${DateTime.now().millisecond}');

    bio = json['bio'] ?? '';
    userInfoSteps.add(
        'got user bio; ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}:${DateTime.now().millisecond}');

    imageLink = json['imageLink'] ?? '';
    userInfoSteps.add(
        'got user image; ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}:${DateTime.now().millisecond}');

    birthday =
        json['birthday'] != null ? DateTime.parse(json['birthday']) : null;
    userInfoSteps.add(
        'got user birthday; ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}:${DateTime.now().millisecond}');

    gender = json['gender'] ?? '';
    userInfoSteps.add(
        'got user gender; ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}:${DateTime.now().millisecond}');

    city = json['city'] ?? '';
    userInfoSteps.add(
        'got user city; ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}:${DateTime.now().millisecond}');

    genderPrefs = json['genderPrefs'] ?? [];
    userInfoSteps.add(
        'got user gender prefs; ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}:${DateTime.now().millisecond}');

    icebreakers = json['givenAnswers'] ?? {};
    userInfoSteps.add(
        'got user answers; ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}:${DateTime.now().millisecond}');

    chatPartnerImages = json['chatPartnerImages'] ?? {};
    userInfoSteps.add(
        'got user chat partners; ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}:${DateTime.now().millisecond}');

    recentlySearched = json['recentlySearched'] ?? [];
    userInfoSteps.add(
        'got user recently searched; ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}:${DateTime.now().millisecond}');

    dreamUpImages = json['dreamUpImages'] ?? {};

    requestedCreators = json['requestedCreators'] ?? {};

    int count = 0;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(id)
        .collection('requestedCreators')
        .count()
        .get()
        .then((value) => count = value.count);

    if (count != requestedCreators.length) {
      var requested = await FirebaseFirestore.instance
          .collection('users')
          .doc(id)
          .collection('requestedCreators')
          .get();

      requestedCreators.clear();

      for (var doc in requested.docs) {
        var data = doc.data();

        var id = data['userId'];
        var name = data['userName'];

        requestedCreators.addAll(
          {
            id: name,
          },
        );
      }
    }
    userInfoSteps.add(
        'got user requested creators; ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}:${DateTime.now().millisecond}');

    personality = json['personality'] ?? {};
    userInfoSteps.add(
        'got user personality; ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}:${DateTime.now().millisecond}');
  }

  void getFromDatabase(Map<String, dynamic> json) async {
    id = json['id'] ?? '';
    userInfoSteps.add(
        'got user Id; ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}:${DateTime.now().millisecond}');

    hasPremium = json['hasPremium'] ?? false;
    userInfoSteps.add(
        'got user premium; ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}:${DateTime.now().millisecond}');

    mail = json['email'] ?? '';
    userInfoSteps.add(
        'got user mail; ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}:${DateTime.now().millisecond}');

    name = json['name'] ?? '';
    userInfoSteps.add(
        'got user name; ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}:${DateTime.now().millisecond}');

    bio = json['bio'] ?? '';
    userInfoSteps.add(
        'got user bio; ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}:${DateTime.now().millisecond}');

    imageLink = json['imageLink'] ?? '';
    userInfoSteps.add(
        'got user image; ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}:${DateTime.now().millisecond}');

    print(json['birthday']);
    print('birthday is timestamp: ${json['birthday'] is Timestamp}');

    birthday = json['birthday'] != null
        ? (json['birthday'] as Timestamp).toDate()
        : null;
    userInfoSteps.add(
        'got user birthday; ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}:${DateTime.now().millisecond}');

    gender = json['gender'] ?? '';
    userInfoSteps.add(
        'got user gender; ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}:${DateTime.now().millisecond}');

    city = json['city'] ?? '';
    userInfoSteps.add(
        'got user city; ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}:${DateTime.now().millisecond}');

    genderPrefs = json['genderPrefs'] ?? [];
    userInfoSteps.add(
        'got user gender prefs; ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}:${DateTime.now().millisecond}');

    chatPartnerImages = json['chatPartnerImages'] ?? {};
    userInfoSteps.add(
        'got user chat partners; ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}:${DateTime.now().millisecond}');

    recentlySearched = json['recentlySearched'] ?? [];
    userInfoSteps.add(
        'got user recently searched; ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}:${DateTime.now().millisecond}');

    dreamUpImages = json['dreamUpImages'] ?? {};

    requestedCreators = json['requestedCreators'] ?? {};

    int count = 0;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(id)
        .collection('requestedCreators')
        .count()
        .get()
        .then((value) => count = value.count);

    if (count != requestedCreators.length) {
      var requested = await FirebaseFirestore.instance
          .collection('users')
          .doc(id)
          .collection('requestedCreators')
          .get();

      requestedCreators.clear();

      for (var doc in requested.docs) {
        var data = doc.data();

        var id = data['userId'];
        var name = data['userName'];

        requestedCreators.addAll(
          {
            id: name,
          },
        );
      }
    }
    userInfoSteps.add(
        'got user requested creators; ${DateTime.now().hour}:${DateTime.now().second}:${DateTime.now().millisecond}');
  }

  Future<File> chatPartnerImage(String chatId, String imageLink) async {
    final path = await appDirectory;

    if (!chatPartnerImages.containsKey(chatId) ||
        chatPartnerImages[chatId] != imageLink) {
      await Dio().download(
        imageLink,
        '$path/$id/chatPartnerImages/$chatId',
      );

      print('download success!');

      if (!chatPartnerImages.containsKey(chatId)) {
        chatPartnerImages.addAll({chatId: imageLink});
      } else {
        chatPartnerImages[chatId] = imageLink;
      }

      await saveUserInformation();

      return File('$path/$id/chatPartnerImages/$chatId');
    } else {
      return File('$path/$id/chatPartnerImages/$chatId');
    }
  }

  Future<File> dreamUpImage(String dreamUpId, String imageLink) async {
    final path = await appDirectory;

    if (!dreamUpImages.containsKey(dreamUpId) ||
        dreamUpImages[dreamUpId] != imageLink) {
      await Dio().download(
        imageLink,
        '$path/$id/dreamUpImages/$dreamUpId',
      );

      print('download success!');

      if (!dreamUpImages.containsKey(dreamUpId)) {
        dreamUpImages.addAll(
          {
            dreamUpId: imageLink,
          },
        );
      } else {
        dreamUpImages[dreamUpId] = imageLink;
      }

      await saveUserInformation();

      return File('$path/$id/dreamUpImages/$dreamUpId');
    } else {
      return File('$path/$id/dreamUpImages/$dreamUpId');
    }
  }

  Future saveImageFile(File imageFile) async {
    final path = await appDirectory;

    await imageFile.copy(
        '$path/userInformation/images/${FirebaseAuth.instance.currentUser?.uid}');

    CurrentUser.imageFile = File(
        '$path/userInformation/images/${FirebaseAuth.instance.currentUser?.uid}');
  }

  Future saveUserInformation() async {
    final path = await appDirectory;

    bool existing = await File(
            '$path/userInformation/${FirebaseAuth.instance.currentUser?.uid}')
        .exists();

    if (existing) {
      var file = File(
          '$path/userInformation/${FirebaseAuth.instance.currentUser?.uid}');

      String json = jsonEncode(toJson());

      file.writeAsStringSync(json);
    } else {
      File file = await File(
              '$path/userInformation/${FirebaseAuth.instance.currentUser?.uid}')
          .create(recursive: true);

      String json = jsonEncode(toJson());

      file.writeAsStringSync(json);
    }

    bool imageExisting = await File(
            '$path/userInformation/images/${FirebaseAuth.instance.currentUser?.uid}')
        .exists();

    if (!imageExisting) {
      await Dio().download(
        CurrentUser.imageLink!,
        '$path/userInformation/images/${FirebaseAuth.instance.currentUser?.uid}',
      );

      CurrentUser.imageFile = File(
          '$path/userInformation/images/${FirebaseAuth.instance.currentUser?.uid}');

      print('download success!');
    } else {
      CurrentUser.imageFile = File(
          '$path/userInformation/images/${FirebaseAuth.instance.currentUser?.uid}');
    }
  }

  Future saveSeenVibes(String category, List<dynamic> vibes) async {
    final path = await appDirectory;

    bool existing = await File(
            '$path/${FirebaseAuth.instance.currentUser?.uid}/seenVibes/$category')
        .exists();

    if (existing) {
      var file = File(
          '$path/${FirebaseAuth.instance.currentUser?.uid}/seenVibes/$category');

      String vibeMaps = jsonEncode(vibes);

      Map combined = {category: vibeMaps};

      String json = jsonEncode(combined);

      file.writeAsStringSync(json);
    } else {
      File file = await File(
              '$path/${FirebaseAuth.instance.currentUser?.uid}/seenVibes/$category')
          .create(recursive: true);

      String vibeMaps = jsonEncode(vibes);

      Map combined = {category: vibeMaps};

      String json = jsonEncode(combined);

      file.writeAsStringSync(json);
    }
  }

  Future getSeenVibes() async {
    final path = await appDirectory;

    for (var category in DreamUpAlgorithmManager.Types) {
      bool existing = await File(
              '$path/${FirebaseAuth.instance.currentUser?.uid}/seenVibes/$category')
          .exists();

      if (existing) {
        var file = File(
            '$path/${FirebaseAuth.instance.currentUser?.uid}/seenVibes/$category');

        var json = await file.readAsString();

        var vibeMap = jsonDecode(json);

        for (String category in vibeMap.keys) {
          List vibes = jsonDecode(vibeMap[category]);

          var entry = {category: vibes};

          seenVibes.addAll(entry);
        }
      }
    }

    for (var category in DreamUpAlgorithmManager.PremiumTypes) {
      bool existing = await File(
              '$path/${FirebaseAuth.instance.currentUser?.uid}/seenVibes/$category')
          .exists();

      if (existing) {
        var file = File(
            '$path/${FirebaseAuth.instance.currentUser?.uid}/seenVibes/$category');

        var json = await file.readAsString();

        var vibeMap = jsonDecode(json);

        for (String category in vibeMap.keys) {
          List vibes = jsonDecode(vibeMap[category]);

          var entry = {category: vibes};

          seenVibes.addAll(entry);
        }
      }
    }
  }

  Future deleteSeenVibes() async {
    final path = await appDirectory;

    for (var category in DreamUpAlgorithmManager.Types) {
      bool existing = await File(
              '$path/${FirebaseAuth.instance.currentUser?.uid}/seenVibes/$category')
          .exists();

      if (existing) {
        var file = File(
            '$path/${FirebaseAuth.instance.currentUser?.uid}/seenVibes/$category');

        file.delete(recursive: true);
      }
    }

    for (var category in DreamUpAlgorithmManager.PremiumTypes) {
      bool existing = await File(
              '$path/${FirebaseAuth.instance.currentUser?.uid}/seenVibes/$category')
          .exists();

      if (existing) {
        var file = File(
            '$path/${FirebaseAuth.instance.currentUser?.uid}/seenVibes/$category');

        file.delete(recursive: true);
      }
    }
  }

  static void deleteUserInfo() {
    id = null;
    hasPremium = null;
    imageFile = null;
    blurredImage = null;
    mail = null;
    name = null;
    bio = null;
    imageLink = null;
    birthday = null;
    gender = null;
    genderPrefs.clear();

    gotUserData = false;

    vibeList.clear();
  }

  static deleteAccount(BuildContext context) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Dialog(
            child: Container(
              padding: EdgeInsets.all(
                MediaQuery.of(context).size.width * 0.05,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  SizedBox(
                    height: MediaQuery.of(context).size.width * 0.05,
                  ),
                  const Text(
                    'Alle deine Daten werden gelöscht...',
                  ),
                ],
              ),
            ),
          );
        });

    var createdVibesRef = await FirebaseFirestore.instance
        .collection('vibes')
        .where('creator', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .get();

    for (var vibe in createdVibesRef.docs) {
      var data = vibe.data();

      if (data['imageLink'] !=
          'https://firebasestorage.googleapis.com/v0/b/activities-with-friends.appspot.com/o/placeholderImages%2FostseeQuadrat.jpg?alt=media&token=cece7d52-6d24-463f-9ac7-ea55ed35086a') {
        var imageRef =
            FirebaseStorage.instance.ref('vibeMedia/images/${vibe.id}');

        await imageRef.delete();
      }

      if (data['audioLink'] != '') {
        var audioRef =
            FirebaseStorage.instance.ref('vibeMedia/audios/${vibe.id}');

        await audioRef.delete();
      }

      if ((data['hashtags'] as List<dynamic>).isNotEmpty) {
        for (var hashtag in data['hashtags']) {
          var databaseHashtagRef = await FirebaseFirestore.instance
              .collection('hashtags')
              .where('hashtag', isEqualTo: hashtag)
              .get();

          var databaseHashtags = databaseHashtagRef.docs;

          for (var databaseHashtag in databaseHashtags) {
            var hashtagData = databaseHashtag.data();

            if (hashtagData['useCount'] > 1) {
              await FirebaseFirestore.instance
                  .collection('hashtags')
                  .doc(databaseHashtag.id)
                  .update(
                {
                  'useCount': FieldValue.increment(-1),
                },
              );
            } else {
              await FirebaseFirestore.instance
                  .collection('hashtags')
                  .doc(databaseHashtag.id)
                  .delete();
            }
          }
        }
      }

      await FirebaseFirestore.instance
          .collection('vibes')
          .doc(vibe.id)
          .delete();
    }

    var userRef = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .get();
    var doc = userRef.data();

    if (doc!['imageLink'] !=
        'https://firebasestorage.googleapis.com/v0/b/activities-with-friends.appspot.com/o/placeholderImages%2FuserPlaceholder.png?alt=media&token=1a4e6423-446d-48b5-8bbf-466900c350ec') {
      var imageRef = FirebaseStorage.instance
          .ref('userImages/${FirebaseAuth.instance.currentUser?.uid}');

      await imageRef.delete();
    }

    var fabiNotes = await FirebaseFirestore.instance
        .collection('users')
        .doc('5HW31VMcRZdiMeYgJwbQqAiL5w82')
        .collection('notifications')
        .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .get();

    for (var note in fabiNotes.docs) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc('5HW31VMcRZdiMeYgJwbQqAiL5w82')
          .collection('notifications')
          .doc(note.id)
          .delete();
    }

    var jacobNotes = await FirebaseFirestore.instance
        .collection('users')
        .doc('Wjrh9Zg3vPcrTOJrgTWtYgwzELC3')
        .collection('notifications')
        .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .get();

    for (var note in jacobNotes.docs) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc('Wjrh9Zg3vPcrTOJrgTWtYgwzELC3')
          .collection('notifications')
          .doc(note.id)
          .delete();
    }

    var chatRef = await FirebaseFirestore.instance
        .collection('chats')
        .where('participants',
            arrayContains: FirebaseAuth.instance.currentUser?.uid)
        .get();

    for (var chat in chatRef.docs) {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chat.id)
          .delete();

      try {
        await FirebaseStorage.instance
            .ref('chatMedia/${chat.id}/images')
            .listAll()
            .then((value) {
          for (var element in value.items) {
            FirebaseStorage.instance.ref(element.fullPath).delete();
          }
        });
      } catch (error) {
        print('file not found');
      }

      try {
        await FirebaseStorage.instance
            .ref('chatMedia/${chat.id}/audios')
            .listAll()
            .then((value) {
          for (var element in value.items) {
            FirebaseStorage.instance.ref(element.fullPath).delete();
          }
        });
      } catch (error) {
        print('file not found');
      }
    }

    final Future<SharedPreferences> prefs = SharedPreferences.getInstance();

    final SharedPreferences sharedPrefs = await prefs;

    await sharedPrefs.remove('mail');
    await sharedPrefs.remove('password');
    await sharedPrefs.setBool('saving', false);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .delete();

    if (FirebaseAuth.instance.currentUser?.providerData[0].providerId ==
        'google.com') {
      final provider =
          Provider.of<GoogleAuthenticationProvider>(context, listen: false);

      await provider.googleLogOut();
    }

    await FirebaseAuth.instance.currentUser?.delete();

    deleteUserInfo();
  }
}

class HomeBarControlProvider extends ChangeNotifier {
  bool homeBarVisible = true;

  void hideHomeBar() {
    homeBarVisible = false;

    notifyListeners();
  }

  void showHomeBar() {
    homeBarVisible = true;

    notifyListeners();
  }
}

void main() async {
  logInTime = DateTime.now();

  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Firebase.initializeApp();

  final db = FirebaseFirestore.instance;
  db.settings = const Settings(persistenceEnabled: false);

  final AudioContext audioContext = AudioContext(
    iOS: AudioContextIOS(
      defaultToSpeaker: true,
      category: AVAudioSessionCategory.playback,
      options: [
        AVAudioSessionOptions.defaultToSpeaker,
        AVAudioSessionOptions.mixWithOthers,
      ],
    ),
    android: AudioContextAndroid(
      isSpeakerphoneOn: true,
      stayAwake: true,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.assistanceSonification,
      audioFocus: AndroidAudioFocus.gain,
    ),
  );

  AudioPlayer.global.setGlobalAudioContext(audioContext);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => HomeBarControlProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => GoogleAuthenticationProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

final navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'DreamUp',
      showPerformanceOverlay: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale(
          'de',
          'de-de',
        ),
      ],
      theme: ThemeData(
        fontFamily: 'Foundry Context W03',
        useMaterial3: false,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return const MyHomePage();
          } else if (snapshot.hasError) {
            return Text('There was an Error: ${snapshot.error}');
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    Key? key,
  }) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  var currentUser = FirebaseAuth.instance.currentUser?.uid;

  int index = 0;

  bool animating = false;

  List<Widget> screens = [
    const DreamUpThread(),
    const CreationOpeningScreen(
      fromProfile: false,
    ),
    const Profile(),
    const ChatsScreen(),
  ];

  Future<void> updateActiveStatus() async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(currentChatId)
        .update({
      'onlineUsers': FieldValue.arrayRemove([currentUser]),
      'lastLogin.$currentUser': DateTime.now(),
    });

    print('updated');
  }

  bool showRequests = false;

  Future<String> get appDirectory async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    logInTime ??= DateTime.now();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (currentChatId != '' && state != AppLifecycleState.resumed) {
      updateActiveStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    spacing = MediaQuery.of(context).padding.bottom;

    homeBarHeight = (MediaQuery.of(context).size.width * 2) / 15 + spacing;

    var provider = Provider.of<HomeBarControlProvider>(context, listen: true);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBody: true,
      body: SizedBox.expand(
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser)
                  .collection('requestedCreators')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var docs = snapshot.data!.docs;

                  Map<String, dynamic> requested = {};

                  for (var doc in docs) {
                    var data = doc.data() as Map<String, dynamic>;

                    requested.addAll(
                      {
                        data['userId']: data['userName'],
                      },
                    );
                  }

                  CurrentUser.requestedCreators = requested;
                }

                return Container();
              },
            ),
            screens[index],
            Visibility(
              visible: provider.homeBarVisible,
              child: SizedBox(
                height: homeBarHeight,
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: Duration(milliseconds: animationSpeed),
                      top: 0,
                      left: -MediaQuery.of(context).size.width * 0.1,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 2,
                        height: (MediaQuery.of(context).size.width * 2) / 15 +
                            spacing,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedPositioned(
                              duration: Duration(milliseconds: animationSpeed),
                              curve: Curves.fastOutSlowIn,
                              top: 0,
                              left: getBarPosition(index, context),
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width * 2,
                                height:
                                    (MediaQuery.of(context).size.width * 2) /
                                            15 +
                                        spacing,
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    AnimatedPositioned(
                                      duration: Duration(
                                        milliseconds:
                                            (animationSpeed * 0.5).toInt(),
                                      ),
                                      top: !animating
                                          ? 0
                                          : (MediaQuery.of(context).size.width *
                                                  2) /
                                              15,
                                      curve: Curves.easeInOut,
                                      onEnd: () {
                                        animating = false;

                                        setState(() {});
                                      },
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          ClipOval(
                                            child: Container(
                                              height: (MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      2) /
                                                  19,
                                              width: (MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      2) /
                                                  19,
                                              decoration: BoxDecoration(
                                                color: index != 1
                                                    ? Colors.white
                                                        .withOpacity(0.35)
                                                    : Colors.grey
                                                        .withOpacity(0.7),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: AnimatedOpacity(
                                                  duration: Duration(
                                                    milliseconds:
                                                        (animationSpeed * 0.5)
                                                            .toInt(),
                                                  ),
                                                  opacity: animating ? 0 : 1,
                                                  child: animating
                                                      ? Container()
                                                      : getIcon(
                                                          context,
                                                          index,
                                                        ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 0,
                                            right: -MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.01,
                                            child: index == 3
                                                ? StreamBuilder(
                                                    stream: FirebaseFirestore
                                                        .instance
                                                        .collection('chats')
                                                        .where('participants',
                                                            arrayContainsAny: [
                                                              currentUser
                                                            ])
                                                        .where('new',
                                                            isEqualTo: true)
                                                        .where('lastSender',
                                                            isNotEqualTo:
                                                                currentUser)
                                                        .snapshots(),
                                                    builder: (context,
                                                        AsyncSnapshot<
                                                                QuerySnapshot>
                                                            snapshot) {
                                                      if (snapshot.hasData) {
                                                        var docs =
                                                            snapshot.data!.docs;

                                                        return Visibility(
                                                          visible:
                                                              docs.isNotEmpty,
                                                          child: CircleAvatar(
                                                            backgroundColor:
                                                                Colors
                                                                    .blueAccent,
                                                            radius: 10,
                                                            child: Center(
                                                              child: Text(
                                                                docs.length
                                                                    .toString(),
                                                                style:
                                                                    const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      } else {
                                                        return Container();
                                                      }
                                                    },
                                                  )
                                                : Container(),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      child: Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                2,
                                        alignment: Alignment.center,
                                        child: SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              2,
                                          height: (MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      2) /
                                                  15 +
                                              spacing,
                                          child: ClipPath(
                                            clipper: HomeBarClipper(),
                                            child: Container(
                                              color: index != 1
                                                  ? Colors.white
                                                      .withOpacity(0.35)
                                                  : Colors.grey
                                                      .withOpacity(0.7),
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
                    ),
                    Positioned(
                      top: 0,
                      child: Container(
                        height: (MediaQuery.of(context).size.width * 2) / 15,
                        width: MediaQuery.of(context).size.width,
                        color: Colors.transparent,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                              child: AnimatedOpacity(
                                duration:
                                    Duration(milliseconds: animationSpeed),
                                opacity: index == 0 ? 0 : 1,
                                child: GestureDetector(
                                  onTap: () {
                                    index = 0;

                                    animating = true;

                                    setState(() {});
                                  },
                                  child: Container(
                                    color: Colors.transparent,
                                    height: (MediaQuery.of(context).size.width *
                                            2) /
                                        13,
                                    child: const Icon(
                                      Icons.home_outlined,
                                      color: Color(0xFF323232),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: AnimatedOpacity(
                                duration:
                                    Duration(milliseconds: animationSpeed),
                                opacity: index == 1 ? 0 : 1,
                                child: GestureDetector(
                                  onTap: () {
                                    index = 1;

                                    animating = true;

                                    setState(() {});
                                  },
                                  child: Container(
                                    color: Colors.transparent,
                                    height: (MediaQuery.of(context).size.width *
                                            2) /
                                        13,
                                    child: const Icon(
                                      Icons.add_rounded,
                                      color: Color(0xFF323232),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: AnimatedOpacity(
                                duration:
                                    Duration(milliseconds: animationSpeed),
                                opacity: index == 2 ? 0 : 1,
                                child: GestureDetector(
                                  onTap: () {
                                    index = 2;

                                    animating = true;

                                    setState(() {});
                                  },
                                  child: Container(
                                    color: Colors.transparent,
                                    height: (MediaQuery.of(context).size.width *
                                            2) /
                                        13,
                                    child: const Icon(
                                      Icons.perm_identity_rounded,
                                      color: Color(0xFF323232),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: AnimatedOpacity(
                                duration:
                                    Duration(milliseconds: animationSpeed),
                                opacity: index == 3 ? 0 : 1,
                                child: GestureDetector(
                                  onTap: () async {
                                    if (index == 3) {
                                      showRequests = !showRequests;

                                      setState(() {});
                                    }

                                    index = 3;

                                    animating = true;

                                    setState(() {});
                                  },
                                  child: Container(
                                    color: Colors.transparent,
                                    height: (MediaQuery.of(context).size.width *
                                            2) /
                                        13,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        const Positioned.fill(
                                          child: Icon(
                                            Icons.mail_outline_rounded,
                                            color: Color(0xFF323232),
                                          ),
                                        ),
                                        Positioned(
                                          top: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.01,
                                          right: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.04,
                                          child: StreamBuilder(
                                            stream: FirebaseFirestore.instance
                                                .collection('chats')
                                                .where('participants',
                                                    arrayContainsAny: [
                                                      currentUser
                                                    ])
                                                .where('new', isEqualTo: true)
                                                .where('lastSender',
                                                    isNotEqualTo: currentUser)
                                                .snapshots(),
                                            builder: (context,
                                                AsyncSnapshot<QuerySnapshot>
                                                    snapshot) {
                                              if (snapshot.hasData) {
                                                var docs = snapshot.data!.docs;

                                                return Visibility(
                                                  visible: docs.isNotEmpty,
                                                  child: CircleAvatar(
                                                    backgroundColor:
                                                        Colors.blueAccent,
                                                    radius: 10,
                                                    child: Center(
                                                      child: Text(
                                                        docs.length.toString(),
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              } else {
                                                return Container();
                                              }
                                            },
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
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: homeBarHeight + 10,
              right: 10,
              left: 20,
              child: Visibility(
                visible: showRequests,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.6,
                  color: Colors.white,
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 10,
                      ),
                      const Text(
                        'Gestellte Anfragen',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Column(
                        children: CurrentUser.requestedCreators.entries
                            .map<Widget>(
                              (creator) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        creator.value,
                                        style: const TextStyle(
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () async {
                                        var id = creator.key;

                                        var request = await FirebaseFirestore
                                            .instance
                                            .collection('chats')
                                            .where('users', isEqualTo: {
                                          currentUser: null,
                                          id: null
                                        }).get();
                                        var doc = request.docs.first;

                                        await FirebaseFirestore.instance
                                            .collection('chats')
                                            .doc(doc.id)
                                            .delete();

                                        var myRequested =
                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(currentUser)
                                                .collection('requestedCreators')
                                                .where('userId', isEqualTo: id)
                                                .get();
                                        var myDoc = myRequested.docs.first;

                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(currentUser)
                                            .collection('requestedCreators')
                                            .doc(myDoc.id)
                                            .delete();

                                        var otherRequested =
                                            await FirebaseFirestore
                                                .instance
                                                .collection('users')
                                                .doc(id)
                                                .collection('requestedCreators')
                                                .where('userId',
                                                    isEqualTo: currentUser)
                                                .get();
                                        var otherDoc =
                                            otherRequested.docs.first;

                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(id)
                                            .collection('requestedCreators')
                                            .doc(otherDoc.id)
                                            .delete();

                                        CurrentUser.requestedCreators
                                            .remove(id);
                                        await CurrentUser()
                                            .saveUserInformation();

                                        final path = await appDirectory;

                                        var chatDirectory =
                                            Directory('$path/chats/${doc.id}/');

                                        if (chatDirectory.existsSync()) {
                                          await chatDirectory.delete(
                                              recursive: true);
                                        }

                                        var userDreamUps =
                                            await FirebaseFirestore.instance
                                                .collection('vibes')
                                                .where('cretaor', isEqualTo: id)
                                                .get();

                                        for (var doc in userDreamUps.docs) {
                                          var docId = doc.id;

                                          if (CurrentUser.icebreakers
                                              .containsKey(docId)) {
                                            CurrentUser.icebreakers
                                                .remove(docId);
                                          }
                                        }

                                        await CurrentUser()
                                            .saveUserInformation();

                                        setState(() {});
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 3,
                                        ),
                                        decoration: const BoxDecoration(
                                          color: Colors.redAccent,
                                        ),
                                        child: const Text(
                                          'Verbindung lösen',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

double getBarPosition(int index, BuildContext context) {
  double position = 0;

  if (index == 0) {
    position = -MediaQuery.of(context).size.width * 0.775;
  } else if (index == 1) {
    position = -MediaQuery.of(context).size.width * 0.525;
  } else if (index == 2) {
    position = -MediaQuery.of(context).size.width * 0.275;
  } else if (index == 3) {
    position = -MediaQuery.of(context).size.width * 0.025;
  }

  return position;
}

Widget getIcon(BuildContext context, int index) {
  if (index == 0) {
    return const Icon(
      Icons.home_outlined,
      color: Color(0xFF323232),
    );
  } else if (index == 1) {
    return const Icon(
      Icons.add_rounded,
      color: Color(0xFF323232),
    );
  } else if (index == 2) {
    return const Icon(
      Icons.perm_identity_rounded,
      color: Color(0xFF323232),
    );
  } else if (index == 3) {
    return const Icon(
      Icons.mail_outline_rounded,
      color: Color(0xFF323232),
    );
  } else {
    return const Icon(
      Icons.notifications_none_rounded,
      color: Color(0xFF323232),
    );
  }
}

class Background extends StatefulWidget {
  final Widget child;

  const Background({Key? key, required this.child}) : super(key: key);

  @override
  State<Background> createState() => _BackgroundState();
}

class _BackgroundState extends State<Background> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          // image: getDetailUCs()[0].image.image,
          image:
              Image.asset('assets/images/GlassMorphismTestImage3.jpeg').image,
          fit: BoxFit.cover,
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

Route changePage(Widget destination) {
  return SwipeablePageRoute(
    builder: (context) => destination,
    canOnlySwipeFromEdge: true,
    transitionBuilder: (context, animation, secondaryAnimation, value, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.ease;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}

class HomeBarClipper extends CustomClipper<Path> {
  @override
  getClip(Size size) {
    double height = size.height - spacing;

    final path = Path();

    path.moveTo(size.width * 0.42, 0);

    path.cubicTo(size.width * 0.475, 0, size.width * 0.455, height * 0.9,
        size.width * 0.5, height * 0.9);

    path.cubicTo(size.width * 0.545, height * 0.9, size.width * 0.525, 0,
        size.width * 0.58, 0);

    path.lineTo(size.width, 0);

    path.lineTo(size.width, height + spacing);

    path.lineTo(0, height + spacing);

    path.lineTo(0, 0);

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<dynamic> oldClipper) {
    return true;
  }
}
