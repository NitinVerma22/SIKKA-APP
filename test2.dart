import 'package:flutter/services.dart';
void test() {
  final Map<String, MethodChannel> channels = {
    'a' : const MethodChannel('a')..setMethodCallHandler((call) async {})
  };
}

