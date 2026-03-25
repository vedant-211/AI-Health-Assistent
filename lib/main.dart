import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medical/pages/home.dart';
import 'package:medical/pages/auth_page.dart';
import 'package:medical/services/auth_service.dart';
import 'package:medical/services/local_storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'theme/app_styles.dart';
import 'services/connectivity_service.dart';
import 'widgets/companion_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env file
  await dotenv.load();
  
  // Initialize Local Storage (Hive)
  await LocalStorageService().init();
  
  // Firebase initialization
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('❌ Firebase initialization error: $e');
  }

  // Start connection monitoring
  ConnectivityService().startMonitoring();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
    return MaterialApp(
      title: 'SwasthMitra AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppStyles.bgDark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppStyles.primaryBlue,
          brightness: Brightness.dark,
          surface: AppStyles.bgSurface,
        ),
        fontFamily: 'Poppins',
        textTheme: Typography.whiteMountainView.apply(
          fontFamily: 'Poppins',
          bodyColor: AppStyles.textMain,
          displayColor: AppStyles.textMain,
        ).copyWith(
          bodyLarge: const TextStyle(height: 1.45, letterSpacing: 0.1),
          bodyMedium: const TextStyle(height: 1.45, letterSpacing: 0.1),
          titleLarge: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
      ),
      home: const AuthWrapper(),
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            const GlobalCompanionOverlay(),
            const Positioned(bottom: 0, left: 0, right: 0, child: ConnectionStatusBanner()),
          ],
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().user,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const HomePage();
        }
        return const AuthPage();
      },
    );
  }
}

class ConnectionStatusBanner extends StatelessWidget {
  const ConnectionStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: ConnectivityService().connectionStream,
      initialData: ConnectivityService().isOnline,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          height: isOnline ? 0 : 40,
          color: Colors.orangeAccent,
          child: isOnline 
            ? const SizedBox.shrink()
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    "Switching to offline mode...", 
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, decoration: TextDecoration.none, fontFamily: 'Poppins')
                  ),
                ],
              ),
        );
      },
    );
  }
}
