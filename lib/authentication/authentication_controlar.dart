// authentication_controlar.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'AppUser.dart';
import '../home/home_screen.dart';
import '../services/cloudinary_service.dart';

class AuthenticationController extends GetxController {
  final Rx<File?> _pickedFile = Rx<File?>(null);
  File? get profileImage => _pickedFile.value;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final obscurePassword = true.obs;
  final obscureConfirmPassword = true.obs;
  final isLoading = false.obs;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    obscurePassword.toggle();
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword.toggle();
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        _pickedFile.value = File(pickedFile.path);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image: ${e.toString()}');
    }
  }

  Future<void> handleSignUp() async {
    try {
      if (passwordController.text != confirmPasswordController.text) {
        throw 'Passwords do not match';
      }
      if (nameController.text.isEmpty) {
        throw 'Please enter your name';
      }
      if (emailController.text.isEmpty) {
        throw 'Please enter your email';
      }
      if (passwordController.text.isEmpty) {
        throw 'Please enter a password';
      }

      await registerUser();
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }

  Future<void> registerUser() async {
    try {
      isLoading.value = true;

      // Upload image to Cloudinary if selected
      String? imageUrl;
      if (_pickedFile.value != null) {
        imageUrl = await _cloudinaryService.uploadImage(_pickedFile.value!);
      }

      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Save user data to Firestore
      final appUser = AppUser(
        name: nameController.text.trim(),
        uid: userCredential.user!.uid,
        image: imageUrl,
        email: emailController.text.trim(),
        youtube: null,
        facebook: null,
        twitter: null,
        instagram: null,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(appUser.toMap());

      // Navigate to home screen after successful registration
      Get.offAll(() => HomeScreen());
    } catch (e) {
      Get.snackbar('Registration Failed', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginUser() async {
    try {
      isLoading.value = true;

      await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Navigate to home screen after successful login
      Get.offAll(() => HomeScreen());
    } catch (e) {
      Get.snackbar('Login Failed', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      clearFields();
    } catch (e) {
      Get.snackbar('Sign Out Failed', e.toString());
    }
  }

  Future<void> resetPassword() async {
    try {
      if (emailController.text.trim().isEmpty) {
        throw 'Please enter your email address';
      }

      isLoading.value = true;
      await _auth.sendPasswordResetEmail(email: emailController.text.trim());
      Get.snackbar('Success', 'Password reset email sent');
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void clearFields() {
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    _pickedFile.value = null;
  }
}