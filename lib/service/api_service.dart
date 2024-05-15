// ignore_for_file: avoid_dynamic_calls

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;


Future<dynamic> makeRequest({
  required String url,
  required Map<String, dynamic> data,
  Map<String, String>? headers,
  String method = 'POST',
}) async {
  try {
    http.Response response;

    // Convertir data a JSON
    final body = json.encode(data);

    if (method.toUpperCase() == 'POST') {
      response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          ...?headers, // Spread operator para añadir cabeceras opcionales
        },
        body: body,
      );
    } else {
      // Implementa otros métodos si es necesario
      throw Exception('HTTP method $method not supported');
    }

    // Validar el status de la respuesta
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    }
    if (response.statusCode == 401) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to make request: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint("Este es un error que está llegando");
    debugPrint(e.toString()); // Convertir e a String
    throw Exception('Failed to make request: $e');
  }
}
