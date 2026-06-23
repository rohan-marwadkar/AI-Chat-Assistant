// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserController {

  String? profileImage;
  String? name;
  String? emailId;
  String? userId;
  bool isLogged = false;

  /// ============================
  /// SAVE USER DATA
  /// ============================
  Future<void> setUserData({
    required String profileImage,
    required String name,
    required String emailId,
    required String userId,
    required bool isLoggedIn,
  }) async {

    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString("profileImage", profileImage);
    await prefs.setString("name", name);
    await prefs.setString("emailId", emailId);
    await prefs.setString("userId", userId);
    await prefs.setBool("loginFlag", isLoggedIn);

    // update local variables
    this.profileImage = profileImage;
    this.name = name;
    this.emailId = emailId;
    this.userId = userId;
    this.isLogged = isLoggedIn;

    print("✅ User data saved: $userId");
  }

  /// ============================
  /// LOAD USER DATA
  /// ============================
  Future<void> loadUserData() async {

    SharedPreferences prefs = await SharedPreferences.getInstance();

    profileImage = prefs.getString("profileImage");
    name = prefs.getString("name");
    emailId = prefs.getString("emailId");
    userId = prefs.getString("userId");
    isLogged = prefs.getBool("loginFlag") ?? false;

    print("Loaded userId from prefs: $userId");

    /// 🔥 EXTRA SAFETY FIX
    /// If SharedPreferences lost data, reload from FirebaseAuth
    if (userId == null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        userId = user.uid;
        emailId = user.email;
        isLogged = true;
        print("⚡ Restored user from FirebaseAuth: $userId");
      }
    }
  }

  /// ============================
  /// LOGOUT
  /// ============================
  Future<void> clearUserData() async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    profileImage = null;
    name = null;
    emailId = null;
    userId = null;
    isLogged = false;

    print("🗑 User data cleared");
  }
}
