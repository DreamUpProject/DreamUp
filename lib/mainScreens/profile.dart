import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:decorated_icon/decorated_icon.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:friendivity/additionalPages/dreamUpDetail.dart';
import 'package:friendivity/additionalPages/premium.dart';
import 'package:friendivity/main.dart';
import 'package:friendivity/mainScreens/creation.dart';
import 'package:friendivity/mainScreens/thread.dart';

import '../additionalPages/personalAttributes.dart';
import '../additionalPages/profileInformation.dart';
import '../additionalPages/settings.dart';

//region Global Variables
var color = const Color(0xFF485868);
//endregion

//region UI Logic
class Profile extends StatefulWidget {
  const Profile({Key? key}) : super(key: key);

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final currentUser = FirebaseAuth.instance.currentUser?.uid;

  void showDeleteDialog(
      String id, String title, Map<String, dynamic> vibeData) {
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
              children: [
                Text(
                  'Achtung! Willst du wirklich \n"$title" \nlöschen?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.width * 0.05,
                ),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          if (vibeData['type'] == 'Date' ||
                              vibeData['type'] == 'Beziehung') {
                            var fabiId = '5HW31VMcRZdiMeYgJwbQqAiL5w82';
                            var jacobId = 'Wjrh9Zg3vPcrTOJrgTWtYgwzELC3';

                            var note = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(currentUser)
                                .collection('notifications')
                                .where('vibeId', isEqualTo: title)
                                .get();

                            for (var doc in note.docs) {
                              var id = doc.id;

                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(currentUser)
                                  .collection('notifications')
                                  .doc(id)
                                  .delete();
                            }

                            var jacobNote = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(jacobId)
                                .collection('notifications')
                                .where('vibeId', isEqualTo: id)
                                .get();

                            for (var doc in jacobNote.docs) {
                              var id = doc.id;

                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(jacobId)
                                  .collection('notifications')
                                  .doc(id)
                                  .delete();
                            }

                            var fabiNote = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(fabiId)
                                .collection('notifications')
                                .where('vibeId', isEqualTo: id)
                                .get();

                            for (var doc in fabiNote.docs) {
                              var id = doc.id;

                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(fabiId)
                                  .collection('notifications')
                                  .doc(id)
                                  .delete();
                            }

                            var likers = await FirebaseFirestore.instance
                                .collection('vibes')
                                .doc(id)
                                .collection('likers')
                                .get();

                            for (var liker in likers.docs) {
                              var notes = await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(liker.id)
                                  .collection('notifications')
                                  .where('vibeId', isEqualTo: id)
                                  .get();

                              for (var note in notes.docs) {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(liker.id)
                                    .collection('notifications')
                                    .doc(note.id)
                                    .delete();
                              }
                            }

                            var ownNotes = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(currentUser)
                                .collection('notifications')
                                .where('vibeId', isEqualTo: id)
                                .get();

                            for (var own in ownNotes.docs) {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(currentUser)
                                  .collection('notifications')
                                  .doc(own.id)
                                  .delete();
                            }

                            await FirebaseFirestore.instance
                                .collection('vibes')
                                .doc(id)
                                .delete();

                            Fluttertoast.showToast(
                              msg: '"$title" wurde erfolgreich gelöscht!',
                            );

                            Navigator.pop(context);
                          } else {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser?.uid)
                                .update(
                              {
                                'createdVibes': FieldValue.arrayRemove(
                                  [
                                    vibeData['id'],
                                  ],
                                ),
                              },
                            );

                            List<dynamic>? vibeHashtags = vibeData['hashtags'];

                            if (vibeHashtags != null) {
                              for (var hashtag in vibeHashtags) {
                                var databaseHashtag = await FirebaseFirestore
                                    .instance
                                    .collection('hashtags')
                                    .where('hashtag', isEqualTo: hashtag)
                                    .get();

                                for (var dbHashtag in databaseHashtag.docs) {
                                  var data = dbHashtag.data();

                                  if (data['useCount'] < 2) {
                                    await FirebaseFirestore.instance
                                        .collection('hashtags')
                                        .doc(dbHashtag.id)
                                        .delete();
                                  } else {
                                    await FirebaseFirestore.instance
                                        .collection('hashtags')
                                        .doc(dbHashtag.id)
                                        .update(
                                      {
                                        'useCount': FieldValue.increment(-1),
                                      },
                                    );
                                  }
                                }
                              }
                            }

                            var fabiId = '5HW31VMcRZdiMeYgJwbQqAiL5w82';
                            var jacobId = 'Wjrh9Zg3vPcrTOJrgTWtYgwzELC3';

                            var note = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(currentUser)
                                .collection('notifications')
                                .where('vibeId', isEqualTo: title)
                                .get();

                            for (var doc in note.docs) {
                              var id = doc.id;

                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(currentUser)
                                  .collection('notifications')
                                  .doc(id)
                                  .delete();
                            }

                            var jacobNote = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(jacobId)
                                .collection('notifications')
                                .where('vibeId', isEqualTo: id)
                                .get();

                            for (var doc in jacobNote.docs) {
                              var id = doc.id;

                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(jacobId)
                                  .collection('notifications')
                                  .doc(id)
                                  .delete();
                            }

                            var fabiNote = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(fabiId)
                                .collection('notifications')
                                .where('vibeId', isEqualTo: id)
                                .get();

                            for (var doc in fabiNote.docs) {
                              var id = doc.id;

                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(fabiId)
                                  .collection('notifications')
                                  .doc(id)
                                  .delete();
                            }

                            var likers = await FirebaseFirestore.instance
                                .collection('vibes')
                                .doc(id)
                                .collection('likers')
                                .get();

                            for (var liker in likers.docs) {
                              var notes = await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(liker.id)
                                  .collection('notifications')
                                  .where('vibeId', isEqualTo: id)
                                  .get();

                              for (var note in notes.docs) {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(liker.id)
                                    .collection('notifications')
                                    .doc(note.id)
                                    .delete();
                              }
                            }

                            var ownNotes = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(currentUser)
                                .collection('notifications')
                                .where('vibeId', isEqualTo: id)
                                .get();

                            for (var own in ownNotes.docs) {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(currentUser)
                                  .collection('notifications')
                                  .doc(own.id)
                                  .delete();
                            }

                            await FirebaseFirestore.instance
                                .collection('vibes')
                                .doc(id)
                                .delete();

                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(currentUser)
                                .update(
                              {
                                'createdVibes': FieldValue.arrayRemove(
                                  [id],
                                ),
                              },
                            );

                            CurrentUser().saveUserInformation();

                            var vibeInList = vibeList.firstWhereOrNull(
                                (element) => element['id'] == id);

                            if (vibeInList != null) {
                              var index = vibeList.indexOf(vibeInList);

                              if (index <= currentIndex) {
                                vibeList.remove(vibeInList);

                                if (currentIndex > 0) {
                                  currentIndex--;
                                }
                              }
                            }

                            if (vibeData['imageLink'] !=
                                'https://firebasestorage.googleapis.com/v0/b/activities-with-friends.appspot.com/o/placeholderImages%2FostseeQuadrat.jpg?alt=media&token=cece7d52-6d24-463f-9ac7-ea55ed35086a') {
                              var imageRef = FirebaseStorage.instance
                                  .ref('vibeMedia/images/$id');

                              await imageRef.delete();
                            }

                            if (vibeData['content'] == '') {
                              var audioRef = FirebaseStorage.instance
                                  .ref('vibeMedia/audios/$id');

                              await audioRef.delete();
                            }

                            Fluttertoast.showToast(
                              msg: '"$title" wurde erfolgreich gelöscht!',
                            );

                            Navigator.pop(context);
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(
                              MediaQuery.of(context).size.width * 0.01,
                            ),
                            border: Border.all(
                              color: Colors.redAccent,
                              width: 2,
                            ),
                          ),
                          padding: EdgeInsets.all(
                            MediaQuery.of(context).size.width * 0.02,
                          ),
                          child: const Center(
                            child: Text(
                              'Löschen',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.025,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.redAccent,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(
                              MediaQuery.of(context).size.width * 0.01,
                            ),
                          ),
                          padding: EdgeInsets.all(
                            MediaQuery.of(context).size.width * 0.02,
                          ),
                          child: const Center(
                            child: Text(
                              'Abbrechen',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                              ),
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
        );
      },
    );
  }

  bool showPopUp = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE2E2E2),
      body: GestureDetector(
        onTap: () {
          if (showPopUp) {
            showPopUp = false;

            setState(() {});
          }
        },
        child: SizedBox.expand(
          child: Stack(
            children: [
              Positioned.fill(
                child:
                    CurrentUser.imageLink != null && CurrentUser.imageLink != ''
                        ? const ProfileBackground()
                        : Container(),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width * 0.1,
                          ),
                          child: Text(
                            'Ich bin ${CurrentUser.name}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 32,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black87,
                                  blurRadius: 10,
                                  offset: Offset(
                                    1,
                                    1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        vertical: MediaQuery.of(context).size.width * 0.05,
                        horizontal: MediaQuery.of(context).size.width * 0.1,
                      ),
                      child: Center(
                        child: Text(
                          CurrentUser.bio ?? 'User Bio',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                            shadows: const [
                              Shadow(
                                color: Colors.black87,
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
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.width * 0.6,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('vibes')
                            .where('creator', isEqualTo: currentUser)
                            .orderBy('createdOn', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            var docs = snapshot.data!.docs;

                            return ListView(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(
                                horizontal:
                                    MediaQuery.of(context).size.width * 0.05,
                              ),
                              physics: const BouncingScrollPhysics(),
                              children: [
                                Row(
                                  children: docs.map<Widget>((doc) {
                                    var data =
                                        doc.data() as Map<String, dynamic>;

                                    var imageLink = data['imageLink'];
                                    var title = data['title'];

                                    return Center(
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            changePage(
                                              DreamUpDetailPage(
                                                dreamUpData: data,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.5,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.5,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          margin: EdgeInsets.symmetric(
                                            horizontal: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.05,
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            child: Stack(
                                              children: [
                                                FutureBuilder<File>(
                                                  future: CurrentUser()
                                                      .dreamUpImage(
                                                    data['id'],
                                                    imageLink,
                                                  ),
                                                  builder: (context, snapshot) {
                                                    if (snapshot.hasData) {
                                                      return Image.file(
                                                        snapshot.data!,
                                                        fit: BoxFit.fill,
                                                      );
                                                    } else {
                                                      return Container(
                                                        color: Colors.white
                                                            .withOpacity(0.5),
                                                      );
                                                    }
                                                  },
                                                ),
                                                Positioned(
                                                  bottom: 0,
                                                  left: 0,
                                                  right: 0,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            15),
                                                    decoration:
                                                        const BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          Colors.transparent,
                                                          Colors.black87,
                                                        ],
                                                        begin:
                                                            Alignment.topCenter,
                                                        end: Alignment
                                                            .bottomCenter,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      title,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 18,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                Center(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        changePage(
                                          const CreationOpeningScreen(
                                            fromProfile: true,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      height:
                                          MediaQuery.of(context).size.width *
                                              0.5,
                                      width: MediaQuery.of(context).size.width *
                                          0.5,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          20,
                                        ),
                                      ),
                                      margin: EdgeInsets.symmetric(
                                        horizontal:
                                            MediaQuery.of(context).size.width *
                                                0.05,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          20,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.all(15),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.4),
                                          ),
                                          child: Center(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.add_rounded,
                                                  size: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.25,
                                                  color: Colors.black54,
                                                ),
                                                const Text(
                                                  'DreamUp erstellen',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Colors.black54,
                                                    fontSize: 22,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }

                          return Container();
                        },
                      ),
                    ),
                    SizedBox(
                      height: homeBarHeight +
                          MediaQuery.of(context).size.width * 0.05,
                    ),
                  ],
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top,
                left: 0,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      changePage(
                        const PersonalQuestionPage(),
                      ),
                    );
                  },
                  child: const SizedBox(
                    height: 50,
                    width: 50,
                    child: Center(
                      child: DecoratedIcon(
                        Icons.question_mark_rounded,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black87,
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
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    showPopUp ? showPopUp = false : showPopUp = true;

                    setState(() {});
                  },
                  child: const SizedBox(
                    height: 50,
                    width: 50,
                    child: Center(
                      child: DecoratedIcon(
                        Icons.more_vert_rounded,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black87,
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
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 50,
                right: 5,
                child: Visibility(
                  visible: showPopUp,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 10,
                          spreadRadius: 1,
                          offset: Offset(
                            2,
                            2,
                          ),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            var refresh = await Navigator.push(
                              context,
                              changePage(
                                const ProfileEditPage(),
                              ),
                            );

                            if (refresh) {
                              showPopUp = false;

                              setState(() {});
                            }
                          },
                          child: Container(
                            color: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 5,
                            ),
                            child: const Text(
                              'Profil bearbeiten',
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            var refresh = await Navigator.push(
                              context,
                              changePage(
                                const SettingsPage(),
                              ),
                            );

                            if (refresh) {
                              showPopUp = false;

                              setState(() {});
                            }
                          },
                          child: Container(
                            color: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 5,
                            ),
                            child: const Text(
                              'Einstellungen',
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            var refresh = await Navigator.push(
                              context,
                              changePage(
                                const DatePreferenceScreen(),
                              ),
                            );

                            if (refresh) {
                              showPopUp = false;

                              setState(() {});
                            }
                          },
                          child: Container(
                            color: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 5,
                            ),
                            child: const Text(
                              'Premium',
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
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

class ProfileBackground extends StatefulWidget {
  const ProfileBackground({
    Key? key,
  }) : super(key: key);

  @override
  State<ProfileBackground> createState() => _ProfileBackgroundState();
}

class _ProfileBackgroundState extends State<ProfileBackground> {
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
                child: Image.file(
                  CurrentUser.blurredImage!,
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
                    child: Image.file(
                      CurrentUser.blurredImage!,
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
                  child: Image.file(
                    CurrentUser.imageFile!,
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
//endregion
