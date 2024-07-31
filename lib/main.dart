import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:pakfoundf/Providers/itemProvider.dart';
import 'package:pakfoundf/api/firebase_api.dart';
import 'package:pakfoundf/landingScreen.dart';
import 'package:provider/provider.dart';
import 'package:pakfoundf/l10n/localeProvider.dart';
import 'Providers/marketPlaceProvider.dart';
//import 'firebase_api.dart'; // Import the FirebaseAPI class
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'loginAndSignup/loginScreen.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize the FirebaseAPI instance
  FirebaseAPI firebaseAPI = FirebaseAPI();
  await firebaseAPI.initializeFirebase();
  await firebaseAPI.requestPermission();

    // Print the Firebase Messaging token
   await firebaseAPI.printToken();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MarketplaceProvider()),
        ChangeNotifierProvider(create: (context) => LocaleProvider()),
        //ChangeNotifierProvider(create: (context) => ChatProvider()),
        ChangeNotifierProvider(create: (context) => ItemsProvider()),
      ],
      child: MyApp(firebaseAPI: firebaseAPI),
    ),
  );
}

class MyApp extends StatefulWidget {
  final FirebaseAPI firebaseAPI;

  const MyApp({Key? key, required this.firebaseAPI}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: localeProvider.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: L10n.all,
          home: LandingScreen(),
        );
      },
    );
  }
}