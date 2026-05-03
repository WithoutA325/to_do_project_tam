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
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
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
  String selectedFilter = "wszystkie";

  Future<void> _openAddTaskScreen() async {
    final Task? newTask = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AddTaskScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(animation);
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );

    if (newTask != null) {
      setState(() {
        TaskRepository.tasks.add(newTask);
      });
    }
  }

  Future<void> _openEditTaskScreen(int index, Task task) async {
    final Task? updatedTask = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditTaskScreen(task: task)),
    );

    if (updatedTask != null) {
      setState(() {
        int originalIndex = TaskRepository.tasks.indexOf(task);
        if (originalIndex != -1) {
          TaskRepository.tasks[originalIndex] = updatedTask;
        }
      });
    }
  }

  void _deleteAllTasks() {
    if (TaskRepository.tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lista jest już pusta.")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Potwierdzenie"),
        content: const Text("Czy na pewno chcesz usunąć wszystkie zadania?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Anuluj"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                TaskRepository.tasks.clear();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Usunięto wszystkie zadania")),
              );
            },
            child: const Text("Usuń", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Task> filteredTasks = TaskRepository.tasks;
    if (selectedFilter == "wykonane") {
      filteredTasks = TaskRepository.tasks.where((task) => task.done).toList();
    } else if (selectedFilter == "do zrobienia") {
      filteredTasks = TaskRepository.tasks.where((task) => !task.done).toList();
    }

    int doneTasksCount = TaskRepository.tasks.where((task) => task.done).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("KrakFlow"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _deleteAllTasks,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Masz dziś ${TaskRepository.tasks.length} zadań (wykonane: $doneTasksCount)",
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _filterButton("wszystkie"),
                  _filterButton("do zrobienia"),
                  _filterButton("wykonane"),
                ],
              ),

              const SizedBox(height: 16),
              const Text(
                "Dzisiejsze zadania",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: ListView.builder(
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    final task = filteredTasks[index];

                    return Dismissible(
                      key: ValueKey(task.title + task.deadline),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        setState(() {
                          TaskRepository.tasks.remove(task);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Zadanie '${task.title}' usunięte")),
                        );
                      },
                      child: TaskCard(
                        title: task.title,
                        subtitle: "termin: ${task.deadline} | priorytet: ${task.priority}",
                        done: task.done,
                        onChanged: (value) {
                          setState(() {
                            int idx = TaskRepository.tasks.indexOf(task);
                            TaskRepository.tasks[idx] = Task(
                              title: task.title,
                              deadline: task.deadline,
                              done: value ?? false,
                              priority: task.priority,
                            );
                          });
                        },
                        onTap: () => _openEditTaskScreen(index, task),
                      ),
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

  Widget _filterButton(String filter) {
    final bool isActive = selectedFilter == filter;
    return TextButton(
      onPressed: () => setState(() => selectedFilter = filter),
      style: TextButton.styleFrom(
        backgroundColor: isActive ? Colors.blue.withValues(alpha: 0.1) : null,
      ),
      child: Text(
        filter.toUpperCase(),
        style: TextStyle(
          color: isActive ? Colors.blue : Colors.grey,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
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
        const SnackBar(content: Text("Uzupełnij wszystkie pola.")),
      );
      return;
    }

    Navigator.pop(context, Task(title: title, deadline: deadline, done: false, priority: priority));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nowe zadanie")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: "Tytuł zadania", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: deadlineController, decoration: const InputDecoration(labelText: "Termin", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: priorityController, decoration: const InputDecoration(labelText: "Priorytet", border: OutlineInputBorder())),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saveTask, child: const Text("Zapisz"))),
          ],
        ),
      ),
    );
  }
}

class EditTaskScreen extends StatefulWidget {
  final Task task;
  const EditTaskScreen({super.key, required this.task});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  late TextEditingController titleController;
  late TextEditingController deadlineController;
  late TextEditingController priorityController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.task.title);
    deadlineController = TextEditingController(text: widget.task.deadline);
    priorityController = TextEditingController(text: widget.task.priority);
  }

  @override
  void dispose() {
    titleController.dispose();
    deadlineController.dispose();
    priorityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edytuj zadanie")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: "Tytuł", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: deadlineController, decoration: const InputDecoration(labelText: "Termin", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: priorityController, decoration: const InputDecoration(labelText: "Priorytet", border: OutlineInputBorder())),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, Task(
                    title: titleController.text,
                    deadline: deadlineController.text,
                    done: widget.task.done,
                    priority: priorityController.text,
                  ));
                },
                child: const Text("Zapisz zmiany"),
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
  final bool done;
  final ValueChanged<bool?>? onChanged;
  final VoidCallback? onTap;

  const TaskCard({super.key, required this.title, required this.subtitle, required this.done, this.onChanged, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: Checkbox(value: done, onChanged: onChanged),
        title: Text(
          title,
          style: TextStyle(
            decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
            color: done ? Colors.grey : Colors.black,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}