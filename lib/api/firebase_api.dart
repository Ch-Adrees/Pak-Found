import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseAPI {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
    _setupFirebaseMessagingHandlers();
  }

  void _setupFirebaseMessagingHandlers() {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessage(message);
    });
  }

  Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    print('Handling a background message: ${message.messageId}');
    _handleMessage(message);
  }

  void _handleMessage(RemoteMessage message) {
    if (message.notification != null) {
      print('Message Title: ${message.notification!.title}');
      print('Message Body: ${message.notification!.body}');
    }
    if (message.data.isNotEmpty) {
      print('Message Data: ${message.data}');
    }
  }

  Future<void> requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }
  }

  Future<void> printToken() async {
    String? token = await _firebaseMessaging.getToken();
    print('Firebase Messaging Token: $token');
  }
  // ignore: empty_constructor_bodies, use_function_type_syntax_for_parameters

  Future<void> enablePushNotifications() async {
    await _firebaseMessaging.subscribeToTopic('all');
    print('Push notifications enabled');
  }

  Future<void> disablePushNotifications() async {
    await _firebaseMessaging.unsubscribeFromTopic('all');
    print('Push notifications disabled');
  }
}
