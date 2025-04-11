import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'dart:io';
import 'firebase_options.dart';

import 'features/profile/domain/entities/user.dart';
import 'features/skills/domain/entities/skill.dart';
import 'features/github/domain/entities/github_repository.dart';
import 'features/github/domain/entities/github_todo.dart';
import 'features/github/data/repositories/github_repository_impl.dart';
import 'core/router/app_router.dart';
import 'features/skills/presentation/pages/skills_page.dart';
import 'features/auth/presentation/pages/login_page.dart';

// Application operation modes
enum AppMode {
  // Using real Firebase
  real,
  // Using Firebase emulator
  emulator,
  // Offline mode (without Firebase)
  offline,
}

// Choose operation mode: AppMode.real, AppMode.emulator or AppMode.offline
const AppMode appMode = AppMode.emulator;

// Set to true to use Firebase emulator
const bool useFirebaseEmulator = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseInitialized = false;

  if (appMode == AppMode.offline) {
    if (kDebugMode) {
      print('Starting application in offline mode without Firebase');
    }

    // In offline mode, just initialize Hive
    firebaseInitialized = true;
  } else {
    try {
      if (kDebugMode) {
        print('Initializing Firebase...');
      }

      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      firebaseInitialized = true;

      if (kDebugMode) {
        print('Firebase successfully initialized!');
      }

      // Connect to Firebase Emulator if the corresponding mode is selected
      if (useFirebaseEmulator || appMode == AppMode.emulator) {
        if (kDebugMode) {
          print('Connecting to Firebase Auth Emulator (localhost:9099)...');
        }

        await firebase_auth.FirebaseAuth.instance.useAuthEmulator(
          'localhost',
          9099,
        );

        if (kDebugMode) {
          print(
            'Connection to Firebase Auth Emulator successfully established!',
          );
        }
      } else {
        if (kDebugMode) {
          print('Using real Firebase');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Firebase initialization error: $e');
        print('Stack trace: $stackTrace');
      }

      // Don't automatically switch to offline mode on error
      firebaseInitialized = false;
    }
  }

  // Initialize Hive for local data storage
  await Hive.initFlutter();

  // Register adapters for data models
  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(SkillAdapter());
  Hive.registerAdapter(SkillCategoryAdapter());

  // Open boxes for local storage
  await Hive.openBox<User>('users');
  await Hive.openBox<Skill>('skills');
  await Hive.openBox('auth_tokens');

  // Initialize GitHub repository (includes registering GitHub adapters)
  await GithubRepositoryImpl.initHive();

  runApp(
    ProviderScope(
      overrides: [
        // Pass operation mode information to providers
        appModeProvider.overrideWithValue(appMode),
      ],
      child: DevMateApp(firebaseInitialized: firebaseInitialized),
    ),
  );
}

/// Application mode provider
final appModeProvider = Provider<AppMode>((ref) => AppMode.real);

class DevMateApp extends ConsumerWidget {
  final bool firebaseInitialized;

  const DevMateApp({super.key, required this.firebaseInitialized});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(appModeProvider);

    if (kDebugMode) {
      print(
        'DevMateApp: mode: $currentMode, Firebase initialized: $firebaseInitialized',
      );
    }

    // If Firebase is not initialized, show error message
    if (!firebaseInitialized) {
      return CupertinoApp(
        debugShowCheckedModeBanner: false,
        title: 'DevMate',
        theme: const CupertinoThemeData(
          brightness: Brightness.light,
          primaryColor: CupertinoColors.systemBlue,
        ),
        home: CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(
            middle: Text('Firebase Error'),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Firebase Initialization Error',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Check your internet connection and Firebase configuration file.',
                    style: TextStyle(color: CupertinoColors.destructiveRed),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Make sure Firebase emulator is running (if emulator mode is selected).',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  CupertinoButton.filled(
                    onPressed: () {
                      if (kDebugMode) {
                        print('Retrying connection');
                      }
                      main();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // If Firebase is initialized or working in offline mode, use router
    return CupertinoApp.router(
      debugShowCheckedModeBanner: false,
      title: 'DevMate',
      theme: const CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: CupertinoColors.systemBlue,
      ),
      routerConfig: appRouter,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
    );
  }
}
