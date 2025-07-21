import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final userProvider = StreamProvider.family<UserModel?, String>((ref, uid) {
  final firestore = ref.watch(firestoreProvider);
  
  return firestore
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((snapshot) {
    if (snapshot.exists && snapshot.data() != null) {
      return UserModel.fromJson(snapshot.data()!);
    }
    return null;
  });
});

final currentUserProvider = StreamProvider<UserModel?>((ref) async* {
  final authState = ref.watch(authStateChangesProvider);
  
  await for (final user in authState.when(
    data: (user) async* {
      if (user != null) {
        final userDoc = ref.watch(userProvider(user.uid));
        yield* userDoc.when(
          data: (userData) async* {
            yield userData;
          },
          loading: () async* {
            yield null;
          },
          error: (error, stack) async* {
            yield null;
          },
        );
      } else {
        yield null;
      }
    },
    loading: () async* {
      yield null;
    },
    error: (error, stack) async* {
      yield null;
    },
  )) {
    yield user;
  }
});