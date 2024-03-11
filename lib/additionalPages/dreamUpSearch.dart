import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:friendivity/additionalPages/dreamUpDetail.dart';

import '../main.dart';

class DreamUpSearchPage extends StatefulWidget {
  const DreamUpSearchPage({Key? key}) : super(key: key);

  @override
  State<DreamUpSearchPage> createState() => _DreamUpSearchPageState();
}

class _DreamUpSearchPageState extends State<DreamUpSearchPage> {
  late TextEditingController searchController;

  List<Map<String, dynamic>> searchedVibes = [];

  bool noVibesFound = false;

  Future searchForVibes() async {
    searching = true;

    setState(() {});

    String hashtagSearch = searchController.text.trim().toLowerCase();

    var titleContains = await FirebaseFirestore.instance
        .collection('vibes')
        .where('searchCharacters',
            arrayContains: searchController.text.trim().toLowerCase())
        .orderBy('createdOn', descending: false)
        .get();
    var hashtagContains = await FirebaseFirestore.instance
        .collection('vibes')
        .where('hashtags',
            arrayContains:
                hashtagSearch[0] == '#' ? hashtagSearch : '#$hashtagSearch')
        .orderBy('createdOn', descending: false)
        .get();

    for (var title in titleContains.docs) {
      var data = title.data();

      searchedVibes.add(data);

      setState(() {});
    }

    for (var hashtag in hashtagContains.docs) {
      var data = hashtag.data();

      var id = data['id'];

      var existing =
          searchedVibes.firstWhereOrNull((element) => element['id'] == id);

      if (existing == null) {
        searchedVibes.add(data);

        setState(() {});
      }
    }

    searchedVibes.removeWhere(
      (element) => CurrentUser.requestedCreators.containsKey(
        element['creator'],
      ),
    );

    searching = false;

    if (searchedVibes.isEmpty) {
      noVibesFound = true;
    }

    setState(() {});
  }

  int searchState = 0;

  bool searching = false;

  @override
  void initState() {
    super.initState();

    searchController = TextEditingController()
      ..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    searchController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: MediaQuery.of(context).padding.top,
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (searchState == 0) {
                      Navigator.pop(context);
                    } else {
                      searchState = 0;

                      searching = false;

                      searchedVibes.clear();

                      noVibesFound = false;

                      searchController.text = '';

                      setState(() {});
                    }
                  },
                  child: Container(
                    color: Colors.transparent,
                    width: MediaQuery.of(context).size.width * 0.15,
                    height: MediaQuery.of(context).size.width * 0.15,
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: MediaQuery.of(context).size.width * 0.1,
                    padding: EdgeInsets.symmetric(
                      vertical: MediaQuery.of(context).size.width * 0.02,
                      horizontal: MediaQuery.of(context).size.width * 0.03,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(7.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          margin: EdgeInsets.only(
                            right: MediaQuery.of(context).size.width * 0.02,
                          ),
                          child: const Icon(
                            Icons.search_rounded,
                            color: Colors.black87,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            onTap: () {
                              if (searchState == 0) {
                                searchState = 1;

                                setState(() {});
                              }
                            },
                            onChanged: (value) {
                              if (searchState == 0) {
                                searchState = 1;

                                setState(() {});
                              }
                            },
                            onSubmitted: (value) async {
                              FocusManager.instance.primaryFocus?.unfocus();

                              searchedVibes.clear();

                              if (CurrentUser.recentlySearched
                                  .contains(value)) {
                                CurrentUser.recentlySearched.remove(value);
                                CurrentUser.recentlySearched.insert(0, value);
                              } else {
                                CurrentUser.recentlySearched.insert(0, value);
                              }

                              await CurrentUser().saveUserInformation();

                              await searchForVibes();
                            },
                            maxLines: 1,
                            autofocus: true,
                            autocorrect: true,
                            enableSuggestions: true,
                            textCapitalization: TextCapitalization.none,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Suche',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                vertical:
                                    MediaQuery.of(context).size.width * 0.01,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            searchController.text = '';

                            searching = false;

                            searchedVibes.clear();

                            FocusManager.instance.primaryFocus?.unfocus();

                            searchState = 0;

                            setState(() {});
                          },
                          child: Visibility(
                            visible: searchController.text.isNotEmpty,
                            child: Container(
                              margin: EdgeInsets.only(
                                left: MediaQuery.of(context).size.width * 0.02,
                              ),
                              child: const Icon(
                                Icons.cancel,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Visibility(
                  visible: searchController.text.isEmpty || searchState != 1,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.03,
                  ),
                ),
                Visibility(
                  visible: searchController.text.isNotEmpty && searchState > 0,
                  child: GestureDetector(
                    onTap: () async {
                      FocusManager.instance.primaryFocus?.unfocus();

                      searchedVibes.clear();

                      setState(() {});

                      await searchForVibes();

                      String value = searchController.text;

                      if (CurrentUser.recentlySearched.contains(value)) {
                        CurrentUser.recentlySearched.remove(value);
                        CurrentUser.recentlySearched.insert(0, value);
                      } else {
                        CurrentUser.recentlySearched.insert(0, value);
                      }

                      await CurrentUser().saveUserInformation();

                      setState(() {});
                    },
                    child: Container(
                      height: MediaQuery.of(context).size.width * 0.15,
                      color: Colors.transparent,
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.03,
                      ),
                      child: const Center(
                        child: Text(
                          'Suchen',
                          style: TextStyle(
                            color: Colors.blueAccent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: searchState == 0
                  ? ListView(
                      padding: EdgeInsets.zero,
                      physics: const BouncingScrollPhysics(),
                      children:
                          CurrentUser.recentlySearched.map<Widget>((search) {
                        return GestureDetector(
                          onTap: () async {
                            searchController.text = search;

                            searchState = 1;

                            searchedVibes.clear();

                            await searchForVibes();

                            setState(() {});

                            FocusManager.instance.primaryFocus?.unfocus();

                            CurrentUser.recentlySearched.remove(search);
                            CurrentUser.recentlySearched.insert(0, search);

                            await CurrentUser().saveUserInformation();
                          },
                          child: Container(
                            margin: EdgeInsets.symmetric(
                              horizontal:
                                  MediaQuery.of(context).size.width * 0.05,
                              vertical:
                                  MediaQuery.of(context).size.width * 0.02,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.access_time,
                                ),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.02,
                                ),
                                Expanded(
                                  child: Text(
                                    search,
                                    style: const TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.02,
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    CurrentUser.recentlySearched.remove(search);

                                    await CurrentUser().saveUserInformation();
                                  },
                                  child: const Icon(
                                    Icons.cancel_outlined,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    )
                  : searching
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : searchedVibes.isNotEmpty
                          ? ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.symmetric(
                                vertical:
                                    MediaQuery.of(context).size.width * 0.05,
                              ),
                              itemCount: searchedVibes.length,
                              itemBuilder: (context, index) {
                                var vibe = searchedVibes[index];

                                List<dynamic> hashtags = vibe['hashtags'] ?? [];

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      changePage(
                                        DreamUpDetailPage(
                                          dreamUpData: vibe,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    margin: EdgeInsets.only(
                                      left: MediaQuery.of(context).size.width *
                                          0.05,
                                      right: MediaQuery.of(context).size.width *
                                          0.05,
                                      bottom:
                                          MediaQuery.of(context).size.width *
                                              0.05,
                                    ),
                                    width:
                                        MediaQuery.of(context).size.width * 0.9,
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: CachedNetworkImageProvider(
                                          vibe['imageLink'],
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        MediaQuery.of(context).size.width *
                                            0.03,
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.black.withOpacity(0.4),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.03,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.all(
                                            MediaQuery.of(context).size.width *
                                                0.05,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                vibe['title'],
                                                style: const TextStyle(
                                                  fontSize: 18,
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
                                              const SizedBox(
                                                height: 8,
                                              ),
                                              Text(
                                                vibe['content'],
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.white,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.black87,
                                                      blurRadius: 5,
                                                      offset: Offset(1, 1),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(
                                                height:
                                                    hashtags.isNotEmpty ? 8 : 0,
                                              ),
                                              Wrap(
                                                spacing: 8,
                                                children: hashtags
                                                    .map<Widget>(
                                                      (hashtag) => Text(
                                                        hashtag,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                          shadows: [
                                                            Shadow(
                                                              color: Colors
                                                                  .black87,
                                                              blurRadius: 5,
                                                              offset:
                                                                  Offset(1, 1),
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
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )
                          : Visibility(
                              visible: noVibesFound,
                              child: Container(
                                padding: EdgeInsets.all(
                                  MediaQuery.of(context).size.width * 0.1,
                                ),
                                child: Text(
                                  'Zu deiner Suche "${searchController.text}" gibt es keine passenden Treffer.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 18,
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
