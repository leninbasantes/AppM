// ignore_for_file: avoid_dynamic_calls

import 'dart:async';
import 'dart:convert';

import 'package:alerta_global/constants.dart';
import 'package:alerta_global/custom_route.dart';
import 'package:alerta_global/dashboard_screen.dart';
import 'package:alerta_global/service/api_service.dart';
import 'package:alerta_global/system_verification.dart';
import 'package:app_alertaglobalconstecoin/flutter_login.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter_session_manager/flutter_session_manager.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
export 'package:app_alertaglobalconstecoin/src/models/login_data.dart';
export 'package:app_alertaglobalconstecoin/src/models/user_data.dart';

class LoginScreen extends StatelessWidget {
  static const routeName = '/auth';

  const LoginScreen({super.key});

  Duration get loginTime => Duration(milliseconds: timeDilation.ceil() * 2250);

  // Metodo de login del sistema
  Future<String?> _loginUser(LoginData data) {
    return Future.delayed(loginTime).then((_) async {
      const url = "${Constants.urlPrincipal}/login/";

      final response = await makeRequest(
          url: url,
          data: {"email": data.email, "password": data.password, "app": "1","tokenFCM": UserPreferences.getFcmToken()},);

      // Debug: Imprimir el JSON completo
      final String jsonString = json.encode(response);
      debugPrint(jsonString);

      if (response is Map<String, dynamic>) {
        if (response.containsKey('error')) {
          return response['error'].toString();
        }
      }

      // Validación de usuario bloqueado
      if (response["blocked"] == true) {
        return "Usuario Bloqueado. Por favor solicitar desbloqueo a su Administrador de Red";
      }

      // Validación de correo no confirmado
      if (response["confirmed"] == false) {
        return "La cuenta de correo de su usuario no ha sido confirmado.";
      }

      final sessionManager = SessionManager();
      debugPrint("No esta logeado");
      await UserPreferences.setName(
          '${response["name"]} ${response["lastname"]}',);
      await UserPreferences.setEmail(data.email);
      await UserPreferences.setUserID(response["_id"].toString());
      await UserPreferences.setToken(response["token"].toString());
      await UserPreferences.setImg(response["image"].split(',')[1] as String);

      await UserPreferences.setLoggedIn(true);

      await sessionManager.set("userName", UserPreferences.getName());
      await sessionManager.set("email", data.email);
      await sessionManager.set("userId", response["_id"].toString());
      await sessionManager.set("token", response["token"].toString());

      // La lista de servicios debe ser manejada como una lista y no como una cadena
      const DashboardScreen dashboardScreenObject = DashboardScreen();
      dashboardScreenObject.serviceList = json.encode(response[
          "services"],); // Asumiendo que la UI puede manejar listas directamente

      final String serviceListJson = jsonEncode(response["services"]);
      await saveServiceList(serviceListJson);

      // Debug: Imprimir los servicios
      debugPrint(response["services"].toString());
      return null;
    });
  }

  Future<void> saveServiceList(String serviceListJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('serviceList', serviceListJson);
  }

  Future<String?> getServiceList() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('serviceList');
  }

  Future<String?> _signupUser(SignupData data) {
    return Future.delayed(loginTime).then((_) {
      return null;
    });
  }

  Future<String?> _recoverPassword(String email) {
    return Future.delayed(loginTime).then((_) async {
      const url = "${Constants.urlPrincipal}/forgot-password/";
      final dio = Dio();
      final response = await dio.post(
        url,
        data: {"email": email},
        options: Options(
          validateStatus: (_) => true,
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
        ),
      );
      if (response.data.toString().contains('error')) {
        final List<String> retorno =
            (jsonDecode(response.data.toString()) as List<dynamic>)
                .cast<String>();
        debugPrint(retorno.first);
        return retorno.first;
      }
      return null;
    });
  }

  Future<String?> _signupConfirm(String error, LoginData data) {
    return Future.delayed(loginTime).then((_) {
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FlutterLogin(
      title: Constants.appName,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      logo: const AssetImage('assets/images/alertaglobal.png'),
      navigateBackAfterRecovery: true,
      onConfirmRecover: _signupConfirm,
      onConfirmSignup: _signupConfirm,
      loginAfterSignUp: false,
      termsOfService: [
        TermOfService(
          id: 'general-term',
          mandatory: true,
          text: 'Términos de Servicios',
          linkUrl: "${Constants.urlPrincipal}/terminos",
        ),
      ],
      additionalSignupFields: [
        UserFormField(
          keyName: 'Email',
          icon: const Icon(FontAwesomeIcons.squareEnvelope),
          userType: LoginUserType.email,
          fieldValidator: (value) {
            final bool emailValid = RegExp(
                    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",)
                .hasMatch(value ?? "");
            if (!emailValid) {
              return "Ingrese un Email Correcto";
            }
            return null;
          },
        ),
        const UserFormField(keyName: 'Name'),
        const UserFormField(keyName: 'Surname'),
        UserFormField(
          keyName: 'phone_number',
          displayName: 'Phone Number',
          userType: LoginUserType.phone,
          icon: const Icon(FontAwesomeIcons.squarePhoneFlip),
          fieldValidator: (value) {
            final phoneRegExp = RegExp(
              '^(\\+\\d{1,2}\\s)?\\(?\\d{3}\\)?[\\s.-]?\\d{3}[\\s.-]?\\d{4}\$',
            );
            if (value != null &&
                value.length < 7 &&
                !phoneRegExp.hasMatch(value)) {
              return "Este no es un número de teléfono válido";
            }
            return null;
          },
        ),
      ],
      userValidator: (value) {
        final bool emailValid = RegExp(
                r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",)
            .hasMatch(value ?? "");
        if (!emailValid) {
          return "Ingrese un Email Correcto";
        }
        return null;
      },
      passwordValidator: (value) {
        if (value!.isEmpty) {
          return 'Ingrese Contraseña';
        }
        return null;
      },
      onLogin: (loginData) {
        return _loginUser(loginData);
      },
      onSignup: (signupData) {
        debugPrint('Signup info');
        debugPrint('Name: ${signupData.name}');
        debugPrint('Password: ${signupData.password}');

        return _signupUser(signupData);
      },
      onSubmitAnimationCompleted: () {
        Navigator.of(context).pushReplacement(
          FadePageRoute(
            builder: (context) => const DashboardScreen(),
          ),
        );
      },
      onRecoverPassword: (name) {
        debugPrint('Recover password info');
        debugPrint('Name: $name');
        return _recoverPassword(name);
        // Show new password dialog
      },
      headerWidget: const IntroWidget(),
    );
  }
}

class IntroWidget extends StatelessWidget {
  const IntroWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Align(
              child: Image.asset(
                'assets/images/icono.png',
                filterQuality: FilterQuality.high,
                height: 250,
                width: 250,
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Align(
              child: Image.asset(
                'assets/images/alertaglobal.png',
                filterQuality: FilterQuality.high,
                height: 40,
              ),
            ),
          ],
        ),
        const Row(
          children: <Widget>[
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Acceso al Sistema"),
            ),
            Expanded(child: Divider()),
          ],
        ),
      ],
    );
  }
}
