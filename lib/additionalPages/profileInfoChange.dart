import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:friendivity/main.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePropertyChangePage extends StatefulWidget {
  final String property;

  const ProfilePropertyChangePage({
    Key? key,
    required this.property,
  }) : super(key: key);

  @override
  State<ProfilePropertyChangePage> createState() =>
      _ProfilePropertyChangePageState();
}

class _ProfilePropertyChangePageState extends State<ProfilePropertyChangePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PropertyEditingWidget(
        property: widget.property,
      ),
    );
  }
}

class PropertyEditingWidget extends StatefulWidget {
  final String property;

  const PropertyEditingWidget({
    Key? key,
    required this.property,
  }) : super(key: key);

  @override
  State<PropertyEditingWidget> createState() => _PropertyEditingWidgetState();
}

class _PropertyEditingWidgetState extends State<PropertyEditingWidget> {
  late TextEditingController nameController;
  late TextEditingController bioController;

  String gender = '';

  bool female = false;
  bool male = false;
  bool diverse = false;

  File? croppedImage;

  Future pickImage(bool fromGallery) async {
    File? image;

    final pickedImage = await ImagePicker().pickImage(
        source: fromGallery ? ImageSource.gallery : ImageSource.camera);

    if (pickedImage == null) return;

    final imageTemporary = File(pickedImage.path);
    image = imageTemporary;

    await cropImage(image);

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

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController()
      ..addListener(() {
        setState(() {});
      });

    if (CurrentUser.name != null) {
      nameController.text = CurrentUser.name!;
    }

    bioController = TextEditingController()
      ..addListener(() {
        setState(() {});
      });

    if (CurrentUser.bio != null) {
      bioController.text = CurrentUser.bio!;
    }

    if (CurrentUser.gender != '') {
      if (CurrentUser.gender == 'female') {
        female = true;
        male = false;
        diverse = false;
      } else if (CurrentUser.gender == 'male') {
        female = false;
        male = true;
        diverse = false;
      } else if (CurrentUser.gender == 'diverse') {
        female = false;
        male = false;
        diverse = true;
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();

    bioController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.property == 'Name') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: MediaQuery.of(context).padding.top,
          ),
          SizedBox(
            height: MediaQuery.of(context).size.width * 0.15,
            child: Center(
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: SizedBox(
                      height: MediaQuery.of(context).size.width * 0.15,
                      width: MediaQuery.of(context).size.width * 0.15,
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back_ios_new,
                        ),
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Name',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      if (nameController.text != '' &&
                          nameController.text != CurrentUser.name) {
                        // await CurrentUser.changeUserName(
                        //     nameController.text);

                        CurrentUser.name = nameController.text;

                        Navigator.pop(context);
                      }
                    },
                    child: SizedBox(
                      height: MediaQuery.of(context).size.width * 0.15,
                      width: MediaQuery.of(context).size.width * 0.15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 1.5,
            width: double.infinity,
            color: Colors.black26,
          ),
          SizedBox(
            height: MediaQuery.of(context).size.width * 0.05,
          ),
          Container(
            padding: EdgeInsets.only(
              left: MediaQuery.of(context).size.width * 0.05,
            ),
            child: const Text(
              'Name',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.width * 0.05,
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.05,
            ),
            child: TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                suffixIcon: GestureDetector(
                  onTap: () {
                    nameController.text = '';

                    setState(() {});
                  },
                  child: const Icon(
                    Icons.cancel_outlined,
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: AnimatedOpacity(
              duration: const Duration(
                milliseconds: 200,
              ),
              opacity: nameController.text != '' &&
                      nameController.text != CurrentUser.name
                  ? 1
                  : 0,
              child: GestureDetector(
                onTap: () async {
                  showDialog(
                    barrierDismissible: false,
                    context: context,
                    builder: (context) => Dialog(
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
                            const CircularProgressIndicator(),
                            SizedBox(
                              height: MediaQuery.of(context).size.width * 0.03,
                            ),
                            const Text(
                              'Deine Änderung wird gespeichert...',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );

                  // await CurrentUserInformation.changeUserName(
                  //     nameController.text);

                  CurrentUser.name = nameController.text;

                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.05,
                    vertical: MediaQuery.of(context).size.width * 0.03,
                  ),
                  margin: EdgeInsets.only(
                    top: MediaQuery.of(context).size.width * 0.05,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(
                      MediaQuery.of(context).size.width * 0.03,
                    ),
                  ),
                  child: const Text(
                    'Speichern',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else if (widget.property == 'Beschreibung') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: MediaQuery.of(context).padding.top,
          ),
          SizedBox(
            height: MediaQuery.of(context).size.width * 0.15,
            child: Center(
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: SizedBox(
                      height: MediaQuery.of(context).size.width * 0.15,
                      width: MediaQuery.of(context).size.width * 0.15,
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back_ios_new,
                        ),
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Beschreibung',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      if (bioController.text != '' &&
                          bioController.text != CurrentUser.bio) {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser?.uid)
                            .update({'bio': bioController.text});

                        CurrentUser.bio = bioController.text;

                        Navigator.pop(context);
                      }
                    },
                    child: SizedBox(
                      height: MediaQuery.of(context).size.width * 0.15,
                      width: MediaQuery.of(context).size.width * 0.15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 1.5,
            width: double.infinity,
            color: Colors.black26,
          ),
          SizedBox(
            height: MediaQuery.of(context).size.width * 0.05,
          ),
          Container(
            padding: EdgeInsets.only(
              left: MediaQuery.of(context).size.width * 0.05,
            ),
            child: const Text(
              'Beschreibung',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.width * 0.05,
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.05,
            ),
            child: TextField(
              controller: bioController,
              autofocus: true,
              minLines: 1,
              maxLines: 5,
              decoration: InputDecoration(
                suffixIcon: GestureDetector(
                  onTap: () {
                    bioController.text = '';

                    setState(() {});
                  },
                  child: const Icon(
                    Icons.cancel_outlined,
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: AnimatedOpacity(
              duration: const Duration(
                milliseconds: 200,
              ),
              opacity: bioController.text != '' &&
                      bioController.text != CurrentUser.bio
                  ? 1
                  : 0,
              child: GestureDetector(
                onTap: () async {
                  showDialog(
                    barrierDismissible: false,
                    context: context,
                    builder: (context) => Dialog(
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
                            const CircularProgressIndicator(),
                            SizedBox(
                              height: MediaQuery.of(context).size.width * 0.03,
                            ),
                            const Text(
                              'Deine Änderung wird gespeichert...',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );

                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .update({'bio': bioController.text});

                  CurrentUser.bio = bioController.text;

                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.05,
                    vertical: MediaQuery.of(context).size.width * 0.03,
                  ),
                  margin: EdgeInsets.only(
                    top: MediaQuery.of(context).size.width * 0.05,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(
                      MediaQuery.of(context).size.width * 0.03,
                    ),
                  ),
                  child: const Text(
                    'Speichern',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else if (widget.property == 'Geschlecht') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: MediaQuery.of(context).padding.top,
          ),
          SizedBox(
            height: MediaQuery.of(context).size.width * 0.15,
            child: Center(
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: SizedBox(
                      height: MediaQuery.of(context).size.width * 0.15,
                      width: MediaQuery.of(context).size.width * 0.15,
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back_ios_new,
                        ),
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Geschlecht',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      if (gender != '' &&
                          gender != CurrentUser.gender) {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser?.uid)
                            .update({'gender': gender});

                        CurrentUser.gender = gender;

                        Navigator.pop(context);
                      }
                    },
                    child: SizedBox(
                      height: MediaQuery.of(context).size.width * 0.15,
                      width: MediaQuery.of(context).size.width * 0.15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 1.5,
            width: double.infinity,
            color: Colors.black26,
          ),
          SizedBox(
            height: MediaQuery.of(context).size.width * 0.05,
          ),
          Container(
            padding: EdgeInsets.only(
              left: MediaQuery.of(context).size.width * 0.05,
            ),
            child: const Text(
              'Geschlecht',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.width * 0.05,
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.05,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Checkbox(
                        value: female,
                        onChanged: (value) {
                          gender = 'female';

                          female = true;
                          male = false;
                          diverse = false;

                          setState(() {});
                        },
                        splashRadius: 0,
                        shape: const CircleBorder(),
                        activeColor: Colors.blueAccent,
                      ),
                      const Text('weiblich'),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Checkbox(
                        value: male,
                        onChanged: (value) {
                          gender = 'male';

                          female = false;
                          male = true;
                          diverse = false;

                          setState(() {});
                        },
                        splashRadius: 0,
                        shape: const CircleBorder(),
                        activeColor: Colors.blueAccent,
                      ),
                      const Text('männlich'),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Checkbox(
                        value: diverse,
                        onChanged: (value) {
                          gender = 'diverse';

                          female = false;
                          male = false;
                          diverse = true;

                          setState(() {});
                        },
                        splashRadius: 0,
                        shape: const CircleBorder(),
                        activeColor: Colors.blueAccent,
                      ),
                      const Text('divers'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: AnimatedOpacity(
              duration: const Duration(
                milliseconds: 200,
              ),
              opacity:
                  gender != '' && CurrentUser.gender != '' ? 1 : 0,
              child: GestureDetector(
                onTap: () async {
                  showDialog(
                    barrierDismissible: false,
                    context: context,
                    builder: (context) => Dialog(
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
                            const CircularProgressIndicator(),
                            SizedBox(
                              height: MediaQuery.of(context).size.width * 0.03,
                            ),
                            const Text(
                              'Deine Änderung wird gespeichert...',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );

                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .update({'gender': gender});

                  CurrentUser.gender = gender;

                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.05,
                    vertical: MediaQuery.of(context).size.width * 0.03,
                  ),
                  margin: EdgeInsets.only(
                    top: MediaQuery.of(context).size.width * 0.05,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(
                      MediaQuery.of(context).size.width * 0.03,
                    ),
                  ),
                  child: const Text(
                    'Speichern',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else if (widget.property == 'Bild') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: MediaQuery.of(context).padding.top,
          ),
          SizedBox(
            height: MediaQuery.of(context).size.width * 0.15,
            child: Center(
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: SizedBox(
                      height: MediaQuery.of(context).size.width * 0.15,
                      width: MediaQuery.of(context).size.width * 0.15,
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back_ios_new,
                        ),
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Bild',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {},
                    child: SizedBox(
                      height: MediaQuery.of(context).size.width * 0.15,
                      width: MediaQuery.of(context).size.width * 0.15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 1.5,
            width: double.infinity,
            color: Colors.black26,
          ),
          SizedBox(
            height: MediaQuery.of(context).size.width * 0.05,
          ),
          Container(
            padding: EdgeInsets.only(
              left: MediaQuery.of(context).size.width * 0.05,
            ),
            child: const Text(
              'Bild',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.width * 0.05,
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.05,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  onTap: () async {
                    await pickImage(false).then((value) => setState(() {}));
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: MediaQuery.of(context).size.width * 0.03,
                      horizontal: MediaQuery.of(context).size.width * 0.05,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(
                        MediaQuery.of(context).size.width * 0.02,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Kamera öffnen',
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    await pickImage(true).then((value) => setState(() {}));
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: MediaQuery.of(context).size.width * 0.03,
                      horizontal: MediaQuery.of(context).size.width * 0.05,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(
                        MediaQuery.of(context).size.width * 0.02,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Gallerie öffnen',
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          croppedImage != null
              ? Container(
                  margin: EdgeInsets.only(
                    top: MediaQuery.of(context).size.width * 0.05,
                    left: MediaQuery.of(context).size.width * 0.05,
                    bottom: MediaQuery.of(context).size.width * 0.05,
                  ),
                  height: MediaQuery.of(context).size.width * 0.9,
                  width: MediaQuery.of(context).size.width * 0.9,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: Image.file(
                        croppedImage!,
                        fit: BoxFit.fill,
                      ).image,
                    ),
                    borderRadius: BorderRadius.circular(
                      MediaQuery.of(context).size.width * 0.05,
                    ),
                  ),
                )
              : Container(),
          Center(
            child: AnimatedOpacity(
              duration: const Duration(
                milliseconds: 200,
              ),
              opacity: croppedImage != null ? 1 : 0,
              child: GestureDetector(
                onTap: () async {
                  showDialog(
                    barrierDismissible: false,
                    context: context,
                    builder: (context) => Dialog(
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
                            const CircularProgressIndicator(),
                            SizedBox(
                              height: MediaQuery.of(context).size.width * 0.03,
                            ),
                            const Text(
                              'Deine Änderung wird gespeichert...',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );

                  if (CurrentUser.imageLink !=
                      'https://firebasestorage.googleapis.com/v0/b/activities-with-friends.appspot.com/o/placeholderImages%2FuserPlaceholder.png?alt=media&token=1a4e6423-446d-48b5-8bbf-466900c350ec') {
                    await FirebaseStorage.instance
                        .ref('userImages/${FirebaseAuth.instance.currentUser?.uid}')
                        .delete();
                  }

                  try {
                    await FirebaseStorage.instance
                        .ref('userImages/${FirebaseAuth.instance.currentUser?.uid}')
                        .putFile(croppedImage!);
                  } on FirebaseException catch (e) {
                    print(e);
                  }

                  var link = await FirebaseStorage.instance
                      .ref('userImages/${FirebaseAuth.instance.currentUser?.uid}')
                      .getDownloadURL();

                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .update({'imageLink': link});

                  CurrentUser.imageLink = link;

                  var image = CachedNetworkImageProvider(link);

                  await precacheImage(image, context);

                  Map<String, CachedNetworkImageProvider> entry = {
                    FirebaseAuth.instance.currentUser!.uid: image
                  };

                  LoadedImages.remove(FirebaseAuth.instance.currentUser?.uid);

                  LoadedImages.addAll(entry);

                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.05,
                    vertical: MediaQuery.of(context).size.width * 0.03,
                  ),
                  margin: EdgeInsets.only(
                    top: MediaQuery.of(context).size.width * 0.05,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(
                      MediaQuery.of(context).size.width * 0.03,
                    ),
                  ),
                  child: const Text(
                    'Speichern',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: MediaQuery.of(context).padding.top,
          ),
          SizedBox(
            height: MediaQuery.of(context).size.width * 0.15,
            child: Center(
              child: Row(
                children: [
                  GestureDetector(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.width * 0.15,
                      width: MediaQuery.of(context).size.width * 0.15,
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back_ios_new,
                        ),
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Name',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.width * 0.15,
                      width: MediaQuery.of(context).size.width * 0.15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 1.5,
            width: double.infinity,
            color: Colors.black26,
          )
        ],
      );
    }
  }
}
