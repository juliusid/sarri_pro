import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sarri_ride/app.dart';
import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/utils/dependency_injection.dart';
import 'package:sarri_ride/firebase_options.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Keep splash screen up until we are ready
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await GetStorage.init();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize HTTP Service (Critical for Auth)
  await Get.putAsync(() => HttpService().init());

  // Initialize other dependencies (Lazy loading applied here)
  await DependencyInjection.init();

  runApp(const App());
}
