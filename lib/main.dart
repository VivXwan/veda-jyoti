import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'utils/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Configure Firebase emulators for testing
  // NOTE: Remove these lines for production deployment
  await _connectToFirebaseEmulators();
  
  runApp(const ProviderScope(child: VedaJyotiApp()));
}

/// Configure Firebase emulators for local testing
/// IMPORTANT: This should be removed/commented out for production
Future<void> _connectToFirebaseEmulators() async {
  const String localhost = '127.0.0.1';
  
  // Connect to Authentication emulator
  await FirebaseAuth.instance.useAuthEmulator(localhost, 9099);
  
  // Connect to Firestore emulator
  FirebaseFirestore.instance.useFirestoreEmulator(localhost, 8080);
}

class VedaJyotiApp extends ConsumerWidget {
  const VedaJyotiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'Veda Jyoti',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}