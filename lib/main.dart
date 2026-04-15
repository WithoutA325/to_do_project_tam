import 'package:flutter/material.dart';
import 'task_repository.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _openAddTaskScreen() async {
    final Task? newTask = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
        const AddTaskScreen(),

        transitionsBuilder: (context, animation, secondaryAnimation, child) {

          final offsetAnimation = Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(animation);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    );


    if (newTask != null) {
      setState(() {
        TaskRepository.tasks.add(newTask);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = TaskRepository.tasks;
    final doneTasks = tasks.where((task) => task.done).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("KrakFlow"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Masz dziś ${tasks.length} zadań (wykonane: $doneTasks)",
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              const Text(
                "Dzisiejsze zadania",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];

                    return TaskCard(
                      title: task.title,
                      subtitle:
                      "termin: ${task.deadline} | priorytet: ${task.priority}",
                      icon: task.done
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddTaskScreen,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController deadlineController = TextEditingController();
  final TextEditingController priorityController = TextEditingController();

  @override
  void dispose() {
    titleController.dispose();
    deadlineController.dispose();
    priorityController.dispose();
    super.dispose();
  }

  void _saveTask() {
    final title = titleController.text.trim();
    final deadline = deadlineController.text.trim();
    final priority = priorityController.text.trim();

    if (title.isEmpty || deadline.isEmpty || priority.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Uzupełnij wszystkie pola."),
        ),
      );
      return;
    }

    final newTask = Task(
      title: title,
      deadline: deadline,
      done: false,
      priority: priority,
    );

    Navigator.pop(context, newTask);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nowe zadanie"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Tytuł zadania",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: deadlineController,
              decoration: const InputDecoration(
                labelText: "Termin",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priorityController,
              decoration: const InputDecoration(
                labelText: "Priorytet",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveTask,
                child: const Text("Zapisz"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const TaskCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}