import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants.dart';
import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<AppUser> register({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    String businessName = '',
    String businessAddress = '',
    GeoPoint? businessLocation,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;

    final appUser = AppUser(
      uid: uid,
      email: email,
      role: role,
      displayName: displayName,
      businessName: businessName,
      businessAddress: businessAddress,
      businessLocation: businessLocation,
    );

    await _db
        .collection(FirestoreCollections.users)
        .doc(uid)
        .set(appUser.toMap());

    return appUser;
  }

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return fetchAppUser(credential.user!.uid);
  }

  Future<AppUser> fetchAppUser(String uid) async {
    final doc =
        await _db.collection(FirestoreCollections.users).doc(uid).get();
    if (!doc.exists) {
      throw Exception('Perfil de usuario no encontrado');
    }
    return AppUser.fromMap(uid, doc.data()!);
  }

  Future<void> logout() => _auth.signOut();
}
