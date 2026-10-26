import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<List<dynamic>> getUsers() async {
  final response = await http.get(
    Uri.parse(
      'https://jsonplaceholder.typicode.com/user'
    ),
  );

  print(response.statusCode);
  print(response.body);

  if(response.statusCode == 200){
    return jsonDecode(response.body);
  }
  throw Exception('API Error');
}