import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'task.dart';

class TaskApiService {
  static const String baseUrl = "https://dummyjson.com";

  static Future<List<Task>> fetchTasks() async {
    final response = await http.get(
      Uri.parse("$baseUrl/todos"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final List todos = data["todos"];

      final random = Random();

      final priorities = ["niski", "średni", "wysoki"];
      final deadlines = [
        "dzisiaj",
        "jutro",
        "za 3 dni",
        "za tydzień"
      ];

      return todos.map((todo) {
        return Task(
          id: todo["id"],
          title: todo["todo"],
          deadline: deadlines[random.nextInt(deadlines.length)],
          done: todo["completed"],
          priority: priorities[random.nextInt(priorities.length)],
        );
      }).toList();
    } else {
      throw Exception("Błąd pobierania danych z API");
    }
  }
}