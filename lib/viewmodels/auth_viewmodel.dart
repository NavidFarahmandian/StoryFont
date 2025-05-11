import 'dart:async';

import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool isLoading = false;
  String? error;
  bool _isSuccess = false; // New property to track success state

  bool get isSuccess => _isSuccess; // Getter for isSuccess

  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    try {
      await _authService.signIn(email, password);
      error = null;
      _isSuccess = true; // Set success state on successful sign-in
      _startSuccessResetTimer(); // Start timer to reset success
    } catch (e) {
      error = e.toString();
      _isSuccess = false; // Reset success state on error
      _startErrorResetTimer(); // Start timer to reset error
    }
    _setLoading(false);
  }

  Future<void> signUp(String email, String password) async {
    _setLoading(true);
    try {
      await _authService.signUp(email, password);
      error = null;
      _isSuccess = true; // Set success state on successful sign-up
      _startSuccessResetTimer(); // Start timer to reset success
    } catch (e) {
      error = e.toString();
      _isSuccess = false; // Reset success state on error
      _startErrorResetTimer(); // Start timer to reset error
    }
    _setLoading(false);
  }

  void _setLoading(bool value) {
    isLoading = value;
    _isSuccess = false; // Reset success state when loading starts
    notifyListeners();
  }

  void resetSuccess() {
    _isSuccess = false; // Optional: Method to reset success state
    notifyListeners();
  }

  void _startSuccessResetTimer() {
    Timer(const Duration(seconds: 3), () {
      _isSuccess = false;
      notifyListeners();
    });
  }

  void _startErrorResetTimer() {
    Timer(const Duration(seconds: 6), () {
      error = null;
      notifyListeners();
    });
  }
}