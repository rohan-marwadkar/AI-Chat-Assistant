import 'dart:io';
import 'package:chat_app/view/custom_snakbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:developer';

import 'package:flutter/material.dart';

class LoginController{
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  //upload image to firebase storage
  Future<void> uploadImage({
    required String fileName,
    required File file,
  })
  async{
    log("Uploading image to firebase storage");
    await _firebaseStorage.ref().child(fileName).putFile(file);
  }

  //download image url
  Future<String> getImageUrl({required String fileName})async{
    String url = await _firebaseStorage.ref().child(fileName).getDownloadURL();
    return url;
  }

Future<String> registerUser({
  required BuildContext context,
  required String email,
  required String password,
}) async {
  try {
    UserCredential credential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    

    return credential.user?.uid ?? "";

  } on FirebaseAuthException catch (e) {
    log(e.toString());

    if (e.code == 'email-already-in-use') {
      throw Exception("Email already used");
    }

    if (e.code == 'weak-password') {
      throw Exception("Password is too weak");
    }

    if (e.code == 'invalid-email') {
      throw Exception("Invalid email address");
    }

    throw Exception("Registration failed");
  }
}

  //store user data to firebase firestore
  Future<void> storeUserDataToDatabase({
    required Map<String,dynamic> userData,
  })async{
    await _firebaseFirestore.collection("Users").add(userData);
  }

//login user with email and password
Future<bool> loginUser({
  required BuildContext context,
  required String email,
  required String password,
}) async {
  try {
    UserCredential userCredentialObj =
        await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    log("Login Status: $userCredentialObj");

    if (userCredentialObj.user != null) {
      
      CustomSnackbar().showCustomSnackbar(
        context: context,
        message: "Login Successful",
      );
      return true;
    }
  } on FirebaseAuthException catch (error) {
    log("Firebase Login Error: ${error.code}");

    String message = "";

    switch (error.code) {
      case "user-not-found":
        message = "No user found with this email.";
        break;
      case "wrong-password":
        message = "Wrong password.";
        break;
      case "invalid-email":
        message = "Invalid email address.";
        break;
      case "invalid-credential":
        message = "Invalid email or password.";
        break;
      case "network-request-failed":
        message = "Please check your internet connection.";
        break;
      default:
        message = error.message ?? "Login failed.";
    }

    CustomSnackbar().showCustomSnackbar(
      context: context,
      message: message,
    );

    return false;
  } catch (e) {
    log("Unknown Login Error: $e");

    CustomSnackbar().showCustomSnackbar(
      context: context,
      message: "Something went wrong. Try again.",
    );

    return false;
  }

  return false;
}

}