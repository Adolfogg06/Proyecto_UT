import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../core/constants.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AppUser? _appUser;
  AuthStatus _status = AuthStatus.unknown;
  String? _errorMessage;
  bool _isLoading = false;

  AppUser? get appUser => _appUser;
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isComercio => _appUser?.isComercio ?? false;

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? user) async {
    if (user == null) {
      _appUser = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      _appUser = await _authService.fetchAppUser(user.uid);
      _status = AuthStatus.authenticated;
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _appUser = await _authService.login(email: email, password: password);
      _status = AuthStatus.authenticated;
      return true;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    String businessName = '',
    String businessAddress = '',
    GeoPoint? businessLocation,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _appUser = await _authService.register(
        email: email,
        password: password,
        displayName: displayName,
        role: role,
        businessName: businessName,
        businessAddress: businessAddress,
        businessLocation: businessLocation,
      );
      _status = AuthStatus.authenticated;
      return true;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _appUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    if (_appUser == null) return;
    _appUser = await _authService.fetchAppUser(_appUser!.uid);
    notifyListeners();
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('email-already-in-use')) return 'Ese correo ya está registrado';
    if (msg.contains('weak-password')) return 'La contraseña es muy débil (mín. 6 caracteres)';
    if (msg.contains('user-not-found') || msg.contains('wrong-password')) {
      return 'Correo o contraseña incorrectos';
    }
    if (msg.contains('invalid-email')) return 'Correo inválido';
    return 'Ocurrió un error. Intenta de nuevo.';
  }
}
