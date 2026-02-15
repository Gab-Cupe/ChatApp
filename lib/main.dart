import 'package:chatapp/chat_addons/logic/dialog_state.dart';
import 'package:chatapp/notifications/message_listener.dart';
import 'package:chatapp/notifications/notification_service.dart';
import 'package:chatapp/notifications/timer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Import platform-specific implementations
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize webview platform
  WebViewPlatform? platform = WebViewPlatform.instance;
  if (platform == null) {
    // Use null-aware assignment
    WebViewPlatform.instance ??= (defaultTargetPlatform == TargetPlatform.iOS)
        ? WebKitWebViewPlatform()
        : AndroidWebViewPlatform();
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.initialize();
  runApp(
    ChangeNotifierProvider(
      create: (context) => DialogState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _messageListener = MessageListener();

  @override
  void initState() {
    super.initState();
    _messageListener.startListening();
    PeriodicNotifier.start(300);
  }

  @override
  void dispose() {
    PeriodicNotifier.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue, // Paleta de azules (incluye celeste)
        primaryColor: const Color(0xFF42A5F5), // Celeste específico
        colorScheme: ColorScheme.light(
          primary: const Color(
            0xFF42A5F5,
          ), // Celeste para elementos interactivos
          secondary: const Color(0xFFBBDEFB), // Celeste claro para acentos
        ),
        scaffoldBackgroundColor: Colors.transparent,
        fontFamily: 'Montserrat',
        // Personalización adicional para elementos específicos
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFF42A5F5), // Cursor celeste en TextFields
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Color(0xFF42A5F5), // Loading spinner celeste
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: MaterialStateProperty.resolveWith<Color?>((
            Set<MaterialState> states,
          ) {
            if (states.contains(MaterialState.disabled)) {
              return null;
            }
            if (states.contains(MaterialState.selected)) {
              return const Color(0xFF42A5F5);
            }
            return null;
          }),
        ),
        radioTheme: RadioThemeData(
          fillColor: MaterialStateProperty.resolveWith<Color?>((
            Set<MaterialState> states,
          ) {
            if (states.contains(MaterialState.disabled)) {
              return null;
            }
            if (states.contains(MaterialState.selected)) {
              return const Color(0xFF42A5F5);
            }
            return null;
          }),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith<Color?>((
            Set<MaterialState> states,
          ) {
            if (states.contains(MaterialState.disabled)) {
              return null;
            }
            if (states.contains(MaterialState.selected)) {
              return const Color(0xFF42A5F5);
            }
            return null;
          }),
          trackColor: MaterialStateProperty.resolveWith<Color?>((
            Set<MaterialState> states,
          ) {
            if (states.contains(MaterialState.disabled)) {
              return null;
            }
            if (states.contains(MaterialState.selected)) {
              return const Color(0xFF42A5F5);
            }
            return null;
          }),
        ), // Checkbox/Switch activos
      ),
      home: Scaffold(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        body: LoginScreen(),
      ),
    );
  }
}
