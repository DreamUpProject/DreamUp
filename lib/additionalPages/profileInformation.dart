import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../main.dart';
import '../utils/imageEditingIsolate.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({Key? key}) : super(key: key);

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final currentUser = FirebaseAuth.instance.currentUser?.uid;

  File? croppedImage;
  String? changedName;
  String? changedBio;
  String? changedGender;
  DateTime? changedBirthday;

  bool somethingChanged() {
    if (croppedImage != null ||
        changedName != null ||
        changedBio != null ||
        changedGender != null ||
        changedBirthday != null) {
      return true;
    } else {
      return false;
    }
  }

  Future pickImage(bool fromGallery) async {
    final pickedImage = await ImagePicker().pickImage(
        source: fromGallery ? ImageSource.gallery : ImageSource.camera);

    if (pickedImage == null) return;

    final imageTemporary = File(pickedImage.path);

    await cropImage(imageTemporary);

    setState(() {});
  }

  Future<File?> cropImage(File? image) async {
    var cropped = await ImageCropper().cropImage(
        sourcePath: image!.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        aspectRatioPresets: [CropAspectRatioPreset.square]);

    setState(() {
      croppedImage = File(cropped!.path);
    });

    return null;
  }

  bool changeImage = false;

  bool sending = false;

  String translateGender(String gender) {
    if (gender == 'male') {
      return 'männlich';
    } else if (gender == 'female') {
      return 'weiblich';
    } else {
      return 'divers';
    }
  }

  Future<String> get appDirectory async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
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
            Navigator.pop(
              context,
              true,
            );
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
          'Persönliche Informationen',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.width * 0.4,
                width: MediaQuery.of(context).size.width * 0.4,
                child: croppedImage == null
                    ? CachedNetworkImage(
                        imageUrl: CurrentUser.imageLink!,
                      )
                    : Image.file(croppedImage!),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.width * 0.05,
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    changeImage ? changeImage = false : changeImage = true;
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: MediaQuery.of(context).size.width * 0.03,
                    horizontal: MediaQuery.of(context).size.width * 0.05,
                  ),
                  color: Colors.white,
                  child: Text(
                    changeImage ? 'Abbrechen' : 'Bild ändern',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: changeImage,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.width * 0.03,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            await pickImage(false);

                            setState(() {
                              changeImage = false;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical:
                                  MediaQuery.of(context).size.width * 0.03,
                              horizontal:
                                  MediaQuery.of(context).size.width * 0.05,
                            ),
                            color: Colors.white,
                            child: const Text(
                              'Kamera',
                              style: TextStyle(
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.03,
                        ),
                        GestureDetector(
                          onTap: () async {
                            await pickImage(true);

                            setState(() {
                              changeImage = false;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical:
                                  MediaQuery.of(context).size.width * 0.03,
                              horizontal:
                                  MediaQuery.of(context).size.width * 0.05,
                            ),
                            color: Colors.white,
                            child: const Text(
                              'Galerie',
                              style: TextStyle(
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(
            height: MediaQuery.of(context).size.width * 0.1,
          ),
          Container(
            padding: EdgeInsets.only(
              left: MediaQuery.of(context).size.width * 0.05,
              bottom: MediaQuery.of(context).size.width * 0.02,
            ),
            child: const Text(
              'Über mich',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
          GestureDetector(
            onTap: () async {
              changedName = await Navigator.push(
                context,
                changePage(
                  const NameChangePage(),
                ),
              ) as String?;

              setState(() {});
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.05,
                vertical: MediaQuery.of(context).size.width * 0.05,
              ),
              color: Colors.white,
              child: Row(
                children: [
                  const Text(
                    'Name',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Container(),
                  ),
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.3,
                    ),
                    margin: EdgeInsets.only(
                      right: MediaQuery.of(context).size.width * 0.03,
                    ),
                    child: Text(
                      changedName != null
                          ? changedName!
                          : CurrentUser.name ?? 'Dein Name',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black38,
                      ),
                    ),
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
          GestureDetector(
            onTap: () async {
              changedBio = await Navigator.push(
                context,
                changePage(
                  const BioChangePage(),
                ),
              ) as String?;

              setState(() {});
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.05,
                vertical: MediaQuery.of(context).size.width * 0.05,
              ),
              color: Colors.white,
              child: Row(
                children: [
                  const Text(
                    'Beschreibung',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Container(),
                  ),
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.3,
                    ),
                    margin: EdgeInsets.only(
                      right: MediaQuery.of(context).size.width * 0.03,
                    ),
                    child: Text(
                      changedBio != null
                          ? changedBio!
                          : CurrentUser.bio ?? 'Deine Beschreibung',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black38,
                      ),
                    ),
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
          GestureDetector(
            onTap: () async {
              changedGender = await Navigator.push(
                context,
                changePage(
                  const GenderChangePage(),
                ),
              ) as String?;

              setState(() {});
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.05,
                vertical: MediaQuery.of(context).size.width * 0.05,
              ),
              color: Colors.white,
              child: Row(
                children: [
                  const Text(
                    'Geschlecht',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Container(),
                  ),
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.3,
                    ),
                    margin: EdgeInsets.only(
                      right: MediaQuery.of(context).size.width * 0.03,
                    ),
                    child: Text(
                      changedGender != null
                          ? translateGender(changedGender!)
                          : CurrentUser.gender == null
                              ? 'Deine Beschreibung'
                              : CurrentUser.gender == ''
                                  ? 'Deine Beschreibung'
                                  : translateGender(CurrentUser.gender!) == ''
                                      ? 'Deine Beschreibung'
                                      : translateGender(CurrentUser.gender!),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black38,
                      ),
                    ),
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
          GestureDetector(
            onTap: () async {
              DateTime? chosenDate = await showDatePicker(
                context: context,
                locale: const Locale(
                  'de',
                  'de-de',
                ),
                initialDate: DateTime.now(),
                firstDate: DateTime(DateTime.now().year - 100),
                lastDate: DateTime.now(),
                helpText: 'Wann ist dein Geburtstag?',
                cancelText: 'Abbrechen',
                confirmText: 'Bestätigen',
              );

              if (chosenDate != null) {
                changedBirthday = chosenDate;

                setState(() {});
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.05,
                vertical: MediaQuery.of(context).size.width * 0.05,
              ),
              color: Colors.white,
              child: Row(
                children: [
                  const Text(
                    'Geburtstag',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Container(),
                  ),
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.3,
                    ),
                    margin: EdgeInsets.only(
                      right: MediaQuery.of(context).size.width * 0.03,
                    ),
                    child: Text(
                      changedBirthday != null
                          ? DateFormat('dd.MM.yyyy').format(changedBirthday!)
                          : CurrentUser.birthday != null
                              ? DateFormat('dd.MM.yyyy')
                                  .format(CurrentUser.birthday!)
                              : 'Dein Geburtstag',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black38,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.transparent,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: GestureDetector(
              onTap: () async {
                if (somethingChanged() && !sending) {
                  sending = true;

                  setState(() {});

                  Map<String, dynamic> json = {};

                  if (croppedImage != null) {
                    if (CurrentUser.imageLink != null &&
                        CurrentUser.imageLink !=
                            'https://firebasestorage.googleapis.com/v0/b/activities-with-friends.appspot.com/o/placeholderImages%2FuserPlaceholder.png?alt=media&token=1a4e6423-446d-48b5-8bbf-466900c350ec') {
                      await FirebaseStorage.instance
                          .ref(
                              'userImages/${FirebaseAuth.instance.currentUser?.uid}')
                          .delete();
                    }

                    try {
                      await FirebaseStorage.instance
                          .ref(
                              'userImages/${FirebaseAuth.instance.currentUser?.uid}')
                          .putFile(croppedImage!);
                    } on FirebaseException catch (e) {
                      print(e);
                    }

                    var link = await FirebaseStorage.instance
                        .ref(
                            'userImages/${FirebaseAuth.instance.currentUser?.uid}')
                        .getDownloadURL();

                    json.addAll({
                      'imageLink': link,
                    });

                    CurrentUser.imageLink = link;

                    final path = await appDirectory;

                    var userId = currentUser;

                    File compressedFile =
                        await File('$path/compressedImage/$userId.jpg')
                            .create(recursive: true);

                    var compressed =
                        await FlutterImageCompress.compressAndGetFile(
                      croppedImage!.path,
                      compressedFile.path,
                      minHeight: 200,
                      minWidth: 200,
                      quality: 0,
                    );

                    File imageFile = File(compressed!.path);

                    await File(
                            '$path/userInformation/images/blurredImage/$userId')
                        .delete();

                    File file = await File(
                            '$path/userInformation/images/blurredImage/$userId')
                        .create(recursive: true);

                    var uiImage = await compute(blurImage, imageFile);

                    file.writeAsBytesSync(
                      img.encodePng(uiImage),
                      mode: FileMode.append,
                    );

                    CurrentUser.blurredImage = file;
                    CurrentUser.imageFile = croppedImage!;

                    CurrentUser().saveImageFile(croppedImage!);
                  }

                  if (changedName != null) {
                    print('name is not null');

                    var chats = await FirebaseFirestore.instance
                        .collection('chats')
                        .where('participants',
                            arrayContains:
                                FirebaseAuth.instance.currentUser?.uid)
                        .get();

                    print(chats.docs.length);

                    for (var chat in chats.docs) {
                      await FirebaseFirestore.instance
                          .collection('chats')
                          .doc(chat.id)
                          .update(
                        {
                          'names': FieldValue.arrayRemove(
                            [
                              CurrentUser.name,
                            ],
                          ),
                        },
                      );

                      await FirebaseFirestore.instance
                          .collection('chats')
                          .doc(chat.id)
                          .update(
                        {
                          'names': FieldValue.arrayUnion(
                            [
                              changedName,
                            ],
                          ),
                        },
                      );
                    }

                    CurrentUser.name = changedName;

                    json.addAll({
                      'name': changedName,
                    });
                  }

                  if (changedBio != null) {
                    CurrentUser.bio = changedBio;

                    json.addAll({
                      'bio': changedBio,
                    });
                  }

                  if (changedGender != null) {
                    CurrentUser.gender = changedGender;

                    json.addAll({
                      'gender': changedGender,
                    });
                  }

                  if (changedBirthday != null) {
                    CurrentUser.birthday = changedBirthday;

                    json.addAll({
                      'birthday': changedBirthday,
                    });
                  }

                  if (json.isNotEmpty) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .update(json);

                    CurrentUser().saveUserInformation();
                  }

                  Fluttertoast.cancel();
                  Fluttertoast.showToast(
                      msg: 'Information saved successfully!');

                  Navigator.pop(
                    context,
                    true,
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
                  color: somethingChanged() ? Colors.blue : Colors.black26,
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
    );
  }
}

class NameChangePage extends StatefulWidget {
  const NameChangePage({Key? key}) : super(key: key);

  @override
  State<NameChangePage> createState() => _NameChangePageState();
}

class _NameChangePageState extends State<NameChangePage> {
  final nameController = TextEditingController();

  String? changedName;

  @override
  void initState() {
    super.initState();

    nameController.addListener(() {
      setState(() {});
    });

    nameController.text = CurrentUser.name ?? '';
  }

  @override
  void dispose() {
    nameController.dispose();

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
            changedName = null;
            Navigator.pop(context, changedName);
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
          'Name ändern',
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
                'Name',
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
                child: TextField(
                  controller: nameController,
                  onSubmitted: (text) {
                    if (text != '') {
                      changedName = text;
                    }
                  },
                  enableSuggestions: true,
                  autocorrect: true,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: CurrentUser.name ?? 'Name',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.03,
                    ),
                  ),
                ),
              ),
              Center(
                child: GestureDetector(
                  onTap: () async {
                    if (nameController.text.isNotEmpty &&
                        nameController.text.trim() != CurrentUser.name) {
                      changedName = nameController.text;

                      Navigator.pop(context, changedName);
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
                      color: nameController.text.isNotEmpty &&
                              nameController.text.trim() != CurrentUser.name
                          ? Colors.blue
                          : Colors.black26,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Text(
                      'Speichern',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
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

class BioChangePage extends StatefulWidget {
  const BioChangePage({Key? key}) : super(key: key);

  @override
  State<BioChangePage> createState() => _BioChangePageState();
}

class _BioChangePageState extends State<BioChangePage> {
  final bioController = TextEditingController();

  String? changedBio;

  @override
  void initState() {
    super.initState();

    bioController.addListener(() {
      setState(() {});
    });

    bioController.text = CurrentUser.bio ?? '';
  }

  @override
  void dispose() {
    bioController.dispose();

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
            changedBio = null;
            Navigator.pop(context, changedBio);
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
          'Beschreibung ändern',
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
                'Beschreibung',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    top: MediaQuery.of(context).size.width * 0.02,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      width: 1,
                      color: Colors.black54,
                    ),
                    color: Colors.white,
                  ),
                  child: TextField(
                    controller: bioController,
                    onSubmitted: (text) {
                      if (text != '') {
                        changedBio = text;
                      }
                    },
                    enableSuggestions: true,
                    autocorrect: true,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    expands: true,
                    minLines: null,
                    maxLines: null,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Beschreibung',
                      contentPadding: EdgeInsets.all(
                        MediaQuery.of(context).size.width * 0.03,
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: GestureDetector(
                  onTap: () async {
                    if (bioController.text.isNotEmpty &&
                        bioController.text.trim() != CurrentUser.bio) {
                      changedBio = bioController.text;

                      Navigator.pop(context, changedBio);
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
                      color: bioController.text.isNotEmpty &&
                              bioController.text.trim() != CurrentUser.bio
                          ? Colors.blue
                          : Colors.black26,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Text(
                      'Speichern',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
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

class GenderChangePage extends StatefulWidget {
  const GenderChangePage({Key? key}) : super(key: key);

  @override
  State<GenderChangePage> createState() => _GenderChangePageState();
}

class _GenderChangePageState extends State<GenderChangePage> {
  String? changedGender;

  bool male = false;
  bool female = false;
  bool diverse = false;

  void getGender(String? gender) {
    print(gender);

    if (gender == 'male') {
      male = true;
    } else if (gender == 'female') {
      female = true;
    } else {
      diverse = true;
    }
  }

  @override
  void initState() {
    super.initState();

    getGender(CurrentUser.gender);
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
            changedGender = null;
            Navigator.pop(context, changedGender);
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
          'Geschlecht ändern',
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
              GestureDetector(
                onTap: () {
                  setState(() {
                    male = true;
                    female = false;
                    diverse = false;

                    changedGender = 'male';
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.05,
                    vertical: MediaQuery.of(context).size.width * 0.05,
                  ),
                  color: Colors.white,
                  child: Row(
                    children: [
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: Checkbox(
                          shape: const CircleBorder(),
                          value: male,
                          onChanged: (isMale) {
                            setState(() {
                              male = isMale!;
                              female = !isMale;
                              diverse = !isMale;

                              changedGender = 'male';
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.03,
                      ),
                      Text(
                        'männlich',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              male ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      Expanded(
                        child: Container(),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    male = false;
                    female = true;
                    diverse = false;

                    changedGender = 'female';
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.05,
                    vertical: MediaQuery.of(context).size.width * 0.05,
                  ),
                  color: Colors.white,
                  child: Row(
                    children: [
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: Checkbox(
                          shape: const CircleBorder(),
                          value: female,
                          onChanged: (isFemale) {
                            setState(() {
                              male = !isFemale!;
                              female = isFemale;
                              diverse = !isFemale;

                              changedGender = 'female';
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.03,
                      ),
                      Text(
                        'weiblich',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              female ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      Expanded(
                        child: Container(),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    male = false;
                    female = false;
                    diverse = true;

                    changedGender = 'diverse';
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.05,
                    vertical: MediaQuery.of(context).size.width * 0.05,
                  ),
                  color: Colors.white,
                  child: Row(
                    children: [
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: Checkbox(
                          shape: const CircleBorder(),
                          value: diverse,
                          onChanged: (isDiverse) {
                            setState(() {
                              male = !isDiverse!;
                              female = !isDiverse;
                              diverse = isDiverse;

                              changedGender = 'diverse';
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.03,
                      ),
                      Text(
                        'divers',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              diverse ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      Expanded(
                        child: Container(),
                      ),
                    ],
                  ),
                ),
              ),
              Center(
                child: GestureDetector(
                  onTap: () async {
                    if (changedGender != null &&
                        changedGender != CurrentUser.gender) {
                      Navigator.pop(context, changedGender);
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
                      color: changedGender != null &&
                              changedGender != CurrentUser.gender
                          ? Colors.blue
                          : Colors.black26,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Text(
                      'Speichern',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
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
