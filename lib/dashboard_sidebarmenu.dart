import 'dart:convert';

import 'package:alerta_global/system_verification.dart';
import 'package:flutter/material.dart';

class NavBar extends StatelessWidget {
  
  static String _userName ="";
  static String _email ="";
  static String _image ="";

  String get userName => _userName;
  String get email => _email;
  String get image => _image;

  set userName(String value) {
    if (value.isNotEmpty) {
      _userName = value;
    }
  }
  set email(String value) {
    if (value.isNotEmpty) {
      _email = value;
    }
  }
  set image(String value) {
    if (value.isNotEmpty) {
      _image = value;
    }
  }

  const NavBar({super.key});

  @override
  Widget build(BuildContext context)  {
    
    return Drawer (
      child: ListView(
        // Remove padding
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader (
            accountName: Text('Bienvenido(a): ${UserPreferences.getName() ?? "Nombre no disponible"}'),
            accountEmail: Text(UserPreferences.getEmail()?? "Sin Email"),
             decoration: const BoxDecoration(
              color: Colors.white,
            ),

            currentAccountPicture: CircleAvatar(
              child: ClipOval(
                  child: Image.memory(base64Decode(UserPreferences.getImg() ?? "Nombre no disponible"),
                  fit: BoxFit.cover,
                  width: 90,
                  height: 90,
                ),
              ),
            ),
          ),
          
          ListTile(
            leading: const Icon(Icons.my_location),
            title: const Text('Página Principal'),
            onTap: () => Navigator.pushNamed(context, '/dashboard'),
          ),
          // ListTile(
          //   leading: const Icon(Icons.settings_remote),
          //   title: const Text('Mis Dispositivos BlueTooth'),
          //   onTap: () => Navigator.pushNamed(context, '/device'),
          // ),
          
          
          
          const Divider(),
          /*ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () => null,
          ),
          ListTile(
            leading: Icon(Icons.description),
            title: Text('Policies'),
            onTap: () => null,
          ),
          Divider(),
          ListTile(
            title: Text('Exit'),
            leading: Icon(Icons.exit_to_app),
            onTap: () => null,
          ),*/
        ],
      ),
    );
  }
}
