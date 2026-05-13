// lib/utils/helpers/helper_functions.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class THelperFunctions {
  static Color? getColor(String value) {
    if (value == 'Green') {
      return Colors.green;
    } else if (value == 'Red') {
      return Colors.red;
    } else if (value == 'Blue') {
      return Colors.blue;
    } else if (value == 'Pink') {
      return Colors.pink;
    } else if (value == 'Grey') {
      return Colors.grey;
    } else if (value == 'Purple') {
      return Colors.purple;
    } else if (value == 'Black') {
      return Colors.black;
    } else if (value == 'White') {
      return Colors.white;
    } else if (value == 'Yellow') {
      return Colors.yellow;
    } else if (value == 'Orange') {
      return Colors.deepOrange;
    } else if (value == 'Brown') {
      return Colors.brown;
    } else if (value == 'Teal') {
      return Colors.teal;
    } else if (value == 'Indigo') {
      return Colors.indigo;
    } else {
      return null;
    }
  }

  // --- FIXED: Using Get.rawSnackbar for iOS compatibility ---
  static void _showCustomSnackBar({
    required String title,
    required String message,
    required Color backgroundColor,
    required IconData icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Close any existing snackbar first to prevent stacking
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    Get.rawSnackbar(
      title: title.isEmpty ? null : title,
      messageText: Text(
        message,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      backgroundColor: backgroundColor,
      icon: Icon(icon, color: Colors.white, size: 28),
      margin: const EdgeInsets.all(15),
      borderRadius: 10,
      duration: duration,
      isDismissible: true,
      snackPosition: SnackPosition.TOP,
      forwardAnimationCurve: Curves.easeOutBack,
    );
  }

  static void showSuccessSnackBar(String title, String message) {
    _showCustomSnackBar(
      title: title,
      message: message,
      backgroundColor: TColors.success.withOpacity(0.9),
      icon: Iconsax.tick_circle,
    );
  }

  static void showErrorSnackBar(String title, String message) {
    _showCustomSnackBar(
      title: title,
      message: message,
      backgroundColor: TColors.error.withOpacity(0.9),
      icon: Iconsax.warning_2,
      duration: const Duration(seconds: 5),
    );
  }

  static void showWarningSnackBar(String title, String message) {
    _showCustomSnackBar(
      title: title,
      message: message,
      backgroundColor: Colors.orange.withOpacity(0.9),
      icon: Iconsax.warning_2,
    );
  }

  static void showSnackBar(String message) {
    _showCustomSnackBar(
      title: '',
      message: message,
      backgroundColor: TColors.info.withOpacity(0.9),
      icon: Iconsax.info_circle,
    );
  }
  // --- END FIXED ---

  static void showAlert(String title, String message) {
    showDialog<void>(
      context: Get.context!,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  static void navigateToScreen(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => screen));
  }

  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    } else {
      return '${text.substring(0, maxLength)}...';
    }
  }

  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Size screenSize() {
    return MediaQuery.of(Get.context!).size;
  }

  static double screenHeight() {
    return MediaQuery.of(Get.context!).size.height;
  }

  static double screenWidth() {
    return MediaQuery.of(Get.context!).size.width;
  }

  static String getFormattedDate(
    DateTime date, {
    String format = 'dd MMM yyyy',
  }) {
    return DateFormat(format).format(date);
  }

  static List<T> removeDuplicates<T>(List<T> list) {
    return list.toSet().toList();
  }

  static List<Widget> wrapWidgets(List<Widget> widgets, int rowSize) {
    final wrappedList = <Widget>[];
    for (var i = 0; i < widgets.length; i += rowSize) {
      final rowChildren = widgets.sublist(
        i,
        i + rowSize > widgets.length ? widgets.length : i + rowSize,
      );
      wrappedList.add(Row(children: rowChildren));
    }
    return wrappedList;
  }

  static Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
  }
}
