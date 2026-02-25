import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/base_url.dart';

class ApiService {
  static Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body) async {

    final url = Uri.parse(
        "${AppConfig.baseUrl}?path=$path");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> get(String path) async {

    final url = Uri.parse(
        "${AppConfig.baseUrl}?path=$path");

    final response = await http.get(url);

    return jsonDecode(response.body);
  }
}