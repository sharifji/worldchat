// upload_controllar.dart
import 'package:get/get.dart';
import 'package:video_compress/video_compress.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:worldchat/services/cloudinary_service.dart';

class UploadController extends GetxController {
  final RxBool isCompressing = false.obs;
  final RxBool isUploading = false.obs;
  final RxBool isStoringData = false.obs;
  final RxDouble uploadProgress = 0.0.obs;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final Rx<File?> videoFile = Rx<File?>(null);
  final Rx<File?> thumbnailFile = Rx<File?>(null);

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    VideoCompress.dispose();
    super.onClose();
  }

  Future<void> pickVideo() async {
    try {
      final pickedFile = await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (pickedFile != null) {
        videoFile.value = File(pickedFile.path);
        await _generateThumbnail(pickedFile.path);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick video: ${e.toString()}');
    }
  }

  Future<void> _generateThumbnail(String videoPath) async {
    try {
      isCompressing.value = true;
      final thumbnail = await VideoCompress.getFileThumbnail(
        videoPath,
        quality: 50,
        position: 0,
      );
      thumbnailFile.value = thumbnail;
    } catch (e) {
      Get.snackbar('Error', 'Failed to generate thumbnail: ${e.toString()}');
    } finally {
      isCompressing.value = false;
    }
  }

  Future<void> compressVideo() async {
    try {
      if (videoFile.value == null) return;

      isCompressing.value = true;
      final MediaInfo? compressedVideo = await VideoCompress.compressVideo(
        videoFile.value!.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
      );

      if (compressedVideo != null) {
        videoFile.value = File(compressedVideo.path!);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to compress video: ${e.toString()}');
    } finally {
      isCompressing.value = false;
    }
  }

  Future<void> saveVideoInformationToFireStoreDatabase(
      String title,
      String description,
      String videoPath,
      BuildContext context,
      ) async {
    try {
      await uploadVideo();
    } catch (e) {
      throw 'Failed to save video information: $e';
    }
  }

  Future<void> uploadVideo() async {
    try {
      if (videoFile.value == null || thumbnailFile.value == null) {
        throw 'Please select a video and ensure thumbnail is generated';
      }

      if (titleController.text.isEmpty) {
        throw 'Please enter a title for your video';
      }

      final user = _auth.currentUser;
      if (user == null) throw 'User not authenticated';

      // Start upload process
      isUploading.value = true;
      uploadProgress.value = 0.0;

      // Upload video to Cloudinary
      final videoUrl = await _cloudinaryService.uploadVideo(
        videoFile.value!,
        onProgress: (progress) {
          uploadProgress.value = progress;
        },
      );

      // Upload thumbnail to Cloudinary
      final thumbnailUrl = await _cloudinaryService.uploadImage(
        thumbnailFile.value!,
      );

      // Store video data in Firestore
      isStoringData.value = true;
      await _firestore.collection('videos').add({
        'userId': user.uid,
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'videoUrl': videoUrl,
        'thumbnailUrl': thumbnailUrl,
        'views': 0,
        'likes': 0,
        'comments': 0,
        'timestamp': FieldValue.serverTimestamp(),
      });

      Get.snackbar('Success', 'Video uploaded successfully');
      resetForm();
    } catch (e) {
      Get.snackbar('Upload Failed', e.toString());
    } finally {
      isUploading.value = false;
      isStoringData.value = false;
      uploadProgress.value = 0.0;
    }
  }

  void resetForm() {
    titleController.clear();
    descriptionController.clear();
    videoFile.value = null;
    thumbnailFile.value = null;
    uploadProgress.value = 0.0;
  }

  String get progressText => '${(uploadProgress.value * 100).toStringAsFixed(1)}%';
}