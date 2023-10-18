// ignore_for_file: sort_child_properties_last, avoid_print, unused_import, depend_on_referenced_packages

import 'dart:typed_data';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _userName;
  Uint8List? _image;
  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  void selectImage() async {
    Uint8List? img = await pickImage(ImageSource.gallery);

    setState(() {
      _image = img;
    });
  }

  void captureImageFromCamera() async {
    Uint8List? img = await pickImage(ImageSource.camera);

    setState(() {
      _image = img;
    });

    if (_image != null) {
      // Upload the image to Firebase storage
      await uploadImageToFirebase(_image!);
    }
  }
  //===============================================================================

  Future<Uint8List?> pickImage(ImageSource source) async {
    final XFile? image = await _imagePicker.pickImage(source: source);
    if (image != null) {
      return await image.readAsBytes();
    }
    return null;
  }

  Future<void> uploadImageToFirebase(Uint8List imageBytes) async {
    try {
      // Create a reference to the Firebase storage bucket
      final ref = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('images/${DateTime.now().toString()}.png');

      // Upload the image to Firebase storage
      await ref.putData(imageBytes);

      // Get the download URL of the uploaded image
      final downloadURL = await ref.getDownloadURL();

      // You can now store the downloadURL in your Firebase database or perform other actions.
      // For demonstration purposes, let's print the download URL.
      print('Download URL: $downloadURL');
    } catch (e) {
      print('Error uploading image to Firebase: $e');
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      // Sign out the current user before signing in a new user
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential =
            await _auth.signInWithCredential(credential);
        final User? user = userCredential.user;

        if (user != null) {
          print('Signed in as: ${user.displayName}');
          print('Profile picture URL: ${user.photoURL}');

          setState(() {
            _image =
                null; // Reset the _image as we will load the profile picture
            _userName = user.displayName; // Set the user's name
          });

          _loadProfilePicture(user.photoURL);
        }
      }
    } catch (e) {
      print('Error signing in with Google: $e');
    }
  }

//====================================================================================
  void _loadProfilePicture(String? photoURL) async {
    if (photoURL == null) return;

    try {
      final response = await http.get(Uri.parse(photoURL));
      if (response.statusCode == 200) {
        setState(() {
          _image = response.bodyBytes;
        });
      } else {
        print('Failed to load profile picture: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading profile picture: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pick image from gallery',
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Pick image from gallery"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  _image != null
                      ? CircleAvatar(
                          radius: 64,
                          backgroundImage: MemoryImage(_image!),
                        )
                      : const CircleAvatar(
                          radius: 64,
                          backgroundImage: NetworkImage(
                            "https://www.seekpng.com/png/detail/428-4287240_no-avatar-user-circle-icon-png.png",
                          ),
                        ),
                  Positioned(
                    child: IconButton(
                      onPressed: selectImage,
                      icon: const Icon(Icons.add_a_photo_outlined),
                    ),
                    bottom: -10,
                    left: 80,
                  ),
                ],
              ),
              if (_userName != null) // Display the user's name if available
                Text(
                  _userName!,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ElevatedButton.icon(
                onPressed: captureImageFromCamera,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Capture Image from Camera'),
              ),
              ElevatedButton.icon(
                onPressed: signInWithGoogle,
                icon: const Icon(Icons.person),
                label: const Text('Google Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
