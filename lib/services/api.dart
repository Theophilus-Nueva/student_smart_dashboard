import 'package:http/http.dart' as http;
import 'dart:convert';

Future<List<dynamic>> getUsers() async {
  final response = await http.get(
    Uri.parse(
      'https://jsonplaceholder.typicode.com/users'
    ),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body) as List<dynamic>;
  }
  throw Exception('API Error');
}
