import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static late SharedPreferences _prefs;

  static Future init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static bool isLoggedIn() {
    return _prefs.getBool('isLoggedIn') ?? false;
  }

  static Future setLoggedIn(bool value) {
    return _prefs.setBool('isLoggedIn', value);
  }

   // Métodos para el UserID
  static String? getUserID() {
    return _prefs.getString('userID');
  }

  static Future setUserID(String userID) {
    return _prefs.setString('userID', userID);
  }

  // Métodos para el Nombre
  static String? getName() {
    return _prefs.getString('name');
  }

  static Future setName(String name) {
    return _prefs.setString('name', name);
  }

  // Métodos para el Email
  static String? getEmail() {
    return _prefs.getString('email');
  }

  static Future setEmail(String email) {
    return _prefs.setString('email', email);
  }

  // Métodos para el Token
  static String? getToken() {
    return _prefs.getString('token');
  }

  static Future setToken(String token) {
    return _prefs.setString('token', token);
  }
  // Métodos para la imagen
  static String? getImg() {
    return _prefs.getString('imagen');
  }

  static Future setImg(String imagen) {
    return _prefs.setString('imagen', imagen);
  }
  // Métodos para la setFcmToken
  static String? getFcmToken() {
    return _prefs.getString('FcmToken');
  }

  static Future setFcmToken(String FcmToken) {
    return _prefs.setString('FcmToken', FcmToken);
  }
}
