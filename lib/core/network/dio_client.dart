import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  final http.Client _client;
  final String _baseUrl;

  ApiClient({http.Client? client})
      : _client = client ?? http.Client(),
        _baseUrl = dotenv.env['API_BASE_URL'] ?? '';

  Map<String, String> _headers({String? token}) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<http.Response> get(String path, {String? token}) {
    return _client.get(
      Uri.parse('$_baseUrl$path'),
      headers: _headers(token: token),
    );
  }

  Future<http.Response> post(String path, String body, {String? token}) {
    return _client.post(
      Uri.parse('$_baseUrl$path'),
      headers: _headers(token: token),
      body: body,
    );
  }

  void dispose() => _client.close();
}
