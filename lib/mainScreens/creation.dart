import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:decorated_icon/decorated_icon.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:friendivity/additionalPages/creationSteps.dart';
import 'package:friendivity/mainScreens/premium.dart';
import 'package:video_player/video_player.dart';

import '../main.dart';

int index = 0;

List<Widget> VideoPlayers = const [
  FriendshipVideoPlayer(),
  HobbyVideoPlayer(),
  DateVideoPlayer(),
  DateVideoPlayer(),
];

class CreationOpeningScreen extends StatefulWidget {
  final bool fromProfile;

  const CreationOpeningScreen({
    Key? key,
    required this.fromProfile,
  }) : super(key: key);

  @override
  State<CreationOpeningScreen> createState() => _CreationOpeningScreenState();
}

class _CreationOpeningScreenState extends State<CreationOpeningScreen> {
  String category = '';

  bool clickedPremium = false;

  final PageController pageController = PageController(
    initialPage: 0,
    viewportFraction: 0.8,
  );

  @override
  void dispose() {
    index = 0;

    pageController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            CreationBackground(
              index: index,
            ),
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.4 +
                  MediaQuery.of(context).padding.bottom +
                  MediaQuery.of(context).size.width * 0.2 +
                  (MediaQuery.of(context).size.width * 2) / 15 +
                  spacing,
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Column(
                  children: [
                    const Text(
                      'Dream Up',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black87,
                            offset: Offset(1, 1),
                            blurRadius: 5,
                          )
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Container(
                      margin: EdgeInsets.only(
                        top: MediaQuery.of(context).size.width * 0.08,
                      ),
                      height: 1,
                      color: Colors.white,
                      width: MediaQuery.of(context).size.width * 0.8,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: homeBarHeight +
                  spacing +
                  MediaQuery.of(context).size.width * 0.1,
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                width: MediaQuery.of(context).size.width,
                child: PageView(
                  scrollDirection: Axis.horizontal,
                  onPageChanged: (page) {
                    index = page;

                    setState(() {});
                  },
                  physics: const BouncingScrollPhysics(),
                  controller: pageController,
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          MediaQuery.of(context).size.width * 0.05,
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: 20,
                            sigmaY: 20,
                          ),
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.7,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.2),
                                  Colors.white.withOpacity(0.4),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(
                                MediaQuery.of(context).size.width * 0.05,
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.8),
                                width: 2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  spreadRadius: 1,
                                  blurRadius: 10,
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(
                              MediaQuery.of(context).size.width * 0.075,
                            ),
                            child: Column(
                              children: [
                                const AutoSizeText(
                                  'Freundschaft',
                                  maxLines: 1,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Container(
                                  color: Colors.white,
                                  height: 2,
                                  margin: EdgeInsets.only(
                                    top: MediaQuery.of(context).size.width *
                                        0.075,
                                    bottom: MediaQuery.of(context).size.width *
                                        0.05,
                                  ),
                                ),
                                Expanded(
                                  child: Container(),
                                ),
                                const Text(
                                  'Wünsch dir genau die Freundschaft, die du in deinem Leben brauchst. Hier findest du sie.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.width * 0.05,
                                ),
                                Expanded(
                                  child: Container(),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    category = 'Freundschaft';

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CreationStepPage(
                                          vibeType: category,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal:
                                          MediaQuery.of(context).size.width *
                                              0.05,
                                      vertical:
                                          MediaQuery.of(context).size.width *
                                              0.03,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(250),
                                    ),
                                    child: const Text(
                                      'DreamUp erstellen',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          MediaQuery.of(context).size.width * 0.05,
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: 20,
                            sigmaY: 20,
                          ),
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.7,
                            decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.2),
                                    Colors.white.withOpacity(0.4),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(
                                  MediaQuery.of(context).size.width * 0.05,
                                ),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.8),
                                  width: 2,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    spreadRadius: 1,
                                    blurRadius: 10,
                                    offset: Offset(1, 1),
                                  ),
                                ]),
                            padding: EdgeInsets.all(
                              MediaQuery.of(context).size.width * 0.075,
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Aktion',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Container(
                                  color: Colors.white,
                                  height: 2,
                                  margin: EdgeInsets.only(
                                    top: MediaQuery.of(context).size.width *
                                        0.075,
                                    bottom: MediaQuery.of(context).size.width *
                                        0.05,
                                  ),
                                ),
                                Expanded(
                                  child: Container(),
                                ),
                                const Text(
                                  'Wünsch dir genau die Aktion, die du in deinem Leben brauchst. Hier findest du sie.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.width * 0.05,
                                ),
                                Expanded(
                                  child: Container(),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    category = 'Aktion';

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CreationStepPage(
                                          vibeType: category,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal:
                                          MediaQuery.of(context).size.width *
                                              0.05,
                                      vertical:
                                          MediaQuery.of(context).size.width *
                                              0.03,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(250),
                                    ),
                                    child: const Text(
                                      'DreamUp erstellen',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          MediaQuery.of(context).size.width * 0.05,
                        ),
                        child: Stack(
                          children: [
                            BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: 20,
                                sigmaY: 20,
                              ),
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.7,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.2),
                                      Colors.white.withOpacity(0.4),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    MediaQuery.of(context).size.width * 0.05,
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.8),
                                    width: 2,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      spreadRadius: 1,
                                      blurRadius: 10,
                                      offset: Offset(1, 1),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.all(
                                  MediaQuery.of(context).size.width * 0.075,
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Beziehung',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Container(
                                      color: Colors.white,
                                      height: 2,
                                      margin: EdgeInsets.only(
                                        top: MediaQuery.of(context).size.width *
                                            0.075,
                                        bottom:
                                            MediaQuery.of(context).size.width *
                                                0.05,
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(),
                                    ),
                                    const Text(
                                      'Wünsch dir genau die Beziehung, die du in deinem Leben brauchst. Hier findest du sie.',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.width *
                                              0.05,
                                    ),
                                    Expanded(
                                      child: Container(),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        category = 'Beziehung';

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                CreationStepPage(
                                              vibeType: category,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.05,
                                          vertical: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.03,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(250),
                                        ),
                                        child: const Text(
                                          'DreamUp erstellen',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Visibility(
                                visible: !CurrentUser.hasPremium!,
                                child: GestureDetector(
                                  onTap: () {
                                    clickedPremium = true;

                                    setState(() {});
                                  },
                                  child: Container(
                                    color: Colors.black.withOpacity(0.7),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.lock_outline_rounded,
                                            color: Colors.white,
                                            size: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.3,
                                          ),
                                          const Text(
                                            'Premium',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          MediaQuery.of(context).size.width * 0.05,
                        ),
                        child: Stack(
                          children: [
                            BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: 20,
                                sigmaY: 20,
                              ),
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.7,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.2),
                                      Colors.white.withOpacity(0.4),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    MediaQuery.of(context).size.width * 0.05,
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.8),
                                    width: 2,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      spreadRadius: 1,
                                      blurRadius: 10,
                                      offset: Offset(1, 1),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.all(
                                  MediaQuery.of(context).size.width * 0.075,
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Date',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Container(
                                      color: Colors.white,
                                      height: 2,
                                      margin: EdgeInsets.only(
                                        top: MediaQuery.of(context).size.width *
                                            0.075,
                                        bottom:
                                            MediaQuery.of(context).size.width *
                                                0.05,
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(),
                                    ),
                                    const Text(
                                      'Wünsch dir genau das Date, das du in deinem Leben brauchst. Hier findest du es.',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.width *
                                              0.05,
                                    ),
                                    Expanded(
                                      child: Container(),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        category = 'Aktion';

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                CreationStepPage(
                                              vibeType: category,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.05,
                                          vertical: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.03,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(250),
                                        ),
                                        child: const Text(
                                          'DreamUp erstellen',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Visibility(
                                visible: !CurrentUser.hasPremium!,
                                child: GestureDetector(
                                  onTap: () {
                                    clickedPremium = true;

                                    setState(() {});
                                  },
                                  child: Container(
                                    color: Colors.black.withOpacity(0.7),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.lock_outline_rounded,
                                            color: Colors.white,
                                            size: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.3,
                                          ),
                                          const Text(
                                            'Premium',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
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
            Visibility(
              visible: clickedPremium,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.1,
                  ),
                  padding: EdgeInsets.all(
                    MediaQuery.of(context).size.width * 0.05,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Diese Art von Wishes kannst du nur mit einem Premiumupgrade erstellen.',
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.width * 0.05,
                      ),
                      GestureDetector(
                        onTap: () async {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .update({'hasPremium': true});

                          CurrentUser.hasPremium = true;

                          CurrentUser().saveUserInformation();

                          setState(() {});

                          var back = await Navigator.push(
                            context,
                            changePage(
                              const DatePreferenceScreen(),
                            ),
                          );

                          if (back) {
                            clickedPremium = false;

                            setState(() {});
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          color: Colors.blueAccent,
                          child: const Text(
                            'Premium abschließen',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.width * 0.025,
                      ),
                      GestureDetector(
                        onTap: () async {
                          clickedPremium = false;

                          setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          color: Colors.blueAccent.withOpacity(0.1),
                          child: const Text(
                            'Abbrechen',
                            style: TextStyle(
                              color: Colors.blueAccent,
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
            Positioned(
              left: 0,
              top: MediaQuery.of(context).padding.top,
              child: Visibility(
                visible: widget.fromProfile,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    color: Colors.transparent,
                    height: 50,
                    width: 50,
                    child: const Center(
                      child: DecoratedIcon(
                        Icons.arrow_back_ios_new_rounded,
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
            ),
          ],
        ),
      ),
    );
  }
}

class DateVideoPlayer extends StatefulWidget {
  const DateVideoPlayer({
    Key? key,
  }) : super(key: key);

  @override
  _DateVideoPlayerState createState() => _DateVideoPlayerState();
}

class _DateVideoPlayerState extends State<DateVideoPlayer> {
  late VideoPlayerController controller;

  @override
  void initState() {
    super.initState();

    controller = VideoPlayerController.asset(
      'assets/videos/DateVideo.mp4',
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
      ),
    )
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) => setState(() {}))
      ..play();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VideoPlayer(controller);
  }
}

class HobbyVideoPlayer extends StatefulWidget {
  const HobbyVideoPlayer({
    Key? key,
  }) : super(key: key);

  @override
  _HobbyVideoPlayerState createState() => _HobbyVideoPlayerState();
}

class _HobbyVideoPlayerState extends State<HobbyVideoPlayer> {
  late VideoPlayerController controller;

  @override
  void initState() {
    super.initState();

    controller = VideoPlayerController.asset(
      'assets/videos/JacobVersionCropped.mp4',
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
      ),
    )
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) => setState(() {}))
      ..play();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VideoPlayer(controller);
  }
}

class CreationBackground extends StatefulWidget {
  final int index;

  const CreationBackground({
    Key? key,
    required this.index,
  }) : super(key: key);

  @override
  State<CreationBackground> createState() => _CreationBackgroundState();
}

class _CreationBackgroundState extends State<CreationBackground> {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: VideoPlayers[widget.index],
    );
  }
}

class FriendshipVideoPlayer extends StatefulWidget {
  const FriendshipVideoPlayer({
    Key? key,
  }) : super(key: key);

  @override
  _FriendshipVideoPlayerState createState() => _FriendshipVideoPlayerState();
}

class _FriendshipVideoPlayerState extends State<FriendshipVideoPlayer> {
  late VideoPlayerController controller;

  @override
  void initState() {
    super.initState();

    controller = VideoPlayerController.asset(
      'assets/videos/FriendshipVideo.mp4',
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
      ),
    )
      //..addListener(() => setState(() {}))
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) => setState(() {}))
      ..play();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VideoPlayer(controller);
  }
}
