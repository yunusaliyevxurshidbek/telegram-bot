import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/birthday.dart';

class BirthdayApiService {
  final baseUrl = "https://portfolio-backend-ac0m.onrender.com/tgapi/birthdays/";

  // 📋 GET: Barcha tug‘ilgan kunlar
  Future<List<Birthday>> getBirthdays() async {
    final res = await http.get(Uri.parse(baseUrl));

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Birthday.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load birthdays');
    }
  }

  // ➕ POST: Yangi tug‘ilgan kun qo‘shish
  Future<void> addBirthday(String name, String date) async {
    final res = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"name": name, "date": date}),
    );
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('Failed to add birthday');
    }
  }

  // ❌ DELETE: Tug‘ilgan kunni o‘chirish
  Future<void> deleteBirthday(int id) async {
    final res = await http.delete(Uri.parse("$baseUrl$id/"));
    if (res.statusCode != 204) {
      throw Exception('Failed to delete birthday');
    }
  }

  // 📊 GET: Statistika
  Future<Map<String, dynamic>> getStats() async {
    final res = await http.get(Uri.parse("${baseUrl}stats/"));
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Failed to load stats');
    }
  }

  // 🎂 GET: Bugungi tug‘ilganlar
  Future<List<Birthday>> getToday() async {
    final res = await http.get(Uri.parse("${baseUrl}today/"));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Birthday.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load today birthdays');
    }
  }
}
