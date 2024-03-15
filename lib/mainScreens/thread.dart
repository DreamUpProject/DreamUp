import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:age_calculator/age_calculator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:decorated_icon/decorated_icon.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_keyboard_size/flutter_keyboard_size.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:friendivity/main.dart';
import 'package:image/image.dart' as img;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:path_provider/path_provider.dart';

import '../additionalPages/dreamUpSearch.dart';
import '../utils/audioWidgets.dart';
import '../utils/imageEditingIsolate.dart';

//region Global Variables
int currentIndex = 0;
int maxIndex = 0;
int refreshCounter = 0;

bool allWishesSeen = false;

List<Map<String, dynamic>> vibeList = [];
List<Map<String, dynamic>> oldVibes = [];

Map<String, List<dynamic>> seenVibes = {};

int backwardCount = 0;

List<String> debugList = [];

bool isNewVibe = true;

DateTime loadingStart = DateTime.now();

bool showLoadingDebugger = false;

bool currentlyFilling = false;

bool currentlyLoading = false;

Duration instantiationTime = Duration.zero;
Duration fillTime = Duration.zero;
Duration loadingTime = Duration.zero;

int loadingCounter = 4;

bool loading = false;

Map<String, dynamic> creatorInfo = {};
List<Map<String, dynamic>> creatorWishes = [];

List<String> userInfoSteps = [];
List<String> loadingSteps = [];

bool scrolling = false;

String filterType = '';

String lastFriendshipId = '';
bool sawAllFriendships = false;
String lastActionId = '';
bool sawAllActions = false;

int oldCounter = 0;

double fontSize = 25;
double smallTextSize = 16;

int ageRange = 3;
//endregion

//region Debugging
class DebugTool {
  static List<dynamic> FriendshipDreamUps = [];
  static List<dynamic> ActionDreamUps = [];

  Future<String> get appDirectory async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future getInfo() async {
    final path = await appDirectory;

    bool oldExisting =
        await File('$path/${FirebaseAuth.instance.currentUser?.uid}/debugInfo')
            .exists();

    if (oldExisting) {
      await File('$path/${FirebaseAuth.instance.currentUser?.uid}/debugInfo')
          .delete();
    }

    for (var category in DreamUpAlgorithmManager.Types) {
      bool existing = await File(
              '$path/${FirebaseAuth.instance.currentUser?.uid}/countingInfo/$category')
          .exists();

      if (existing) {
        var file = File(
            '$path/${FirebaseAuth.instance.currentUser?.uid}/countingInfo/$category');

        var json = await file.readAsString();

        var debugInfo = jsonDecode(json);

        if (category == 'Freundschaft') {
          FriendshipDreamUps = debugInfo;
        } else {
          ActionDreamUps = debugInfo;
        }
      } else {
        var dreamUps = await FirebaseFirestore.instance
            .collection('vibes')
            .where('type', isEqualTo: category)
            .orderBy('createdOn', descending: false)
            .get();

        for (var doc in dreamUps.docs) {
          var data = doc.data();

          String id = data['id'];
          String title = data['title'];
          String creator = data['creator'];
          int count = 0;
          bool seen = false;

          Map entry = {
            'id': id,
            'title': title,
            'creator': creator,
            'count': count,
            'seen': seen,
          };

          if (category == 'Freundschaft') {
            FriendshipDreamUps.add(entry);
          } else {
            ActionDreamUps.add(entry);
          }
        }
      }
    }
  }

  Future saveInfo(String category) async {
    final path = await appDirectory;

    bool existing = await File(
            '$path/${FirebaseAuth.instance.currentUser?.uid}/countingInfo/$category')
        .exists();

    if (existing) {
      var file = File(
          '$path/${FirebaseAuth.instance.currentUser?.uid}/countingInfo/$category');

      if (category == 'Freundschaft') {
        String json = jsonEncode(FriendshipDreamUps);

        file.writeAsStringSync(json);
      } else {
        String json = jsonEncode(ActionDreamUps);

        file.writeAsStringSync(json);
      }
    } else {
      File file = await File(
              '$path/${FirebaseAuth.instance.currentUser?.uid}/countingInfo/$category')
          .create(recursive: true);

      if (category == 'Freundschaft') {
        String json = jsonEncode(FriendshipDreamUps);

        file.writeAsStringSync(json);
      } else {
        String json = jsonEncode(ActionDreamUps);

        file.writeAsStringSync(json);
      }
    }
  }

  Future updateInfo(String category, Map<String, dynamic> dreamUpInfo) async {
    String id = dreamUpInfo['id'];
    String title = dreamUpInfo['title'];
    String creator = dreamUpInfo['creator'];
    int count = 0;
    bool seen = false;

    if (category == 'Freundschaft') {
      for (var map in FriendshipDreamUps) {
        var amount = map['count'];

        if (amount > count) {
          count = amount;
        }
      }
    } else {
      for (var map in ActionDreamUps) {
        var amount = map['count'];

        if (amount > count) {
          count = amount;
        }
      }
    }

    Map entry = {
      'id': id,
      'title': title,
      'creator': creator,
      'count': count != 0 ? count - 1 : count,
      'seen': seen,
    };

    if (category == 'Freundschaft') {
      FriendshipDreamUps.add(entry);
    } else {
      ActionDreamUps.add(entry);
    }
  }

  Future deleteInfo() async {
    final path = await appDirectory;

    for (var category in DreamUpAlgorithmManager.Types) {
      bool existing = await File(
              '$path/${FirebaseAuth.instance.currentUser?.uid}/countingInfo/$category')
          .exists();

      if (existing) {
        var file = File(
            '$path/${FirebaseAuth.instance.currentUser?.uid}/countingInfo/$category');

        await file.delete();
      }

      FriendshipDreamUps.clear();
      ActionDreamUps.clear();
    }
  }

  Future updateDreamUps() async {
    var dreamUps = await FirebaseFirestore.instance
        .collection('vibes')
        .where('type', whereIn: ['Freundschaft', 'Aktion']).get();

    var dreamUpDatas = [];

    var deletingFriendships = [];
    var deletingActions = [];

    for (var doc in dreamUps.docs) {
      var data = doc.data();

      dreamUpDatas.add(data);
    }

    for (int i = 0; i < FriendshipDreamUps.length; i++) {
      var entry = FriendshipDreamUps[i];

      var id = entry['id'];

      var existing =
          dreamUpDatas.firstWhereOrNull((element) => element['id'] == id);

      if (existing == null) {
        print('deleting ${entry['title']}');

        deletingFriendships.add(entry);
      } else {
        entry = existing;
      }
    }

    for (int i = 0; i < ActionDreamUps.length; i++) {
      var entry = ActionDreamUps[i];

      var id = entry['id'];

      var existing =
          dreamUpDatas.firstWhereOrNull((element) => element['id'] == id);

      if (existing == null) {
        print('deleting ${entry['title']}');

        deletingActions.add(entry);
      } else {
        entry = existing;
      }
    }

    for (var entry in deletingFriendships) {
      FriendshipDreamUps.remove(entry);
    }

    for (var entry in deletingActions) {
      ActionDreamUps.remove(entry);
    }

    await saveInfo('Freundschaft');
    await saveInfo('Aktion');

    Fluttertoast.showToast(msg: 'Tool updated');
  }
}
//endregion

//region UI Logic
class DreamUpThread extends StatelessWidget {
  const DreamUpThread({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const DreamUpScreenContent();
  }
}

class DreamUpScreenContent extends StatefulWidget {
  const DreamUpScreenContent({
    Key? key,
  }) : super(key: key);

  @override
  State<DreamUpScreenContent> createState() => _DreamUpScreenContentState();
}

class _DreamUpScreenContentState extends State<DreamUpScreenContent>
    with TickerProviderStateMixin {
  final currentUser = FirebaseAuth.instance.currentUser?.uid;

  CarouselController carouselController = CarouselController();

  bool refreshing = false;

  double connectInitSize = 0;
  double currentSheetHeight = 0;

  bool showDebugTool = false;

  bool gotSeenVibes = false;

  Future<String> get appDirectory async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  instantiateAlgorithmQueries(String filterType, BuildContext context) async {
    var connection = await InternetConnectionChecker().hasConnection;

    if (!connection) {
      print('no connection!');

      if (!offline) {
        print('by 1');

        handleDisconnect('initial');
      }
    } else {
      if (DebugTool.FriendshipDreamUps.isEmpty) {
        await DebugTool().getInfo();
      }

      await FirebaseFirestore.instance
          .collection('vibes')
          .where('type', isEqualTo: 'Freundschaft')
          .orderBy('createdOn', descending: false)
          .limit(1)
          .get()
          .then(
        (res) {
          var data = res.docs.first.data();

          print(data['title']);

          lastFriendshipId = data['id'];
        },
        onError: (e) => print("Error completing: $e"),
      );

      await FirebaseFirestore.instance
          .collection('vibes')
          .where('type', isEqualTo: 'Aktion')
          .orderBy('createdOn', descending: false)
          .limit(1)
          .get()
          .then(
        (res) {
          var data = res.docs.first.data();

          print(data['title']);

          lastActionId = data['id'];
        },
        onError: (e) => print("Error completing: $e"),
      );
    }

    if (!gotUserData) {
      print('should get UserData');

      await CurrentUser().getUserData();

      gotUserData = true;
      setState(() {});

      await CurrentUser().getSeenVibes();

      gotSeenVibes = true;
      setState(() {});

      print('got UserData');
    }

    var start = DateTime.now();

    loadingStart = start;
    DreamUpAlgorithmManager.QueryList.clear();

    if (!DreamUpAlgorithmManager.filtering) {
      for (var type in DreamUpAlgorithmManager.Types) {
        var existing = seenVibes.containsKey(type);

        if (existing) {
          if (seenVibes[type]!.isNotEmpty) {
            var last = seenVibes[type]!.last.entries.first;

            Timestamp newStart = Timestamp.fromDate(logInTime!);
            Timestamp newEnd = Timestamp.fromDate(DateTime.parse(last.key));

            int amount = 0;

            await FirebaseFirestore.instance
                .collection('vibes')
                .where('type', isEqualTo: type)
                .orderBy('createdOn', descending: true)
                .startAfter([newStart])
                .endBefore([newEnd])
                .get()
                .then(
                  (res) {
                    amount = res.docs.length;

                    var docs = res.docs.reversed;

                    for (var doc in docs) {
                      var data = doc.data();

                      DebugTool().updateInfo(type, data);
                    }

                    DebugTool().saveInfo(type);
                  },
                  onError: (e) => print("Error completing: $e"),
                );

            print('$amount new cards of type $type');

            if (amount == 0) {
              var connection = await InternetConnectionChecker().hasConnection;

              if (connection) {
                print('no new vibes of $type');

                Map<String, String> newLast = {
                  logInTime.toString(): last.value,
                };

                seenVibes[type]?.removeLast();
                seenVibes[type]?.add(newLast);

                Query newQuery = FirebaseFirestore.instance
                    .collection('vibes')
                    .where('type', isEqualTo: type)
                    .orderBy('createdOn', descending: true)
                    .startAfter([
                  Timestamp.fromDate(DateTime.parse(last.value))
                ]).limit(1);

                DreamUpAlgorithmManager.QueryList.add(newQuery);
              } else {
                print('no connection!');

                if (!offline) {
                  print('by 2');
                  handleDisconnect('initial');
                }

                break;
              }
            } else {
              print('there are new vibes of $type');

              Query newQuery = FirebaseFirestore.instance
                  .collection('vibes')
                  .where('type', isEqualTo: type)
                  .orderBy('createdOn', descending: true)
                  .startAfter([newStart]).limit(1);

              DreamUpAlgorithmManager.QueryList.add(newQuery);
            }
          } else {
            Query query = FirebaseFirestore.instance
                .collection('vibes')
                .where('type', isEqualTo: type)
                .orderBy('createdOn', descending: true)
                .startAfter([Timestamp.fromDate(logInTime!)]).limit(1);

            DreamUpAlgorithmManager.QueryList.add(query);
          }
        } else {
          Query query = FirebaseFirestore.instance
              .collection('vibes')
              .where('type', isEqualTo: type)
              .orderBy('createdOn', descending: true)
              .startAfter([Timestamp.fromDate(logInTime!)]).limit(1);

          DreamUpAlgorithmManager.QueryList.add(query);
        }
      }
    } else {
      if (filterType == 'Date' || filterType == 'Beziehung') {
        Query query = FirebaseFirestore.instance
            .collection('vibes')
            .where('type', isEqualTo: filterType)
            .where('genderPrefs', arrayContains: CurrentUser.gender)
            .where('creatorGender', whereIn: CurrentUser.genderPrefs)
            .orderBy('createdOn', descending: true)
            .startAt([Timestamp.fromDate(logInTime!)]).limit(1);

        DreamUpAlgorithmManager.QueryList.add(query);
      } else if (filterType == 'gender') {
        Query query = FirebaseFirestore.instance
            .collection('vibes')
            .where('creatorGender', isEqualTo: CurrentUser.gender)
            .orderBy('createdOn', descending: true)
            .startAt([Timestamp.fromDate(logInTime!)]).limit(1);

        DreamUpAlgorithmManager.QueryList.add(query);
      } else {
        Query query = FirebaseFirestore.instance
            .collection('vibes')
            .where('type', isEqualTo: filterType)
            .orderBy('createdOn', descending: true)
            .startAt([Timestamp.fromDate(logInTime!)]).limit(1);

        DreamUpAlgorithmManager.QueryList.add(query);
      }
    }

    var connected = await InternetConnectionChecker().hasConnection;

    print(DreamUpAlgorithmManager.QueryList.length);

    if (DreamUpAlgorithmManager.QueryList.isEmpty && connected) {
      seenVibes.clear();
      await CurrentUser().deleteSeenVibes();

      await instantiateAlgorithmQueries('', context);
    } else {
      if (connected) {
        loadingCounter = 4;
        await fillDreamUpList(context);
      } else {
        print('no connection!');

        if (!offline) {
          print('by 3');
          handleDisconnect('instantiate');
        }
      }
    }

    if (instantiationTime == Duration.zero) {
      instantiationTime = DateTime.now().difference(start);
    }
  }

  Future getNewAlgorithmQueries() async {
    DreamUpAlgorithmManager.QueryList.clear();

    oldVibes.clear();

    allWishesSeen = true;

    for (var type in DreamUpAlgorithmManager.Types) {
      Query query = FirebaseFirestore.instance
          .collection('vibes')
          .where('type', isEqualTo: type)
          .orderBy('createdOn', descending: true)
          .startAfter([Timestamp.fromDate(logInTime!)]).limit(1);

      DreamUpAlgorithmManager.QueryList.add(query);
    }

    loadingCounter++;
  }

  Future<void> fillDreamUpList(BuildContext context) async {
    if (!currentlyFilling) {
      currentlyFilling = true;

      var connected = await InternetConnectionChecker().hasConnection;

      if (DreamUpAlgorithmManager.QueryList.isEmpty &&
          !DreamUpAlgorithmManager.filtering &&
          connected) {
        print('getting new queries');

        await getNewAlgorithmQueries();
      }

      if (connected) {
        while (loadingCounter > 0 &&
            DreamUpAlgorithmManager.QueryList.isNotEmpty) {
          if (!DreamUpAlgorithmManager.filtering) {
            var start = DateTime.now();

            if (DreamUpAlgorithmManager.QueryList.isNotEmpty) {
              if (loadingCounter == 0) {
                break;
              }

              var random =
                  Random().nextInt(DreamUpAlgorithmManager.QueryList.length);

              await DreamUpAlgorithmManager.QueryList[random].get().then(
                (documents) async {
                  for (var doc in documents.docs) {
                    var data = doc.data() as Map<String, dynamic>;

                    var type = data['type'];
                    var createdOn = (data['createdOn'] as Timestamp).toDate();

                    print('');
                    print(data['title']);

                    var exists = seenVibes.containsKey(type);

                    if (exists) {
                      bool crossed = true;

                      if (seenVibes[type]!.isNotEmpty) {
                        for (int i = seenVibes[type]!.length - 1; i > -1; i--) {
                          var last = seenVibes[type]![i] as Map;

                          var lastCreation =
                              DateTime.parse(last.entries.first.value);
                          var lastLogin =
                              DateTime.parse(last.entries.first.key);

                          if (logInTime != lastLogin) {
                            if (createdOn.isBefore(lastLogin) &&
                                !createdOn.isBefore(lastCreation)) {
                              debugList.add('vibe is crossing seenVibes');

                              Timestamp newStart =
                                  Timestamp.fromDate(lastCreation);

                              DreamUpAlgorithmManager.QueryList[random] =
                                  DreamUpAlgorithmManager.QueryList[random]
                                      .startAfter([newStart]);

                              crossed = true;

                              break;
                            } else {
                              debugList.add(
                                  'not crossing seenVibes, going forward normally');
                              crossed = false;
                            }
                          } else {
                            debugList.add('same dates, maybe error here?');

                            crossed = false;
                          }
                        }

                        if (!crossed) {
                          debugList.add('getting next');

                          Timestamp newStart = Timestamp.fromDate(createdOn);

                          if (allWishesSeen) {
                            var existing = oldVibes.firstWhereOrNull(
                                (element) => element['id'] == data['id']);

                            if (existing == null) {
                              var image = CachedNetworkImageProvider(
                                data['imageLink'],
                                errorListener: (object) {
                                  print('image error!');
                                },
                              );

                              await precacheImage(
                                image,
                                context,
                                size: Size(
                                  MediaQuery.of(context).size.width,
                                  MediaQuery.of(context).size.width,
                                ),
                              );

                              Map<String, CachedNetworkImageProvider> entry = {
                                data['id']: image
                              };

                              if (!LoadedImages.containsKey(data['id'])) {
                                LoadedImages.addAll(entry);
                              }

                              var cachedImage = await DefaultCacheManager()
                                  .getSingleFile(data['imageLink']);

                              var path = await appDirectory;

                              File compressedFile = await File(
                                      '$path/compressedImage/${data['id']}.jpg')
                                  .create(recursive: true);

                              var compressed =
                                  await FlutterImageCompress.compressAndGetFile(
                                cachedImage.path,
                                compressedFile.path,
                                minHeight: 200,
                                minWidth: 200,
                                quality: 0,
                              );

                              File imageFile = File(compressed!.path);

                              File file =
                                  await File('$path/blurredImage/${data['id']}')
                                      .create(recursive: true);

                              var uiImage = await compute(blurImage, imageFile);

                              file.writeAsBytesSync(
                                img.encodePng(uiImage),
                                mode: FileMode.append,
                              );

                              var blurredImage = Image.file(
                                file,
                                width: MediaQuery.of(context).size.width,
                                height: MediaQuery.of(context).size.width,
                              ).image;

                              await precacheImage(
                                blurredImage,
                                context,
                                size: Size(
                                  MediaQuery.of(context).size.width,
                                  MediaQuery.of(context).size.width,
                                ),
                              );

                              Map<String, ImageProvider> blurredEntry = {
                                data['id']: blurredImage,
                              };

                              if (!BlurImages.containsKey(data['id'])) {
                                BlurImages.addAll(blurredEntry);
                              }

                              if (!CurrentUser.requestedCreators
                                  .containsKey(data['creator'])) {
                                oldVibes.add(data);

                                vibeList.add(data);

                                loadingSteps.add(
                                    'added ${data['title']} to list; ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}:${DateTime.now().millisecond}');

                                loadingCounter--;

                                setState(() {});
                              } else {}
                            }
                          } else {
                            var existing = vibeList.firstWhereOrNull(
                                (element) => element['id'] == data['id']);

                            if (existing == null) {
                              var image = CachedNetworkImageProvider(
                                data['imageLink'],
                                errorListener: (object) {
                                  print('image error!');
                                },
                              );

                              await precacheImage(
                                image,
                                context,
                                size: Size(
                                  MediaQuery.of(context).size.width,
                                  MediaQuery.of(context).size.width,
                                ),
                              );

                              Map<String, CachedNetworkImageProvider> entry = {
                                data['id']: image
                              };

                              if (!LoadedImages.containsKey(data['id'])) {
                                LoadedImages.addAll(entry);
                              }

                              var cachedImage = await DefaultCacheManager()
                                  .getSingleFile(data['imageLink']);

                              var path = await appDirectory;

                              File compressedFile = await File(
                                      '$path/compressedImage/${data['id']}.jpg')
                                  .create(recursive: true);

                              var compressed =
                                  await FlutterImageCompress.compressAndGetFile(
                                cachedImage.path,
                                compressedFile.path,
                                minHeight: 200,
                                minWidth: 200,
                                quality: 0,
                              );

                              File imageFile = File(compressed!.path);

                              File file =
                                  await File('$path/blurredImage/${data['id']}')
                                      .create(recursive: true);

                              var uiImage = await compute(blurImage, imageFile);

                              file.writeAsBytesSync(
                                img.encodePng(uiImage),
                                mode: FileMode.append,
                              );

                              var blurredImage = Image.file(
                                file,
                                width: MediaQuery.of(context).size.width,
                                height: MediaQuery.of(context).size.width,
                              ).image;

                              await precacheImage(
                                blurredImage,
                                context,
                                size: Size(
                                  MediaQuery.of(context).size.width,
                                  MediaQuery.of(context).size.width,
                                ),
                              );

                              Map<String, ImageProvider> blurredEntry = {
                                data['id']: blurredImage,
                              };

                              if (!BlurImages.containsKey(data['id'])) {
                                BlurImages.addAll(blurredEntry);
                              }

                              if (!CurrentUser.requestedCreators
                                  .containsKey(data['creator'])) {
                                vibeList.add(data);

                                loadingSteps.add(
                                    'added ${data['title']} to list; ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}:${DateTime.now().millisecond}');

                                loadingCounter--;

                                setState(() {});
                              } else {}
                            }
                          }

                          DreamUpAlgorithmManager.QueryList[random] =
                              DreamUpAlgorithmManager.QueryList[random]
                                  .startAfter([newStart]);
                        } else {
                          print('should something happen here?');
                        }
                      } else {
                        debugList
                            .add('going forward at $type, nothing seen yet');

                        if (allWishesSeen) {
                          var existing = oldVibes.firstWhereOrNull(
                              (element) => element['id'] == data['id']);

                          if (existing == null) {
                            var image = CachedNetworkImageProvider(
                              data['imageLink'],
                              errorListener: (object) {
                                print('image error!');
                              },
                            );

                            await precacheImage(
                              image,
                              context,
                              size: Size(
                                MediaQuery.of(context).size.width,
                                MediaQuery.of(context).size.width,
                              ),
                            );

                            Map<String, CachedNetworkImageProvider> entry = {
                              data['id']: image
                            };

                            if (!LoadedImages.containsKey(data['id'])) {
                              LoadedImages.addAll(entry);
                            }

                            var cachedImage = await DefaultCacheManager()
                                .getSingleFile(data['imageLink']);

                            var path = await appDirectory;

                            File compressedFile = await File(
                                    '$path/compressedImage/${data['id']}.jpg')
                                .create(recursive: true);

                            var compressed =
                                await FlutterImageCompress.compressAndGetFile(
                              cachedImage.path,
                              compressedFile.path,
                              minHeight: 200,
                              minWidth: 200,
                              quality: 0,
                            );
                            File imageFile = File(compressed!.path);

                            File file =
                                await File('$path/blurredImage/${data['id']}')
                                    .create(recursive: true);

                            var uiImage = await compute(blurImage, imageFile);

                            file.writeAsBytesSync(
                              img.encodePng(uiImage),
                              mode: FileMode.append,
                            );

                            var blurredImage = Image.file(
                              file,
                              width: MediaQuery.of(context).size.width,
                              height: MediaQuery.of(context).size.width,
                            ).image;

                            await precacheImage(
                              blurredImage,
                              context,
                              size: Size(
                                MediaQuery.of(context).size.width,
                                MediaQuery.of(context).size.width,
                              ),
                            );

                            Map<String, ImageProvider> blurredEntry = {
                              data['id']: blurredImage,
                            };

                            if (!BlurImages.containsKey(data['id'])) {
                              BlurImages.addAll(blurredEntry);
                            }

                            if (!CurrentUser.requestedCreators
                                .containsKey(data['creator'])) {
                              oldVibes.add(data);

                              vibeList.add(data);

                              loadingSteps.add(
                                  'added ${data['title']} to list; ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}:${DateTime.now().millisecond}');

                              loadingCounter--;

                              setState(() {});
                            } else {}
                          }
                        } else {
                          var existing = vibeList.firstWhereOrNull(
                              (element) => element['id'] == data['id']);

                          if (existing == null) {
                            var image = CachedNetworkImageProvider(
                              data['imageLink'],
                              errorListener: (object) {
                                print('image error!');
                              },
                            );

                            await precacheImage(
                              image,
                              context,
                              size: Size(
                                MediaQuery.of(context).size.width,
                                MediaQuery.of(context).size.width,
                              ),
                            );

                            Map<String, CachedNetworkImageProvider> entry = {
                              data['id']: image
                            };

                            if (!LoadedImages.containsKey(data['id'])) {
                              LoadedImages.addAll(entry);
                            }

                            var cachedImage = await DefaultCacheManager()
                                .getSingleFile(data['imageLink']);

                            var path = await appDirectory;

                            File compressedFile = await File(
                                    '$path/compressedImage/${data['id']}.jpg')
                                .create(recursive: true);

                            var compressed =
                                await FlutterImageCompress.compressAndGetFile(
                              cachedImage.path,
                              compressedFile.path,
                              minHeight: 200,
                              minWidth: 200,
                              quality: 0,
                            );

                            File imageFile = File(compressed!.path);

                            File file =
                                await File('$path/blurredImage/${data['id']}')
                                    .create(recursive: true);

                            var uiImage = await compute(blurImage, imageFile);

                            file.writeAsBytesSync(
                              img.encodePng(uiImage),
                              mode: FileMode.append,
                            );

                            var blurredImage = Image.file(
                              file,
                              width: MediaQuery.of(context).size.width,
                              height: MediaQuery.of(context).size.width,
                            ).image;

                            await precacheImage(
                              blurredImage,
                              context,
                              size: Size(
                                MediaQuery.of(context).size.width,
                                MediaQuery.of(context).size.width,
                              ),
                            );

                            Map<String, ImageProvider> blurredEntry = {
                              data['id']: blurredImage,
                            };

                            if (!BlurImages.containsKey(data['id'])) {
                              BlurImages.addAll(blurredEntry);
                            }

                            if (!CurrentUser.requestedCreators
                                .containsKey(data['creator'])) {
                              vibeList.add(data);

                              loadingSteps.add(
                                  'added ${data['title']} to list; ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}:${DateTime.now().millisecond}');

                              loadingCounter--;

                              setState(() {});
                            } else {}
                          }
                        }

                        DreamUpAlgorithmManager.QueryList[random] =
                            DreamUpAlgorithmManager.QueryList[random]
                                .startAfter([Timestamp.fromDate(createdOn)]);
                      }
                    } else {
                      debugList.add('going forward at $type, nothing seen yet');

                      if (allWishesSeen) {
                        var existing = oldVibes.firstWhereOrNull(
                            (element) => element['id'] == data['id']);

                        if (existing == null) {
                          var image = CachedNetworkImageProvider(
                            data['imageLink'],
                            errorListener: (object) {
                              print('image error!');
                            },
                          );

                          await precacheImage(
                            image,
                            context,
                            size: Size(
                              MediaQuery.of(context).size.width,
                              MediaQuery.of(context).size.width,
                            ),
                          );

                          Map<String, CachedNetworkImageProvider> entry = {
                            data['id']: image
                          };

                          if (!LoadedImages.containsKey(data['id'])) {
                            LoadedImages.addAll(entry);
                          }

                          var cachedImage = await DefaultCacheManager()
                              .getSingleFile(data['imageLink']);

                          var path = await appDirectory;

                          File compressedFile = await File(
                                  '$path/compressedImage/${data['id']}.jpg')
                              .create(recursive: true);

                          var compressed =
                              await FlutterImageCompress.compressAndGetFile(
                            cachedImage.path,
                            compressedFile.path,
                            minHeight: 200,
                            minWidth: 200,
                            quality: 0,
                          );

                          File imageFile = File(compressed!.path);

                          File file =
                              await File('$path/blurredImage/${data['id']}')
                                  .create(recursive: true);

                          var uiImage = await compute(blurImage, imageFile);

                          file.writeAsBytesSync(
                            img.encodePng(uiImage),
                            mode: FileMode.append,
                          );

                          var blurredImage = Image.file(
                            file,
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.width,
                          ).image;

                          await precacheImage(
                            blurredImage,
                            context,
                            size: Size(
                              MediaQuery.of(context).size.width,
                              MediaQuery.of(context).size.width,
                            ),
                          );

                          Map<String, ImageProvider> blurredEntry = {
                            data['id']: blurredImage,
                          };

                          if (!BlurImages.containsKey(data['id'])) {
                            BlurImages.addAll(blurredEntry);
                          }

                          if (!CurrentUser.requestedCreators
                              .containsKey(data['creator'])) {
                            oldVibes.add(data);

                            vibeList.add(data);

                            loadingSteps.add(
                                'added ${data['title']} to list; ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}:${DateTime.now().millisecond}');

                            loadingCounter--;

                            setState(() {});
                          } else {}
                        }
                      } else {
                        var existing = vibeList.firstWhereOrNull(
                            (element) => element['id'] == data['id']);

                        if (existing == null) {
                          var image = CachedNetworkImageProvider(
                            data['imageLink'],
                            errorListener: (object) {
                              print('image error!');
                            },
                          );

                          await precacheImage(
                            image,
                            context,
                            size: Size(
                              MediaQuery.of(context).size.width,
                              MediaQuery.of(context).size.width,
                            ),
                          );

                          Map<String, CachedNetworkImageProvider> entry = {
                            data['id']: image
                          };

                          if (!LoadedImages.containsKey(data['id'])) {
                            LoadedImages.addAll(entry);
                          }

                          var cachedImage = await DefaultCacheManager()
                              .getSingleFile(data['imageLink']);

                          var path = await appDirectory;

                          File compressedFile = await File(
                                  '$path/compressedImage/${data['id']}.jpg')
                              .create(recursive: true);

                          var compressed =
                              await FlutterImageCompress.compressAndGetFile(
                            cachedImage.path,
                            compressedFile.path,
                            minHeight: 200,
                            minWidth: 200,
                            quality: 0,
                          );

                          File imageFile = File(compressed!.path);

                          File file =
                              await File('$path/blurredImage/${data['id']}')
                                  .create(recursive: true);

                          var uiImage = await compute(blurImage, imageFile);

                          file.writeAsBytesSync(
                            img.encodePng(uiImage),
                            mode: FileMode.append,
                          );

                          var blurredImage = Image.file(
                            file,
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.width,
                          ).image;

                          await precacheImage(
                            blurredImage,
                            context,
                            size: Size(
                              MediaQuery.of(context).size.width,
                              MediaQuery.of(context).size.width,
                            ),
                          );

                          Map<String, ImageProvider> blurredEntry = {
                            data['id']: blurredImage,
                          };

                          if (!BlurImages.containsKey(data['id'])) {
                            BlurImages.addAll(blurredEntry);
                          }

                          if (!CurrentUser.requestedCreators
                              .containsKey(data['creator'])) {
                            vibeList.add(data);

                            loadingSteps.add(
                                'added ${data['title']} to list; ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}:${DateTime.now().millisecond}');

                            loadingCounter--;

                            setState(() {});
                          } else {}
                        }
                      }

                      DreamUpAlgorithmManager.QueryList[random] =
                          DreamUpAlgorithmManager.QueryList[random]
                              .startAfter([Timestamp.fromDate(createdOn)]);
                    }
                  }

                  if (documents.docs.isEmpty) {
                    var connection =
                        await InternetConnectionChecker().hasConnection;

                    if (connection) {
                      DreamUpAlgorithmManager.QueryList.removeAt(random);
                    } else {
                      print('no connection!');

                      if (!offline) {
                        print('by 4');
                        handleDisconnect('fill');
                      }
                    }
                  }
                },
                onError: (e) => print(e),
              );

              if (fillTime == Duration.zero) {
                fillTime = DateTime.now().difference(start);
              }
            }
          } else {
            if (DreamUpAlgorithmManager.QueryList.isNotEmpty) {
              var random =
                  Random().nextInt(DreamUpAlgorithmManager.QueryList.length);

              try {
                await DreamUpAlgorithmManager.QueryList[random].get().then(
                  (documents) async {
                    for (var doc in documents.docs) {
                      var data = doc.data() as Map<String, dynamic>;

                      var createdOn = (data['createdOn'] as Timestamp).toDate();

                      if (allWishesSeen) {
                        var existing = oldVibes.firstWhereOrNull(
                            (element) => element['id'] == data['id']);

                        if (existing == null) {
                          var image = CachedNetworkImageProvider(
                            data['imageLink'],
                            errorListener: (object) {
                              print('image error!');
                            },
                          );

                          await precacheImage(
                            image,
                            context,
                            size: Size(
                              MediaQuery.of(context).size.width,
                              MediaQuery.of(context).size.width,
                            ),
                          );

                          Map<String, CachedNetworkImageProvider> entry = {
                            data['id']: image
                          };

                          if (!LoadedImages.containsKey(data['id'])) {
                            LoadedImages.addAll(entry);
                          }

                          var cachedImage = await DefaultCacheManager()
                              .getSingleFile(data['imageLink']);

                          var path = await appDirectory;

                          File compressedFile = await File(
                                  '$path/compressedImage/${data['id']}.jpg')
                              .create(recursive: true);

                          var compressed =
                              await FlutterImageCompress.compressAndGetFile(
                            cachedImage.path,
                            compressedFile.path,
                            minHeight: 200,
                            minWidth: 200,
                            quality: 0,
                          );
                          File imageFile = File(compressed!.path);

                          File file =
                              await File('$path/blurredImage/${data['id']}')
                                  .create(recursive: true);

                          var uiImage = await compute(blurImage, imageFile);

                          file.writeAsBytesSync(
                            img.encodePng(uiImage),
                            mode: FileMode.append,
                          );

                          var blurredImage = Image.file(
                            file,
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.width,
                          ).image;

                          await precacheImage(
                            blurredImage,
                            context,
                            size: Size(
                              MediaQuery.of(context).size.width,
                              MediaQuery.of(context).size.width,
                            ),
                          );

                          Map<String, ImageProvider> blurredEntry = {
                            data['id']: blurredImage,
                          };

                          if (!BlurImages.containsKey(data['id'])) {
                            BlurImages.addAll(blurredEntry);
                          }

                          if (!CurrentUser.requestedCreators
                              .containsKey(data['creator'])) {
                            oldVibes.add(data);

                            vibeList.add(data);

                            loadingSteps.add(
                                'added ${data['title']} to list; ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}:${DateTime.now().millisecond}');

                            loadingCounter--;

                            setState(() {});
                          } else {}
                        }
                      } else {
                        var existing = vibeList.firstWhereOrNull(
                            (element) => element['id'] == data['id']);

                        if (existing == null) {
                          var image = CachedNetworkImageProvider(
                            data['imageLink'],
                            errorListener: (object) {
                              print('image error!');
                            },
                          );

                          await precacheImage(
                            image,
                            context,
                            size: Size(
                              MediaQuery.of(context).size.width,
                              MediaQuery.of(context).size.width,
                            ),
                          );

                          Map<String, CachedNetworkImageProvider> entry = {
                            data['id']: image
                          };

                          if (!LoadedImages.containsKey(data['id'])) {
                            LoadedImages.addAll(entry);
                          }

                          var cachedImage = await DefaultCacheManager()
                              .getSingleFile(data['imageLink']);

                          var path = await appDirectory;

                          File compressedFile = await File(
                                  '$path/compressedImage/${data['id']}.jpg')
                              .create(recursive: true);

                          var compressed =
                              await FlutterImageCompress.compressAndGetFile(
                            cachedImage.path,
                            compressedFile.path,
                            minHeight: 200,
                            minWidth: 200,
                            quality: 0,
                          );
                          File imageFile = File(compressed!.path);

                          File file =
                              await File('$path/blurredImage/${data['id']}')
                                  .create(recursive: true);

                          var uiImage = await compute(blurImage, imageFile);

                          file.writeAsBytesSync(
                            img.encodePng(uiImage),
                            mode: FileMode.append,
                          );

                          var blurredImage = Image.file(
                            file,
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.width,
                          ).image;

                          await precacheImage(
                            blurredImage,
                            context,
                            size: Size(
                              MediaQuery.of(context).size.width,
                              MediaQuery.of(context).size.width,
                            ),
                          );

                          Map<String, ImageProvider> blurredEntry = {
                            data['id']: blurredImage,
                          };

                          if (!BlurImages.containsKey(data['id'])) {
                            BlurImages.addAll(blurredEntry);
                          }

                          if (!CurrentUser.requestedCreators
                              .containsKey(data['creator'])) {
                            vibeList.add(data);

                            loadingSteps.add(
                                'added ${data['title']} to list; ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}:${DateTime.now().millisecond}');

                            loadingCounter--;

                            setState(() {});
                          } else {}
                        }
                      }

                      Timestamp newStart = Timestamp.fromDate(createdOn);

                      DreamUpAlgorithmManager.QueryList[random] =
                          DreamUpAlgorithmManager.QueryList[random]
                              .startAfter([newStart]);
                    }

                    if (documents.docs.isEmpty) {
                      var connection =
                          await InternetConnectionChecker().hasConnection;

                      if (connection) {
                        DreamUpAlgorithmManager.QueryList.removeAt(random);
                      } else {
                        print('no connection!');

                        if (!offline) {
                          print('by 7');
                          handleDisconnect('fill');
                        }
                      }
                    }
                  },
                );
              } on Exception catch (e) {
                print('connection Error: $e');
              }
            } else {
              print('Query List is empty');

              loadingCounter = 0;

              break;
            }
          }
        }
      } else {
        print('by whatever');

        currentlyFilling = false;

        handleDisconnect('fill');
      }

      var connection = await InternetConnectionChecker().hasConnection;

      if ((vibeList.isEmpty || vibeList.length == 1) &&
          connection &&
          !DreamUpAlgorithmManager.filtering) {
        DreamUpAlgorithmManager.QueryList.clear();

        seenVibes.clear();
        await CurrentUser().deleteSeenVibes();

        currentlyFilling = false;

        await instantiateAlgorithmQueries('', context);
      } else if (!connection) {
        print('no connection!');
      }

      if (loadingTime == Duration.zero) {
        loadingTime = DateTime.now().difference(loadingStart);
      }

      currentlyFilling = false;

      loadingCounter = 0;

      print('filling finished');
    }
  }

  late DraggableScrollableController connectDragController;

  bool applyFilter = false;

  bool descriptionExpanded = false;

  late StreamSubscription<InternetConnectionStatus> internetChecker;

  bool offline = false;

  List<Map<String, dynamic>> contactInfo = [];

  int seenCounter() {
    int count = 0;

    for (var entry in DebugTool.FriendshipDreamUps) {
      int value = entry['count'];

      count += value;
    }

    for (var entry in DebugTool.ActionDreamUps) {
      int value = entry['count'];

      count += value;
    }

    return count;
  }

  void handleDisconnect(String state) {
    offline = true;

    print('is offline');
    print(state);

    late StreamSubscription<InternetConnectionStatus>? subscription;

    var timer = Timer(
      const Duration(seconds: 10),
      () {
        subscription?.cancel();

        if (!ModalRoute.of(context)!.isCurrent) {
          Navigator.pop(context);
        }

        if (!ModalRoute.of(context)!.isCurrent) {
          Navigator.pop(context);
        }

        loadingCounter = 0;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            insetPadding:
                EdgeInsets.all(MediaQuery.of(context).size.width * 0.1),
            child: Container(
              padding: EdgeInsets.all(
                MediaQuery.of(context).size.width * 0.05,
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.signal_wifi_bad_rounded,
                  ),
                  Text('No Connection!'),
                ],
              ),
            ),
          ),
        );

        var checker = InternetConnectionChecker.createInstance(
          checkInterval: const Duration(seconds: 1),
          checkTimeout: const Duration(seconds: 1),
        );

        internetChecker = checker.onStatusChange.listen((status) async {
          if (status == InternetConnectionStatus.connected) {
            offline = false;

            if (!ModalRoute.of(context)!.isCurrent && !offline) {
              Navigator.pop(context);
            }

            if (state == 'initial') {
              if (backwardCount != 0) {
                backwardCount = 0;
              }

              showDialog(
                barrierDismissible: false,
                context: context,
                builder: (context) => Dialog(
                  insetPadding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.4,
                  ),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.2,
                    height: MediaQuery.of(context).size.width * 0.2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      padding: EdgeInsets.all(
                        MediaQuery.of(context).size.width * 0.05,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                ),
              );

              if (!DreamUpAlgorithmManager.filtering) {
                await instantiateAlgorithmQueries('', context);

                filterType = '';
              } else {
                await instantiateAlgorithmQueries(filterType, context);
              }

              if (refreshing) {
                isNewVibe = true;

                refreshing = false;
              }

              if (applyFilter) {
                isNewVibe = true;

                applyFilter = false;
              }

              if (!ModalRoute.of(context)!.isCurrent && !offline) {
                Navigator.pop(context);
              }
            } else if (state == 'fill') {
              showDialog(
                barrierDismissible: false,
                context: context,
                builder: (context) => Dialog(
                  insetPadding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.4,
                  ),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.2,
                    height: MediaQuery.of(context).size.width * 0.2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      padding: EdgeInsets.all(
                        MediaQuery.of(context).size.width * 0.05,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                ),
              );

              if (!DreamUpAlgorithmManager.filtering) {
                await instantiateAlgorithmQueries('', context);

                filterType = '';
              } else {
                await instantiateAlgorithmQueries(filterType, context);
              }

              if (refreshing) {
                isNewVibe = true;

                refreshing = false;
              }

              if (applyFilter) {
                isNewVibe = true;

                applyFilter = false;
              }

              if (!ModalRoute.of(context)!.isCurrent && !offline) {
                Navigator.pop(context);
              }
            }

            internetChecker.cancel();
          } else {
            print('checking for connection');

            subscription?.cancel();
          }
        });
      },
    );

    var connectionChecker = InternetConnectionChecker.createInstance(
      checkInterval: const Duration(seconds: 1),
      checkTimeout: const Duration(seconds: 1),
    );

    subscription = connectionChecker.onStatusChange.listen((status) async {
      if (status == InternetConnectionStatus.connected) {
        print('reconnected!');

        timer.cancel();

        print('online again!');

        offline = false;

        if (state == 'initial') {
          if (backwardCount != 0) {
            backwardCount = 0;
          }

          if (!DreamUpAlgorithmManager.filtering) {
            await instantiateAlgorithmQueries('', context);

            filterType = '';
          } else {
            await instantiateAlgorithmQueries(filterType, context);
          }

          if (!ModalRoute.of(context)!.isCurrent && !offline) {
            Navigator.pop(context);
          }

          if (refreshing) {
            isNewVibe = true;

            refreshing = false;
          }

          if (applyFilter) {
            isNewVibe = true;

            applyFilter = false;
          }

          filterType = '';
        } else if (state == 'fill') {
          if (!DreamUpAlgorithmManager.filtering) {
            await instantiateAlgorithmQueries('', context);

            filterType = '';
          } else {
            await instantiateAlgorithmQueries(filterType, context);
          }

          if (refreshing) {
            isNewVibe = true;

            refreshing = false;
          }

          if (applyFilter) {
            isNewVibe = true;

            applyFilter = false;
          }

          if (!ModalRoute.of(context)!.isCurrent && !offline) {
            Navigator.pop(context);
          }
        }

        subscription?.cancel();
      }
    });

    if (state == 'fill' && !applyFilter) {
      if (!ModalRoute.of(context)!.isCurrent && !offline) {
        Navigator.pop(context);
      }

      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.4,
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.2,
            height: MediaQuery.of(context).size.width * 0.2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
              ),
              padding: EdgeInsets.all(
                MediaQuery.of(context).size.width * 0.05,
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ),
      );
    }
  }

  bool uploading = false;

  Future contactCreator(String message) async {
    var creatorId = vibeList[currentIndex]['creator'];

    if (!CurrentUser.requestedCreators.containsKey(creatorId)) {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.4,
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.2,
            height: MediaQuery.of(context).size.width * 0.2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
              ),
              padding: EdgeInsets.all(
                MediaQuery.of(context).size.width * 0.05,
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ),
      );

      var id = vibeList[currentIndex]['id'];

      var requestChat = FirebaseFirestore.instance.collection('chats').doc();

      var creatorDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(vibeList[currentIndex]['creator'])
          .get();
      var creatorInfo = creatorDoc.data()!;

      var name = creatorInfo['name'];

      Map<String, dynamic> chatInfo = {
        'id': requestChat.id,
        'images': {
          currentUser: CurrentUser.imageLink,
          vibeList[currentIndex]['creator']: creatorInfo['imageLink'],
        },
        'lastAction': DateTime.now(),
        'lastSender': currentUser,
        'lastLogin': {
          currentUser: DateTime.now(),
          vibeList[currentIndex]['creator']: DateTime.now(),
        },
        'names': [
          name,
          CurrentUser.name,
        ],
        'new': true,
        'onlineUsers': [],
        'participants': [
          vibeList[currentIndex]['creator'],
        ],
        'users': {
          vibeList[currentIndex]['creator']: null,
          currentUser: null,
        },
        'isRequest': true,
      };

      await requestChat.set(chatInfo);

      DateTime now = DateTime.now();

      DateTime imageTime =
          DateTime(now.year, now.month, now.day, now.hour, now.minute, 0);
      DateTime messageTime =
          DateTime(now.year, now.month, now.day, now.hour, now.minute, 1);
      DateTime systemTime =
          DateTime(now.year, now.month, now.day, now.hour, now.minute, 2);

      var imageDoc = FirebaseFirestore.instance
          .collection('chats')
          .doc(requestChat.id)
          .collection('messages')
          .doc();

      Map<String, dynamic> imageContent = {
        'content': vibeList[currentIndex]['imageLink'],
        'createdOn': imageTime,
        'creatorId': currentUser,
        'imageSubText': vibeList[currentIndex]['title'],
        'messageId': imageDoc.id,
        'type': 'image',
      };

      var messageDoc = FirebaseFirestore.instance
          .collection('chats')
          .doc(requestChat.id)
          .collection('messages')
          .doc();

      Map<String, dynamic> messageContent = {
        'content': message,
        'createdOn': messageTime,
        'creatorId': currentUser,
        'messageId': messageDoc.id,
        'type': 'text',
      };

      var systemDoc = FirebaseFirestore.instance
          .collection('chats')
          .doc(requestChat.id)
          .collection('messages')
          .doc();

      Map<String, dynamic> systemMessage = {
        'content': '',
        'createdOn': systemTime,
        'creatorId': currentUser,
        'messageId': systemDoc.id,
        'type': 'system',
      };

      await imageDoc.set(imageContent);
      await messageDoc.set(messageContent);

      await systemDoc.set(systemMessage);

      CurrentUser.icebreakers.addAll(
        {
          id: message,
        },
      );

      CurrentUser.requestedCreators.addAll(
        {
          creatorId: name,
        },
      );

      await CurrentUser().saveUserInformation();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser)
          .collection('requestedCreators')
          .add(
        {
          'userId': creatorId,
          'userName': name,
        },
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(creatorId)
          .collection('requestedCreators')
          .add(
        {
          'userId': currentUser,
          'userName': CurrentUser.name,
        },
      );

      int count = 0;

      List<int> indexes = [];

      for (int i = 0; i < vibeList.length; i++) {
        var thisVibe = vibeList[i];

        if (thisVibe['creator'] == creatorId && thisVibe['id'] != id) {
          if (i <= currentIndex) {
            count++;
          }

          indexes.add(i);
        }
      }

      var reverse = indexes.reversed;

      for (var index in reverse) {
        vibeList.removeAt(index);
      }

      currentIndex = max(0, currentIndex - count);
      maxIndex = currentIndex;

      refreshCounter++;

      Fluttertoast.showToast(msg: 'request sent');

      contactInfo.clear();

      int puffer = vibeList.length - currentIndex;
      loadingCounter = puffer > 4 ? 0 : 4 - puffer;

      await fillDreamUpList(context);

      Navigator.pop(context);

      setState(() {});
    } else {
      Fluttertoast.showToast(
        msg: 'Wie es aussieht, wurde dieser DreamUp gerade gelöscht!',
      );
    }
  }

  void reloadImages() {
    for (var image in LoadedImages.keys) {
      precacheImage(
        LoadedImages[image]!,
        context,
        size: Size(
          MediaQuery.of(context).size.width,
          MediaQuery.of(context).size.width,
        ),
      );
    }

    for (var image in BlurImages.keys) {
      precacheImage(
        BlurImages[image]!,
        context,
        size: Size(
          MediaQuery.of(context).size.width,
          MediaQuery.of(context).size.width,
        ),
      );
    }
  }

  TextEditingController contactController = TextEditingController();

  @override
  void initState() {
    super.initState();

    contactController.addListener(() {
      setState(() {});
    });

    currentlyFilling = false;

    connectDragController = DraggableScrollableController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      reloadImages();

      if (vibeList.isEmpty && currentIndex == 0) {
        var path = await appDirectory;

        var blurred = Directory('$path/blurredImage/');
        var compressed = Directory('$path/compressedImage/');

        if (blurred.existsSync()) {
          blurred.deleteSync(recursive: true);

          print('blurred images deleted');
        }

        if (compressed.existsSync()) {
          compressed.deleteSync(recursive: true);

          print('compressed images deleted');
        }
      }

      if (loadingCounter > 0 && loadingCounter < 4) {
        await fillDreamUpList(context);
      }

      if (vibeList.isEmpty) {
        loading = true;
        setState(() {});

        await instantiateAlgorithmQueries('', context).then((value) async {
          if (!offline) {
            if (!ModalRoute.of(context)!.isCurrent) {
              Navigator.pop(context);
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    currentlyFilling = false;

    connectDragController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var provider = Provider.of<HomeBarControlProvider>(context, listen: true);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black87,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: vibeList.length,
              itemBuilder: (context, index) {
                if (isNewVibe && !DreamUpAlgorithmManager.filtering) {
                  var newVibe = vibeList[currentIndex];

                  String id = newVibe['id'];
                  String type = newVibe['type'];
                  String title = newVibe['title'];

                  var createdOn = (newVibe['createdOn'] as Timestamp).toDate();

                  var existing = seenVibes.containsKey(type);

                  if (existing) {
                    var last = seenVibes[type]!.last as Map;

                    var lastLogin = DateTime.parse(last.entries.first.key);
                    var lastCreation = DateTime.parse(last.entries.first.value);

                    if (logInTime != lastLogin) {
                      seenVibes[type]!.add(
                        {
                          logInTime.toString(): createdOn.toString(),
                        },
                      );
                    } else {
                      if (seenVibes[type]!.length > 1) {
                        var secondLast =
                            seenVibes[type]![seenVibes[type]!.length - 2]
                                as Map;

                        var secondCreation =
                            DateTime.parse(secondLast.entries.first.value);
                        var secondLogin =
                            DateTime.parse(secondLast.entries.first.key);

                        if (!createdOn.isAfter(secondLogin)) {
                          seenVibes[type]!.removeLast();
                          seenVibes[type]!.removeLast();

                          seenVibes[type]!.add({
                            logInTime.toString(): secondCreation.toString(),
                          });
                        } else if (!createdOn.isBefore(lastCreation)) {
                          seenVibes[type]!.removeLast();
                          seenVibes[type]!.removeLast();

                          seenVibes[type]!.add({
                            logInTime.toString(): secondCreation.toString(),
                          });
                        } else {
                          seenVibes[type]!.removeLast();

                          seenVibes[type]!.add({
                            logInTime.toString(): createdOn.toString(),
                          });
                        }
                      } else {
                        if (createdOn.isBefore(lastCreation)) {
                          seenVibes[type]!.removeLast();

                          seenVibes[type]!.add({
                            logInTime.toString(): createdOn.toString(),
                          });
                        } else {
                          print('$title: something is wrong!');
                        }
                      }
                    }
                  } else {
                    Map<String, List<Map<String, String>>> entry = {
                      type: [
                        {
                          logInTime.toString(): createdOn.toString(),
                        }
                      ]
                    };

                    seenVibes.addAll(entry);
                  }

                  if (type == 'Freundschaft') {
                    var dreamUp = DebugTool.FriendshipDreamUps.firstWhereOrNull(
                        (element) => element['id'] == id);

                    if (dreamUp != null) {
                      var count = dreamUp['count'];

                      dreamUp['count'] = count + 1;
                      dreamUp['seen'] = true;

                      DebugTool().saveInfo(type);
                    }
                  } else {
                    var dreamUp = DebugTool.ActionDreamUps.firstWhereOrNull(
                        (element) => element['id'] == id);

                    if (dreamUp != null) {
                      var count = dreamUp['count'];

                      dreamUp['count'] = count + 1;
                      dreamUp['seen'] = true;

                      DebugTool().saveInfo(type);
                    }
                  }

                  Future.delayed(
                    Duration.zero,
                    () async {
                      if (id == lastFriendshipId) {
                        sawAllFriendships = true;

                        print('saw all friendships');
                      }

                      if (id == lastActionId) {
                        sawAllActions = true;

                        print('saw all actions');
                      }

                      if (sawAllActions && sawAllActions) {
                        print('is last DreamUp');

                        seenVibes.clear();

                        await CurrentUser().deleteSeenVibes();

                        await CurrentUser().saveUserInformation();

                        sawAllFriendships = false;
                        sawAllActions = false;
                      } else {
                        print('saving as seen');

                        await CurrentUser()
                            .saveSeenVibes(type, seenVibes[type]!);
                      }

                      setState(() {});
                    },
                  );

                  isNewVibe = false;
                }

                return SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Positioned.fill(
                        child: MainScreenBackground(
                          key: Key(vibeList[currentIndex]['id']),
                        ),
                      ),
                      Positioned.fill(
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (scroll) {
                            if (scroll is ScrollUpdateNotification) {
                              if (currentIndex == 0 &&
                                  scroll.dragDetails != null &&
                                  scroll.metrics.pixels <=
                                      -MediaQuery.of(context).size.height *
                                          0.1 &&
                                  !descriptionExpanded) {
                                if (!DreamUpAlgorithmManager.filtering &&
                                    !refreshing) {
                                  refreshing = true;

                                  showDialog(
                                    barrierDismissible: false,
                                    context: context,
                                    builder: (context) => Dialog(
                                      insetPadding: EdgeInsets.symmetric(
                                        horizontal:
                                            MediaQuery.of(context).size.width *
                                                0.4,
                                      ),
                                      child: SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.2,
                                        height:
                                            MediaQuery.of(context).size.width *
                                                0.2,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          padding: EdgeInsets.all(
                                            MediaQuery.of(context).size.width *
                                                0.05,
                                          ),
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );

                                  creatorWishes.clear();
                                  creatorInfo.clear();

                                  Future.delayed(
                                    Duration.zero,
                                    () async {
                                      for (int i = 0; i < maxIndex + 1; i++) {
                                        if (vibeList.isEmpty) {
                                          break;
                                        }

                                        vibeList.removeAt(0);
                                      }

                                      var difference = 4 - vibeList.length;

                                      loadingCounter = max(0, difference);

                                      print(
                                          'needs to load $loadingCounter new dreamUps');

                                      if (!currentlyFilling) {
                                        await fillDreamUpList(context);
                                      }

                                      maxIndex = currentIndex;

                                      setState(() {});

                                      refreshCounter++;

                                      backwardCount = 0;

                                      isNewVibe = true;

                                      currentlyLoading = false;

                                      refreshing = false;

                                      scrolling = false;

                                      Timer.periodic(
                                          const Duration(
                                            milliseconds: 100,
                                          ), (timer) async {
                                        print(
                                            'loadingCounter: $loadingCounter');

                                        if (loadingCounter == 0) {
                                          timer.cancel();

                                          Navigator.pop(context);
                                        }
                                      });
                                    },
                                  );
                                }
                              }

                              if (scroll.metrics.pixels >=
                                      scroll.metrics.maxScrollExtent + 20 &&
                                  !currentlyLoading &&
                                  currentIndex + 1 == vibeList.length) {
                                currentlyLoading = true;

                                if (DreamUpAlgorithmManager.QueryList.isEmpty) {
                                  if (DreamUpAlgorithmManager.filtering) {
                                    DreamUpAlgorithmManager.filtering = false;

                                    creatorWishes.clear();
                                    creatorInfo.clear();

                                    showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder: (context) => Dialog(
                                        insetPadding: EdgeInsets.symmetric(
                                          horizontal: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.2,
                                          vertical: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.3,
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(15),
                                          ),
                                          padding: EdgeInsets.all(
                                            MediaQuery.of(context).size.width *
                                                0.05,
                                          ),
                                          child: Center(
                                            child: Text(
                                              'Es sind keine weiteren DreamUps von "$filterType" mehr übrig. Wir leiten dich wieder in deinen normalen Thread.',
                                              style: const TextStyle(
                                                fontSize: 18,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );

                                    DefaultCacheManager().emptyCache().then(
                                      (value) async {
                                        currentIndex = 0;
                                        maxIndex = currentIndex;

                                        vibeList.clear();
                                        oldVibes.clear();

                                        setState(() {});

                                        refreshCounter++;

                                        LoadedImages.clear();
                                        BlurImages.clear();

                                        await instantiateAlgorithmQueries(
                                          '',
                                          context,
                                        ).then(
                                          (value) async {
                                            filterType = '';

                                            backwardCount = 0;

                                            isNewVibe = true;

                                            currentlyLoading = false;

                                            Navigator.pop(context);

                                            setState(() {});
                                          },
                                        );
                                      },
                                    );
                                  }
                                } else {
                                  creatorWishes.clear();
                                  creatorInfo.clear();

                                  showDialog(
                                    barrierDismissible: false,
                                    context: context,
                                    builder: (context) {
                                      Future.delayed(
                                        Duration.zero,
                                        () async {
                                          loadingCounter = 4;

                                          await fillDreamUpList(context);
                                        },
                                      );

                                      Timer.periodic(
                                          const Duration(
                                            milliseconds: 100,
                                          ), (timer) async {
                                        if (mounted) {
                                          setState(() {});
                                        }

                                        if (loadingCounter == 0) {
                                          timer.cancel();

                                          currentIndex++;
                                          maxIndex++;

                                          refreshCounter++;

                                          if (mounted) {
                                            setState(() {});
                                          }

                                          isNewVibe = true;

                                          Navigator.pop(context);

                                          currentlyLoading = false;

                                          if (mounted) {
                                            setState(() {});
                                          }
                                        }
                                      });

                                      return Dialog(
                                        insetPadding: EdgeInsets.symmetric(
                                          horizontal: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.4,
                                        ),
                                        child: SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.2,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.2,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                            padding: EdgeInsets.all(
                                              MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.05,
                                            ),
                                            child: const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }
                              }
                            }

                            return true;
                          },
                          child: PageView.builder(
                            key: Key(
                              refreshCounter.toString(),
                            ),
                            padEnds: false,
                            scrollDirection: Axis.vertical,
                            controller: PageController(
                              initialPage: currentIndex,
                              viewportFraction: 1,
                            ),
                            physics: descriptionExpanded
                                ? const NeverScrollableScrollPhysics()
                                : const CustomScrollPhysics(),
                            itemCount: vibeList.length,
                            itemBuilder: (BuildContext context, int index) {
                              return DreamUpScrollItem(
                                showPanel: () {
                                  setState(() {});
                                },
                                expandDescription: (expand) {
                                  descriptionExpanded = expand;

                                  setState(() {});
                                },
                                connectionDragController: connectDragController,
                                vibeData: vibeList[index],
                                controller: carouselController,
                                animationHeight: currentSheetHeight,
                              );
                            },
                            onPageChanged: (ind) async {
                              print('on page changed is called');

                              creatorInfo.clear();
                              creatorWishes.clear();

                              var oldIndex = currentIndex;
                              bool goingForward;

                              currentIndex = ind;
                              if (currentIndex > maxIndex) {
                                maxIndex = currentIndex;
                              }

                              print(maxIndex);

                              if (currentIndex > oldIndex) {
                                goingForward = true;

                                if (oldIndex == 0 && currentIndex != 1) {
                                  goingForward = false;
                                }
                              } else {
                                goingForward = false;

                                if (currentIndex == 0 && oldIndex != 1) {
                                  goingForward = true;
                                }
                              }

                              if (goingForward && backwardCount < 1) {
                                if (!DreamUpAlgorithmManager.filtering) {
                                  isNewVibe = true;
                                }

                                loadingCounter++;

                                fillDreamUpList(context)
                                    .then((value) => setState(() {}));
                              }

                              if (goingForward && backwardCount > 0) {
                                backwardCount--;
                              } else if (!goingForward) {
                                backwardCount++;
                              }

                              setState(() {});
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        top: MediaQuery.of(context).padding.top,
                        left: 0,
                        right: 0,
                        child: AnimatedOpacity(
                          duration: Duration.zero,
                          opacity: 1 - currentSheetHeight / 0.8,
                          child: SizedBox(
                            height: 50,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      changePage(
                                        const DreamUpSearchPage(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    color: Colors.transparent,
                                    width: MediaQuery.of(context).size.width *
                                        0.15,
                                    child: const Center(
                                      child: DecoratedIcon(
                                        Icons.search_rounded,
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
                                GestureDetector(
                                  onTap: () async {
                                    if (!refreshing && !scrolling) {
                                      refreshing = true;

                                      logInTime = DateTime.now();

                                      DreamUpAlgorithmManager.filtering = false;

                                      showDialog(
                                        barrierDismissible: false,
                                        context: context,
                                        builder: (context) => Dialog(
                                          insetPadding: EdgeInsets.symmetric(
                                            horizontal: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.4,
                                          ),
                                          child: SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.2,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.2,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                              padding: EdgeInsets.all(
                                                MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.05,
                                              ),
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );

                                      DefaultCacheManager().emptyCache().then(
                                        (value) async {
                                          currentIndex = 0;
                                          maxIndex = currentIndex;

                                          setState(() {});

                                          vibeList.clear();
                                          oldVibes.clear();
                                          seenVibes.clear();

                                          LoadedImages.clear();
                                          BlurImages.clear();

                                          var path = await appDirectory;

                                          var blurred =
                                              Directory('$path/blurredImage/');
                                          var compressed = Directory(
                                              '$path/compressedImage/');

                                          if (blurred.existsSync()) {
                                            blurred.deleteSync(recursive: true);

                                            print('blurred images deleted');
                                          }

                                          if (compressed.existsSync()) {
                                            compressed.deleteSync(
                                                recursive: true);

                                            print('compressed images deleted');
                                          }

                                          await CurrentUser().deleteSeenVibes();

                                          CurrentUser.icebreakers.clear();

                                          await CurrentUser()
                                              .saveUserInformation();

                                          await DebugTool().deleteInfo();

                                          loadingCounter = 4;

                                          oldCounter = 0;

                                          await instantiateAlgorithmQueries(
                                            '',
                                            context,
                                          ).then(
                                            (value) async {
                                              isNewVibe = true;

                                              Navigator.pop(context);

                                              backwardCount = 0;

                                              setState(() {});

                                              refreshing = false;
                                            },
                                          );
                                        },
                                      );
                                    }
                                  },
                                  child: Container(
                                    height: 50,
                                    width:
                                        MediaQuery.of(context).size.width * 0.6,
                                    color: Colors.transparent,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    applyFilter
                                        ? applyFilter = false
                                        : applyFilter = true;

                                    setState(() {});
                                  },
                                  child: Container(
                                    color: Colors.transparent,
                                    width: MediaQuery.of(context).size.width *
                                        0.15,
                                    child: Center(
                                      child: DecoratedIcon(
                                        DreamUpAlgorithmManager.filtering
                                            ? Icons.filter_alt
                                            : Icons.filter_alt_outlined,
                                        color: DreamUpAlgorithmManager.filtering
                                            ? Colors.blue
                                            : Colors.white,
                                        shadows: const [
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
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 50,
                        left: 0,
                        child: Container(
                          color: Colors.transparent,
                          height: 50,
                          width: 70,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                showDebugTool
                                    ? showDebugTool = false
                                    : showDebugTool = true;
                              });
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 50,
                        right: 0,
                        child: Container(
                          color: Colors.transparent,
                          height: 50,
                          width: 70,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                showLoadingDebugger
                                    ? showLoadingDebugger = false
                                    : showLoadingDebugger = true;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 55,
            left: MediaQuery.of(context).size.width * 0.025,
            child: Visibility(
              visible: showDebugTool,
              child: Container(
                color: Colors.white.withOpacity(0.7),
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.4,
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${seenCounter()}/${DebugTool.FriendshipDreamUps.length + DebugTool.ActionDreamUps.length} DreamUps seen',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Expanded(
                          child: Container(),
                        ),
                        GestureDetector(
                          onTap: () async {
                            await DebugTool().updateDreamUps();

                            setState(() {});
                          },
                          child: const Icon(
                            Icons.restart_alt_rounded,
                          ),
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        GestureDetector(
                          onTap: () async {
                            showDebugTool = false;

                            setState(() {});
                          },
                          child: const Icon(
                            Icons.cancel,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Aktionen',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.only(
                                left: 10,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: DebugTool.ActionDreamUps.map<Widget>(
                                    (entry) {
                                  bool blocked = CurrentUser.requestedCreators
                                      .containsKey(entry['creator']);

                                  return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        entry['title'],
                                        style: TextStyle(
                                          color: blocked
                                              ? Colors.red
                                              : Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        entry['count'].toString(),
                                        style: TextStyle(
                                          color: blocked
                                              ? Colors.red
                                              : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                            const Text(
                              'Freundschaften',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.only(
                                left: 10,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children:
                                    DebugTool.FriendshipDreamUps.map<Widget>(
                                        (entry) {
                                  bool blocked = CurrentUser.requestedCreators
                                      .containsKey(entry['creator']);

                                  return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        entry['title'],
                                        style: TextStyle(
                                          color: blocked
                                              ? Colors.red
                                              : Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        entry['count'].toString(),
                                        style: TextStyle(
                                          color: blocked
                                              ? Colors.red
                                              : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
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
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 55,
            left: 0,
            right: 0,
            child: Visibility(
              visible: showLoadingDebugger,
              child: GestureDetector(
                onTap: () {
                  setState(() {});
                },
                child: Container(
                  color: Colors.white,
                  height: MediaQuery.of(context).size.height * 0.2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(),
                          ),
                          GestureDetector(
                            onTap: () {
                              showLoadingDebugger = false;

                              setState(() {});
                            },
                            child: Container(
                              color: Colors.transparent,
                              padding: const EdgeInsets.all(8),
                              child: const Icon(
                                Icons.cancel,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'App Version 23.11.',
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'database requests in pipeline: $loadingCounter',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Visibility(
              visible: applyFilter,
              child: GestureDetector(
                onTap: () {
                  applyFilter = false;

                  setState(() {});
                },
                child: Container(
                  color: Colors.transparent,
                  child: Stack(
                    children: [
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 55,
                        right: MediaQuery.of(context).size.width * 0.025,
                        child: DreamUpFilterWidget(
                          filterVibes: (String type) {
                            filterType = type;

                            if (!refreshing) {
                              refreshing = true;

                              showDialog(
                                barrierDismissible: false,
                                context: context,
                                builder: (context) => Dialog(
                                  insetPadding: EdgeInsets.symmetric(
                                    horizontal:
                                        MediaQuery.of(context).size.width * 0.4,
                                  ),
                                  child: SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * 0.2,
                                    height:
                                        MediaQuery.of(context).size.width * 0.2,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      padding: EdgeInsets.all(
                                        MediaQuery.of(context).size.width *
                                            0.05,
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                  ),
                                ),
                              );

                              DreamUpAlgorithmManager.filtering = true;

                              vibeList.clear();
                              oldVibes.clear();

                              LoadedImages.clear();
                              BlurImages.clear();

                              backwardCount = 0;

                              setState(() {});

                              DefaultCacheManager()
                                  .emptyCache()
                                  .then((value) async {
                                currentIndex = 0;
                                maxIndex = currentIndex;

                                await instantiateAlgorithmQueries(
                                  filterType,
                                  context,
                                ).then((value) {
                                  if (!offline) {
                                    Navigator.pop(context);

                                    applyFilter = false;

                                    setState(() {});
                                  }

                                  refreshing = false;
                                });
                              });
                            }
                          },
                          resetVibes: () {
                            if (!refreshing) {
                              refreshing = true;

                              filterType = '';

                              showDialog(
                                barrierDismissible: false,
                                context: context,
                                builder: (context) => Dialog(
                                  insetPadding: EdgeInsets.symmetric(
                                    horizontal:
                                        MediaQuery.of(context).size.width * 0.4,
                                  ),
                                  child: SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * 0.2,
                                    height:
                                        MediaQuery.of(context).size.width * 0.2,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      padding: EdgeInsets.all(
                                        MediaQuery.of(context).size.width *
                                            0.05,
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                  ),
                                ),
                              );

                              vibeList.clear();
                              oldVibes.clear();

                              backwardCount = 0;

                              LoadedImages.clear();
                              BlurImages.clear();
                              DreamUpAlgorithmManager.filtering = false;

                              setState(() {});

                              DefaultCacheManager()
                                  .emptyCache()
                                  .then((value) async {
                                currentIndex = 0;
                                maxIndex = currentIndex;

                                await instantiateAlgorithmQueries(
                                  '',
                                  context,
                                ).then((value) {
                                  isNewVibe = true;

                                  Navigator.pop(context);

                                  applyFilter = false;

                                  refreshing = false;

                                  setState(() {});
                                });
                              });
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
          Positioned.fill(
            child: NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                setState(() {
                  currentSheetHeight = notification.extent;
                  connectInitSize = notification.extent;
                });

                if (notification.extent == 0 && connectInitSize != 0) {
                  connectInitSize = 0;
                  currentSheetHeight = 0;

                  provider.showHomeBar();
                }

                if (notification.extent <= 0.1) {
                  provider.showHomeBar();
                }

                if (notification.extent <= 0.02) {
                  FocusManager.instance.primaryFocus?.unfocus();
                }

                return true;
              },
              child: DraggableScrollableSheet(
                maxChildSize: 0.8,
                minChildSize: 0,
                initialChildSize: connectInitSize,
                controller: connectDragController,
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
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).size.width * 0.1,
                      left: MediaQuery.of(context).size.width * 0.05,
                      right: MediaQuery.of(context).size.width * 0.05,
                    ),
                    height: MediaQuery.of(context).size.height * 0.8,
                    child: vibeList.isNotEmpty &&
                            vibeList[currentIndex]['creator'] != currentUser
                        ? Column(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: EdgeInsets.zero,
                                  controller: scrollController,
                                  physics: const BouncingScrollPhysics(),
                                  child: SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                            0.8 -
                                        MediaQuery.of(context).size.width * 0.1,
                                    child: Column(
                                      children: [
                                        Text(
                                          'Hier kannst du den Ersteller von \n"${vibeList[currentIndex]['title']}"\nkontaktieren.',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.05,
                                        ),
                                        Center(
                                          child: SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.3,
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.3,
                                            child: ClipOval(
                                              child: Image(
                                                image: vibeList.isNotEmpty &&
                                                        LoadedImages.isNotEmpty
                                                    ? LoadedImages[
                                                        vibeList[currentIndex]
                                                            ['id']]!
                                                    : Image.asset(
                                                            'assets/images/ucImages/ostseeQuadrat.jpg')
                                                        .image,
                                                fit: BoxFit.fill,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.05,
                                        ),
                                        vibeList[currentIndex]
                                                        ['keyQuestions'] !=
                                                    null &&
                                                vibeList[currentIndex]
                                                        ['keyQuestions']
                                                    .isNotEmpty
                                            ? SingleChildScrollView(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'Der Ersteller möchte wissen:',
                                                      textAlign:
                                                          TextAlign.start,
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        color: Colors.black54,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Column(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: (vibeList[
                                                                      currentIndex]
                                                                  [
                                                                  'keyQuestions']
                                                              as List<dynamic>)
                                                          .map<Widget>(
                                                            (question) =>
                                                                Container(
                                                              margin:
                                                                  const EdgeInsets
                                                                      .only(
                                                                top: 10,
                                                              ),
                                                              child: Text(
                                                                question,
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 16,
                                                                  color: Colors
                                                                      .black54,
                                                                ),
                                                              ),
                                                            ),
                                                          )
                                                          .toList(),
                                                    ),
                                                    CurrentUser.icebreakers
                                                            .containsKey(vibeList[
                                                                    currentIndex]
                                                                ['id'])
                                                        ? Text(
                                                            CurrentUser
                                                                    .icebreakers[
                                                                vibeList[
                                                                        currentIndex]
                                                                    ['id']],
                                                            textAlign:
                                                                TextAlign.start,
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 18,
                                                              color: Colors
                                                                  .black54,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          )
                                                        : Container(),
                                                  ],
                                                ),
                                              )
                                            : CurrentUser.icebreakers
                                                    .containsKey(
                                                        vibeList[currentIndex]
                                                            ['id'])
                                                ? Text(
                                                    CurrentUser.icebreakers[
                                                        vibeList[currentIndex]
                                                            ['id']],
                                                    textAlign: TextAlign.start,
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      color: Colors.black54,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  )
                                                : const Text(
                                                    'Schreibe dem Ersteller eine kurze Nachricht.',
                                                    textAlign: TextAlign.start,
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      color: Colors.black54,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                        Expanded(
                                          child: Container(),
                                        ),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(7),
                                                  color: Colors.black
                                                      .withOpacity(0.1),
                                                ),
                                                padding: EdgeInsets.symmetric(
                                                  horizontal:
                                                      MediaQuery.of(context)
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
                                                        enabled: !CurrentUser
                                                            .icebreakers
                                                            .containsKey(vibeList[
                                                                    currentIndex]
                                                                ['id']),
                                                        controller:
                                                            contactController,
                                                        textCapitalization:
                                                            TextCapitalization
                                                                .sentences,
                                                        onChanged: (text) {
                                                          setState(() {});
                                                        },
                                                        decoration:
                                                            InputDecoration(
                                                          border:
                                                              InputBorder.none,
                                                          hintText: CurrentUser
                                                                  .icebreakers
                                                                  .containsKey(
                                                                      vibeList[
                                                                              currentIndex]
                                                                          [
                                                                          'id'])
                                                              ? 'Du hast diesen Ersteller bereits kontaktiert'
                                                              : 'Deine Nachricht',
                                                        ),
                                                      ),
                                                    ),
                                                    GestureDetector(
                                                      onTap: () async {
                                                        contactController.text =
                                                            '';

                                                        setState(() {});
                                                      },
                                                      child: CurrentUser
                                                              .icebreakers
                                                              .containsKey(vibeList[
                                                                      currentIndex]
                                                                  ['id'])
                                                          ? Container()
                                                          : AnimatedContainer(
                                                              duration:
                                                                  Duration(
                                                                milliseconds:
                                                                    animationSpeed,
                                                              ),
                                                              color: Colors
                                                                  .transparent,
                                                              width: 20,
                                                              margin: EdgeInsets
                                                                  .only(
                                                                left: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.01,
                                                              ),
                                                              child:
                                                                  AnimatedOpacity(
                                                                duration:
                                                                    Duration(
                                                                  milliseconds:
                                                                      (animationSpeed *
                                                                              0.5)
                                                                          .toInt(),
                                                                ),
                                                                opacity: 1,
                                                                child:
                                                                    const Icon(
                                                                  Icons
                                                                      .cancel_outlined,
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
                                              onTap: () async {
                                                print('clicking');

                                                await contactCreator(
                                                        contactController.text)
                                                    .then((value) {
                                                  contactController.text = '';

                                                  connectDragController
                                                      .animateTo(
                                                    0,
                                                    duration: const Duration(
                                                        milliseconds: 250),
                                                    curve: Curves.fastOutSlowIn,
                                                  );
                                                });
                                              },
                                              child: AnimatedContainer(
                                                duration: Duration(
                                                  milliseconds: animationSpeed,
                                                ),
                                                height: CurrentUser.icebreakers
                                                        .containsKey(vibeList[
                                                            currentIndex]['id'])
                                                    ? 0
                                                    : 50,
                                                width: CurrentUser.icebreakers
                                                        .containsKey(vibeList[
                                                            currentIndex]['id'])
                                                    ? 0
                                                    : 50,
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
                                                      milliseconds:
                                                          animationSpeed,
                                                    ),
                                                    opacity: CurrentUser
                                                            .icebreakers
                                                            .containsKey(vibeList[
                                                                    currentIndex]
                                                                ['id'])
                                                        ? 0
                                                        : 1,
                                                    child: const Icon(
                                                      Icons.send,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          height: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.02 +
                                              MediaQuery.of(context)
                                                  .padding
                                                  .bottom,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView(
                            controller: scrollController,
                          ),
                  );
                },
              ),
            ),
          ),
          // Positioned(
          //   left: 0,
          //   right: 0,
          //   top: MediaQuery.of(context).size.height * 0.125,
          //   child: Visibility(
          //     visible: loading,
          //     child: GestureDetector(
          //       onTap: () {
          //         loading = false;
          //
          //         setState(() {});
          //       },
          //       child: Container(
          //         height: MediaQuery.of(context).size.height * 0.75,
          //         color: Colors.white,
          //         padding: const EdgeInsets.all(
          //           10,
          //         ),
          //         child: Column(
          //           crossAxisAlignment: CrossAxisAlignment.center,
          //           children: [
          //             Text(
          //               '${vibeList.length}/4 DreamUps loaded',
          //               style: const TextStyle(
          //                 fontSize: 18,
          //                 fontWeight: FontWeight.bold,
          //               ),
          //             ),
          //             const SizedBox(
          //               height: 10,
          //             ),
          //             Column(
          //               mainAxisSize: MainAxisSize.min,
          //               crossAxisAlignment: CrossAxisAlignment.start,
          //               children: userInfoSteps
          //                   .map<Widget>(
          //                     (step) => Text(step),
          //                   )
          //                   .toList(),
          //             ),
          //             Row(
          //               children: [
          //                 Checkbox(
          //                   value: gotUserData,
          //                   onChanged: (value) {},
          //                 ),
          //                 const Text(
          //                   'Got User Data',
          //                 ),
          //               ],
          //             ),
          //             Row(
          //               children: [
          //                 Checkbox(
          //                   value: gotSeenVibes,
          //                   onChanged: (value) {},
          //                 ),
          //                 const Text(
          //                   'Got Seen DreamUps',
          //                 ),
          //               ],
          //             ),
          //             Column(
          //               mainAxisSize: MainAxisSize.min,
          //               crossAxisAlignment: CrossAxisAlignment.start,
          //               children: loadingSteps
          //                   .map<Widget>(
          //                     (step) => Text(step),
          //                   )
          //                   .toList(),
          //             ),
          //           ],
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}

class MainScreenBackground extends StatefulWidget {
  const MainScreenBackground({
    Key? key,
  }) : super(key: key);

  @override
  State<MainScreenBackground> createState() => _MainScreenBackgroundState();
}

class _MainScreenBackgroundState extends State<MainScreenBackground> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.width,
                width: MediaQuery.of(context).size.width,
                child: Image(
                  image: vibeList.isNotEmpty && BlurImages.isNotEmpty
                      ? BlurImages[vibeList[currentIndex]['id']]!
                      : Image.asset('assets/images/ucImages/ostseeQuadrat.jpg')
                          .image,
                  fit: BoxFit.fill,
                  height: MediaQuery.of(context).size.width,
                  width: MediaQuery.of(context).size.width,
                  gaplessPlayback: true,
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 3,
                child: Transform.rotate(
                  angle: 180 * pi / 180,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(pi),
                    child: Image(
                      image: vibeList.isNotEmpty && BlurImages.isNotEmpty
                          ? BlurImages[vibeList[currentIndex]['id']]!
                          : Image.asset(
                              'assets/images/ucImages/ostseeQuadrat.jpg',
                            ).image,
                      fit: BoxFit.fill,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.width * 0.7,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height -
                MediaQuery.of(context).size.width * 0.7,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
                stops: const [
                  0,
                  1,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          child: SizedBox(
            height: MediaQuery.of(context).size.width,
            width: MediaQuery.of(context).size.width,
            child: Stack(
              children: [
                ShaderMask(
                  shaderCallback: (rect) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black,
                        Colors.transparent,
                      ],
                      stops: [
                        0.4,
                        1,
                      ],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstIn,
                  child: Image(
                    image: vibeList.isNotEmpty && LoadedImages.isNotEmpty
                        ? LoadedImages[vibeList[currentIndex]['id']]!
                        : Image.asset(
                                'assets/images/ucImages/ostseeQuadrat.jpg')
                            .image,
                    fit: BoxFit.fill,
                    height: MediaQuery.of(context).size.width,
                    width: MediaQuery.of(context).size.width,
                    gaplessPlayback: true,
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black54,
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [
                        0,
                        0.5,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class DreamUpFilterWidget extends StatefulWidget {
  final void Function(String filterType) filterVibes;
  final void Function() resetVibes;

  const DreamUpFilterWidget({
    Key? key,
    required this.filterVibes,
    required this.resetVibes,
  }) : super(key: key);

  @override
  State<DreamUpFilterWidget> createState() => _DreamUpFilterWidgetState();
}

class _DreamUpFilterWidgetState extends State<DreamUpFilterWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            spreadRadius: 1,
            offset: Offset(-1, 1),
            color: Colors.black54,
          ),
        ],
      ),
      width: MediaQuery.of(context).size.width * 0.7,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              filterType != 'gender' ? filterType = 'gender' : filterType = '';

              setState(() {});
            },
            child: Container(
              color: Colors.transparent,
              child: Row(
                children: [
                  Radio(
                    value: 'gender',
                    toggleable: true,
                    groupValue: filterType,
                    onChanged: (String? value) {
                      filterType != 'gender'
                          ? filterType = value!
                          : filterType = '';

                      setState(() {});
                    },
                  ),
                  Text(
                    'Dein Geschlecht',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: 'gender' == filterType
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: DreamUpAlgorithmManager.Types.map<Widget>((type) {
              return GestureDetector(
                onTap: () {
                  filterType != type ? filterType = type : filterType = '';

                  setState(() {});
                },
                child: Container(
                  color: Colors.transparent,
                  child: Row(
                    children: [
                      Radio(
                        value: type,
                        toggleable: true,
                        groupValue: filterType,
                        onChanged: (String? value) {
                          filterType != type
                              ? filterType = value!
                              : filterType = '';

                          setState(() {});
                        },
                      ),
                      Text(
                        type,
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: type == filterType
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          Visibility(
            visible: CurrentUser.hasPremium!,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  DreamUpAlgorithmManager.PremiumTypes.map<Widget>((type) {
                return GestureDetector(
                  onTap: () {
                    filterType != type ? filterType = type : filterType = '';

                    setState(() {});
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: Row(
                      children: [
                        Radio(
                          value: type,
                          toggleable: true,
                          groupValue: filterType,
                          onChanged: (String? value) {
                            filterType != type
                                ? filterType = value!
                                : filterType = '';

                            setState(() {});
                          },
                        ),
                        Text(
                          type,
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: type == filterType
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Center(
            child: GestureDetector(
              onTap: () async {
                filterType != ''
                    ? widget.filterVibes(filterType)
                    : widget.resetVibes();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(250),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                margin: const EdgeInsets.only(
                  bottom: 15,
                  top: 15,
                ),
                child: const Text(
                  'Filtern',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DreamUpScrollItem extends StatefulWidget {
  final void Function() showPanel;
  final void Function(bool expand) expandDescription;
  final DraggableScrollableController connectionDragController;
  final double animationHeight;
  final Map<String, dynamic> vibeData;
  final CarouselController controller;

  const DreamUpScrollItem({
    Key? key,
    required this.showPanel,
    required this.expandDescription,
    required this.connectionDragController,
    required this.animationHeight,
    required this.vibeData,
    required this.controller,
  }) : super(key: key);

  @override
  State<DreamUpScrollItem> createState() => _DreamUpScrollItemState();
}

class _DreamUpScrollItemState extends State<DreamUpScrollItem>
    with SingleTickerProviderStateMixin {
  final currentUser = FirebaseAuth.instance.currentUser?.uid;

  int counter = 0;

  bool hasKeyQuestions = true;

  final scrollController = ScrollController();

  late final Map<String, dynamic> vibeData;

  Future getCreatorInfoContent() async {
    widget.showPanel();

    var creator = vibeList[currentIndex]['creator'];

    var userDoc =
        await FirebaseFirestore.instance.collection('users').doc(creator).get();

    creatorInfo = userDoc.data() ?? {};

    print('got creator info');

    var userWishes = await FirebaseFirestore.instance
        .collection('vibes')
        .where('creator', isEqualTo: creator)
        .orderBy('createdOn', descending: true)
        .get();

    for (var doc in userWishes.docs) {
      var data = doc.data();

      var existing = creatorWishes
          .firstWhereOrNull((element) => element['id'] == data['id']);

      if (existing == null) {
        creatorWishes.add(data);
      }
    }

    print('got creator wishes');

    widget.showPanel();
  }

  GlobalKey titleKey = GlobalKey();
  GlobalKey buttonKey = GlobalKey();
  GlobalKey textKey = GlobalKey();
  GlobalKey readMoreKey = GlobalKey();

  double? titleHeight;
  double? buttonHeight;
  double? textHeight;
  double? originalScrollerHeight;
  double? expandedScrollerHeight;
  double? readMoreHeight;

  bool needsScroller = true;

  bool descriptionExpanded = false;

  String getGender(String? originalGender) {
    String gender = '';

    if (originalGender == 'male') {
      gender = 'männlich';
    } else if (originalGender == 'female') {
      gender = 'weiblich';
    } else if (originalGender == 'diverse') {
      gender = 'divers';
    } else if (originalGender == null) {
      gender = 'unbekannt';
    }

    return gender;
  }

  String getAge(DateTime birthday) {
    String age = '';

    var years = AgeCalculator.age(
      birthday,
    ).years;

    int myAge = 0;
    if (CurrentUser.birthday != null) {
      myAge = AgeCalculator.age(
        CurrentUser.birthday!,
      ).years;
    }

    if (myAge == 0) {
      age = 'unbekannt';
    } else if (years > myAge + ageRange) {
      age = 'älter';
    } else if (years < myAge - ageRange) {
      age = 'jünger';
    } else {
      age = 'dein Alter';
    }

    return age;
  }

  @override
  void initState() {
    super.initState();

    vibeData = widget.vibeData;

    if (widget.vibeData['keyQuestions'] != null &&
        widget.vibeData['keyQuestions'].isNotEmpty) {
      hasKeyQuestions = true;
    } else {
      hasKeyQuestions = false;
    }

    scrollController.addListener(() {
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var titleContext = titleKey.currentContext;
      var buttonContext = buttonKey.currentContext;
      var textContext = textKey.currentContext;
      var readMoreContext = readMoreKey.currentContext;

      if (titleContext != null) {
        titleHeight = titleContext.size!.height;
      }

      if (buttonContext != null) {
        buttonHeight = buttonContext.size!.height;
      }

      if (textContext != null) {
        textHeight = textContext.size!.height;
      }

      if (readMoreContext != null) {
        readMoreHeight = readMoreContext.size!.height;
      }

      originalScrollerHeight = MediaQuery.of(context).size.height -
          MediaQuery.of(context).size.width -
          titleHeight! -
          buttonHeight! -
          readMoreHeight! -
          homeBarHeight;

      var spacing = MediaQuery.of(context).size.width -
          MediaQuery.of(context).padding.top -
          50;

      expandedScrollerHeight = originalScrollerHeight! + spacing;

      if (textHeight != null && textHeight! <= originalScrollerHeight!) {
        needsScroller = false;

        originalScrollerHeight = originalScrollerHeight! + readMoreHeight!;
      }

      if (vibeData['audioLink'] != null) {
        needsScroller = false;

        originalScrollerHeight = originalScrollerHeight! + readMoreHeight!;
      }

      setState(() {});
    });
  }

  @override
  void dispose() {
    scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var provider = Provider.of<HomeBarControlProvider>(context, listen: true);

    return SizedBox.expand(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            key: titleKey,
            duration: Duration.zero,
            margin: EdgeInsets.only(
              left: MediaQuery.of(context).size.width * 0.05,
            ),
            width: MediaQuery.of(context).size.width * 0.9,
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vibeData['title'],
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    shadows: const [
                      Shadow(
                        color: Colors.black87,
                        blurRadius: 10,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                Text(
                  vibeData['creator'] == currentUser
                      ? 'dein DreamUp'
                      : '${getGender(vibeData['creatorGender'])}, ${getAge((vibeData['creatorBirthday'].toDate()))}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    shadows: [
                      Shadow(
                        color: Colors.black87,
                        blurRadius: 10,
                        offset: Offset(1, 1),
                      ),
                    ],
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: Colors.transparent,
            height: titleHeight != null && !descriptionExpanded
                ? (MediaQuery.of(context).size.width -
                        (MediaQuery.of(context).size.height * 0.2 -
                            titleHeight!) +
                        15) *
                    widget.animationHeight /
                    0.8
                : 0,
          ),
          Container(
            key: buttonKey,
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.1,
              vertical: MediaQuery.of(context).size.width * 0.05,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    if (vibeList[currentIndex]['creator'] != currentUser) {
                      widget.connectionDragController
                          .animateTo(
                            0.8,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.fastOutSlowIn,
                          )
                          .then((value) => provider.hideHomeBar());
                    }
                  },
                  child: SizedBox(
                    height: 25,
                    width: 25,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 1,
                          bottom: 4,
                          child: Transform.rotate(
                            angle: -24 * pi / 180,
                            child: DecoratedIcon(
                              Icons.send_rounded,
                              color: Colors.white.withOpacity(0.8),
                              shadows: const [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 5,
                                  offset: Offset(
                                    1,
                                    1,
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
              ],
            ),
          ),
          AnimatedContainer(
            duration: Duration(
              milliseconds: animationSpeed,
            ),
            padding: EdgeInsets.only(
              left: MediaQuery.of(context).size.width * 0.1,
              right: MediaQuery.of(context).size.width * 0.1,
            ),
            color: Colors.transparent,
            clipBehavior: Clip.antiAlias,
            height: !descriptionExpanded
                ? originalScrollerHeight ??
                    MediaQuery.of(context).size.height * 0.25
                : min(textHeight!, expandedScrollerHeight!),
            child: vibeData['content'] != ''
                ? GestureDetector(
                    onTap: () {
                      if (needsScroller) {
                        if (descriptionExpanded) {
                          descriptionExpanded = false;

                          widget.expandDescription(false);
                        } else {
                          descriptionExpanded = true;

                          widget.expandDescription(true);
                        }

                        counter++;

                        setState(() {});
                      }
                    },
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      key: Key(
                        counter.toString(),
                      ),
                      physics: descriptionExpanded
                          ? const BouncingScrollPhysics()
                          : const NeverScrollableScrollPhysics(),
                      children: [
                        Column(
                          key: textKey,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              vibeData['content'],
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                fontSize: smallTextSize,
                                color: Colors.white,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black87,
                                    blurRadius: 5,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                            ),
                            vibeData['hashtags'] != null
                                ? Container(
                                    margin: EdgeInsets.only(
                                      top: MediaQuery.of(context).size.width *
                                          0.05,
                                    ),
                                    alignment: Alignment.centerLeft,
                                    child: Wrap(
                                      spacing:
                                          MediaQuery.of(context).size.width *
                                              0.02,
                                      runSpacing:
                                          MediaQuery.of(context).size.width *
                                              0.02,
                                      children: (vibeData['hashtags']
                                              as List<dynamic>)
                                          .map<Widget>(
                                            (hashtag) => Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(200),
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                horizontal:
                                                    MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        0.02,
                                                vertical: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.01,
                                              ),
                                              child: Text(
                                                hashtag,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.black
                                                      .withOpacity(0.8),
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  )
                                : Container(),
                          ],
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: WishAudioPlayer(
                      isFile: false,
                      source: vibeData['audioLink'],
                    ),
                  ),
          ),
          Visibility(
            visible: needsScroller,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  if (descriptionExpanded) {
                    descriptionExpanded = false;

                    widget.expandDescription(false);
                  } else {
                    descriptionExpanded = true;

                    widget.expandDescription(true);
                  }

                  counter++;

                  setState(() {});
                },
                child: Container(
                  key: readMoreKey,
                  color: Colors.transparent,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.width * 0.02,
                    bottom: MediaQuery.of(context).size.width * 0.05,
                  ),
                  child: Text(
                    descriptionExpanded ? 'read less' : 'read more',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      shadows: const [
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
            ),
          ),
          SizedBox(
            height: homeBarHeight,
          ),
        ],
      ),
    );
  }
}
//endregion

//region Business Logic
class DreamUpAlgorithmManager {
  static bool filtering = false;

  static List<String> Types = [
    'Aktion',
    'Freundschaft',
  ];

  static List<String> PremiumTypes = [
    'Date',
    'Beziehung',
  ];

  static List<Query> QueryList = [];
}

class CustomScrollPhysics extends ScrollPhysics {
  const CustomScrollPhysics({ScrollPhysics? parent}) : super(parent: parent);

  @override
  ScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return const CustomScrollPhysics();
  }

  @override
  double get minFlingVelocity => 0;

  @override
  double get minFlingDistance => 5;

  double frictionFactor(double overscrollFraction) =>
      0.52 * pow(1 - overscrollFraction, 2);

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    assert(offset != 0.0);
    assert(position.minScrollExtent <= position.maxScrollExtent);

    if (!position.outOfRange) {
      return offset;
    }

    final double overscrollPastStart =
        max(position.minScrollExtent - position.pixels, 0.0);
    final double overscrollPastEnd =
        max(position.pixels - position.maxScrollExtent, 0.0);
    final double overscrollPast = max(overscrollPastStart, overscrollPastEnd);
    final bool easing = (overscrollPastStart > 0.0 && offset < 0.0) ||
        (overscrollPastEnd > 0.0 && offset > 0.0);

    final double friction = easing
        ? frictionFactor(
            (overscrollPast - offset.abs()) / position.viewportDimension)
        : frictionFactor(overscrollPast / position.viewportDimension);
    final double direction = offset.sign;

    return direction * _applyFriction(overscrollPast, offset.abs(), friction);
  }

  static double _applyFriction(
      double extentOutside, double absDelta, double gamma) {
    assert(absDelta > 0);
    double total = 0.0;
    if (extentOutside > 0) {
      final double deltaToLimit = extentOutside / gamma;
      if (absDelta < deltaToLimit) {
        return absDelta * gamma;
      }
      total += extentOutside;
      absDelta -= deltaToLimit;
    }
    return total + absDelta;
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) => 0.0;

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    final Tolerance tolerance = this.tolerance;
    if (velocity.abs() >= tolerance.velocity || position.outOfRange) {
      return BouncingScrollSimulation(
        spring: spring,
        position: position.pixels,
        velocity: velocity,
        leadingExtent: position.minScrollExtent,
        trailingExtent: position.maxScrollExtent,
        tolerance: tolerance,
      );
    }
    return null;
  }

  @override
  double carriedMomentum(double existingVelocity) {
    return existingVelocity.sign *
        min(0.000816 * pow(existingVelocity.abs(), 1.967).toDouble(), 40000.0);
  }

  @override
  double get dragStartDistanceMotionThreshold => 3.5;
}
//endregion
