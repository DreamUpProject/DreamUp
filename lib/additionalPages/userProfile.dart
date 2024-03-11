import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:friendivity/additionalPages/dreamUpDetail.dart';

import '../main.dart';

var color = const Color(0xFF485868);

class UserProfile extends StatefulWidget {
  final String chatId;
  final String partnerId;

  const UserProfile({
    Key? key,
    required this.chatId,
    required this.partnerId,
  }) : super(key: key);

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  Map<String, dynamic> partnerInfo = {};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.partnerId)
          .get();

      partnerInfo = doc.data()!;

      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    double padding = MediaQuery.of(context).size.width / 6 / 4;

    return Scaffold(
      backgroundColor: const Color(0xFFE2E2E2),
      body: partnerInfo.isNotEmpty
          ? StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var data = snapshot.data!.data() as Map<String, dynamic>;
                  var info = data['shownInformation'] as Map?;

                  bool nameUnlocked = false;
                  bool imageUnlocked = false;
                  bool bioUnlocked = false;
                  bool dreamUpsUnlocked = false;

                  if (info != null) {
                    var userInfo = info[widget.partnerId] as Map?;

                    if (userInfo != null) {
                      nameUnlocked = userInfo['name'] == true;
                      imageUnlocked = userInfo['image'] == true;
                      bioUnlocked = userInfo['bio'] == true;
                      dreamUpsUnlocked = userInfo['dreamUps'] == true;
                    }
                  }

                  String name = nameUnlocked ? partnerInfo['name'] : 'User';
                  String imageLink = imageUnlocked
                      ? partnerInfo['imageLink']
                      : 'https://firebasestorage.googleapis.com/v0/b/activities-with-friends.appspot.com/o/placeholderImages%2FuserPlaceholder.png?alt=media&token=1a4e6423-446d-48b5-8bbf-466900c350ec&_gl=1*1g9i9yi*_ga*ODE3ODU3OTY4LjE2OTI2OTU2NzA.*_ga_CW55HF8NVT*MTY5ODkxNDQwMS4yMy4xLjE2OTg5MTUyNzEuNTkuMC4w';
                  String bio = bioUnlocked
                      ? partnerInfo['bio']
                      : 'Dieser User hat dir seinen Profiltext noch nicht freigegeben.';

                  return SizedBox.expand(
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: SizedBox(
                            child: CachedNetworkImage(
                              imageUrl: imageLink,
                              fit: BoxFit.fitWidth,
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: DraggableScrollableSheet(
                            snap: true,
                            initialChildSize: 0.55,
                            minChildSize: 0.55,
                            maxChildSize: 0.9,
                            builder: (context, ScrollController controller) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E2E2),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(
                                      MediaQuery.of(context).size.width * 0.05,
                                    ),
                                    topRight: Radius.circular(
                                      MediaQuery.of(context).size.width * 0.05,
                                    ),
                                  ),
                                ),
                                child: ListView(
                                  controller: controller,
                                  physics: const BouncingScrollPhysics(),
                                  padding: EdgeInsets.only(
                                    bottom:
                                        MediaQuery.of(context).padding.bottom,
                                  ),
                                  children: [
                                    Stack(
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              margin: EdgeInsets.only(
                                                left: padding * 2,
                                                right: padding * 2,
                                              ),
                                              padding: EdgeInsets.only(
                                                top: padding * 2,
                                                bottom: padding,
                                              ),
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                'I am $name',
                                                style: TextStyle(
                                                  fontSize: 26,
                                                  color: color.withOpacity(1),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              margin: EdgeInsets.only(
                                                left: padding * 2,
                                                right: padding * 2,
                                              ),
                                              child: Text(
                                                bio,
                                                textAlign: TextAlign.start,
                                                style: TextStyle(
                                                  color: color.withOpacity(0.6),
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              height: padding * 0.5,
                                            ),
                                            Container(
                                              margin: EdgeInsets.only(
                                                left: padding * 2,
                                                right: padding * 2,
                                              ),
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width -
                                                  padding * 4,
                                              color: color.withOpacity(0.4),
                                            ),
                                            SizedBox(
                                              height: padding,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    StreamBuilder(
                                        stream: FirebaseFirestore.instance
                                            .collection('vibes')
                                            .where('creator',
                                                isEqualTo: widget.partnerId)
                                            .orderBy('createdOn',
                                                descending: true)
                                            .snapshots(),
                                        builder: (context,
                                            AsyncSnapshot<QuerySnapshot>
                                                snapshot) {
                                          if (snapshot.hasError) {
                                            return Center(
                                              child: SizedBox(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.8,
                                                child: Text(
                                                  'An Error has occured: ${snapshot.error}',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            );
                                          } else if (snapshot.hasData) {
                                            if (snapshot
                                                .data!.docs.isNotEmpty) {
                                              return ListView(
                                                shrinkWrap: true,
                                                padding: EdgeInsets.only(
                                                  bottom: MediaQuery.of(context)
                                                          .padding
                                                          .bottom +
                                                      (MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              2) /
                                                          15,
                                                ),
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                children: snapshot.data!.docs
                                                    .map<Widget>((doc) {
                                                  var data = doc.data()
                                                      as Map<String, dynamic>;

                                                  List<dynamic>? hashtags =
                                                      data['hashtags'];

                                                  return GestureDetector(
                                                    onTap: () async {
                                                      dreamUpsUnlocked
                                                          ? Navigator.push(
                                                              context,
                                                              changePage(
                                                                DreamUpDetailPage(
                                                                  dreamUpData:
                                                                      data,
                                                                ),
                                                              ),
                                                            )
                                                          : Fluttertoast
                                                              .showToast(
                                                              msg:
                                                                  'Dieser User hat dir seine erstellten DreamUps noch nicht freigegeben.',
                                                            );
                                                    },
                                                    child: Container(
                                                      margin: EdgeInsets.only(
                                                        left: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width *
                                                            0.05,
                                                        right: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width *
                                                            0.05,
                                                        bottom: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width *
                                                            0.05,
                                                      ),
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.9,
                                                      decoration: BoxDecoration(
                                                        image: DecorationImage(
                                                          image:
                                                              CachedNetworkImageProvider(
                                                            data['imageLink'],
                                                          ),
                                                          fit: BoxFit.cover,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.03,
                                                        ),
                                                      ),
                                                      child: Stack(
                                                        children: [
                                                          Positioned.fill(
                                                            child: Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .black
                                                                    .withOpacity(
                                                                        0.4),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                  MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width *
                                                                      0.03,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          Container(
                                                            padding:
                                                                EdgeInsets.all(
                                                              MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width *
                                                                  0.05,
                                                            ),
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Text(
                                                                  data['title'],
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        18,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: Colors
                                                                        .white,
                                                                    shadows: [
                                                                      Shadow(
                                                                        color: Colors
                                                                            .black87,
                                                                        blurRadius:
                                                                            10,
                                                                        offset: Offset(
                                                                            1,
                                                                            1),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  height: 8,
                                                                ),
                                                                Text(
                                                                  data[
                                                                      'content'],
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                    color: Colors
                                                                        .white,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    shadows: [
                                                                      Shadow(
                                                                        color: Colors
                                                                            .black87,
                                                                        blurRadius:
                                                                            5,
                                                                        offset: Offset(
                                                                            1,
                                                                            1),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                  height: hashtags !=
                                                                              null &&
                                                                          hashtags
                                                                              .isNotEmpty
                                                                      ? 8
                                                                      : 0,
                                                                ),
                                                                hashtags != null &&
                                                                        hashtags
                                                                            .isNotEmpty
                                                                    ? Wrap(
                                                                        spacing:
                                                                            8,
                                                                        children: hashtags
                                                                            .map<Widget>(
                                                                              (hashtag) => Text(
                                                                                hashtag,
                                                                                style: const TextStyle(
                                                                                  fontSize: 16,
                                                                                  fontWeight: FontWeight.bold,
                                                                                  color: Colors.white,
                                                                                  shadows: [
                                                                                    Shadow(
                                                                                      color: Colors.black87,
                                                                                      blurRadius: 5,
                                                                                      offset: Offset(1, 1),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                            )
                                                                            .toList(),
                                                                      )
                                                                    : Container(),
                                                              ],
                                                            ),
                                                          ),
                                                          Positioned.fill(
                                                            child:
                                                                dreamUpsUnlocked
                                                                    ? Container()
                                                                    : ClipRRect(
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                          MediaQuery.of(context).size.width *
                                                                              0.03,
                                                                        ),
                                                                        child:
                                                                            BackdropFilter(
                                                                          filter:
                                                                              ImageFilter.blur(
                                                                            sigmaX:
                                                                                5,
                                                                            sigmaY:
                                                                                5,
                                                                          ),
                                                                          child:
                                                                              Container(),
                                                                        ),
                                                                      ),
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              );
                                            } else {
                                              return SizedBox(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.8,
                                                child: const Text(
                                                  'Du hast noch keine DreamUps ertsellt!',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              );
                                            }
                                          } else {
                                            return const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            );
                                          }
                                        }),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: MediaQuery.of(context).padding.top,
                          left: 0,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: const SizedBox(
                              height: 50,
                              width: 50,
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            )
          : Container(
              color: Colors.white,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
    );
  }
}

class ProfileBackground extends StatelessWidget {
  final String? imageURL;

  const ProfileBackground({Key? key, required this.imageURL}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Stack(
            children: [
              Positioned.fill(
                child: Image(
                  image: Image.network(imageURL!).image,
                  fit: BoxFit.fill,
                ),
              ),
              Positioned(
                top: 0,
                child: SizedBox(
                  height: MediaQuery.of(context).size.width,
                  width: MediaQuery.of(context).size.width,
                  child: Image(
                    image: Image.network(imageURL!).image,
                    fit: BoxFit.fill,
                  ),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
