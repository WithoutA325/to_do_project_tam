import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'task.dart';
import 'task_local_database.dart';
import 'task_sync_service.dart';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox("tasks");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        useMaterial3: true,
      ),
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
  late Future<List<Task>> tasksFuture;

  String selectedFilter = "wszystkie";

  @override
  void initState() {
    super.initState();

    tasksFuture = loadTasks();
  }


  Future<List<Task>> loadTasks() async {

    await TaskSyncService
        .loadInitialDataIfNeeded();

    return TaskLocalDatabase.getTasks();
  }

  Future<void> _openAddTaskScreen() async {
    final Task? newTask = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (
            context,
            animation,
            secondaryAnimation,
            ) =>
        const AddTaskScreen(),
        transitionsBuilder: (
            context,
            animation,
            secondaryAnimation,
            child,
            ) {
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

      await TaskLocalDatabase.addTask(newTask);

      setState(() {
        tasksFuture = loadTasks();
      });
    }
  }

  Future<void> _openEditTaskScreen(
      int index,
      Task task,
      ) async {
    final Task? updatedTask = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditTaskScreen(task: task),
      ),
    );

    if (updatedTask != null) {

      await TaskLocalDatabase
          .updateTask(updatedTask);

      setState(() {
        tasksFuture = loadTasks();
      });
    }
  }

  void _deleteAllTasks() {
    if (TaskLocalDatabase.getTasks().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lista jest już pusta."),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Potwierdzenie"),
        content: const Text(
          "Czy na pewno chcesz usunąć wszystkie zadania?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Anuluj"),
          ),
          TextButton(
            onPressed: () async {
                await TaskLocalDatabase
                    .deleteAllTasks();

                setState(() {
                  tasksFuture = loadTasks();
                });

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                  Text("Usunięto wszystkie zadania"),
                ),
              );
            },
            child: const Text(
              "Usuń",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("KrakFlow"),
        backgroundColor: Colors.pinkAccent,
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
          child: FutureBuilder<List<Task>>(
            future: tasksFuture,
            builder: (context, snapshot) {

              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Błąd: ${snapshot.error}",
                    style: const TextStyle(fontSize: 18),
                  ),
                );
              }

              final apiTasks = snapshot.data ?? [];

              final doneTasksCount = apiTasks
                  .where((task) => task.done)
                  .length;

              List<Task> filteredTasks = apiTasks;

              if (selectedFilter == "wykonane") {
                filteredTasks = apiTasks
                    .where((task) => task.done)
                    .toList();
              } else if (selectedFilter ==
                  "do zrobienia") {
                filteredTasks = apiTasks
                    .where((task) => !task.done)
                    .toList();
              }

              return Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    "Masz dziś ${apiTasks.length} zadań "
                        "(wykonane: $doneTasksCount)",
                    style: const TextStyle(fontSize: 18),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceEvenly,
                    children: [
                      _filterButton("wszystkie"),
                      _filterButton("do zrobienia"),
                      _filterButton("wykonane"),
                    ],
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
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task =
                        filteredTasks[index];

                        return Dismissible(
                          key: ValueKey(
                            task.title + task.deadline,
                          ),

                          direction:
                          DismissDirection
                              .endToStart,

                          background: Container(
                            color: Colors.red,
                            alignment:
                            Alignment.centerRight,
                            padding:
                            const EdgeInsets.only(
                              right: 20,
                            ),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),

                          onDismissed: (direction) async {
                              await TaskLocalDatabase
                                  .deleteTask(task.id);

                              setState(() {
                                tasksFuture = loadTasks();
                            });

                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Zadanie '${task.title}' usunięte",
                                ),
                              ),
                            );
                          },

                          child: TaskCard(
                            title: task.title,
                            subtitle:
                            "termin: ${task.deadline} | priorytet: ${task.priority}",
                            done: task.done,
                            onChanged: (value) async {

                              final updatedTask = Task(
                                id: task.id,
                                title: task.title,
                                deadline: task.deadline,
                                priority: task.priority,
                                done: value ?? false,
                              );

                              await TaskLocalDatabase
                                  .updateTask(updatedTask);

                              setState(() {
                                tasksFuture = loadTasks();
                              });
                            },
                            onTap: () =>
                                _openEditTaskScreen(
                                  index,
                                  task,
                                ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
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
    final bool isActive =
        selectedFilter == filter;

    return TextButton(
      onPressed: () =>
          setState(() => selectedFilter = filter),
      style: TextButton.styleFrom(
        backgroundColor: isActive
            ? Colors.purple.withValues(alpha: 0.1)
            : null,
      ),
      child: Text(
        filter.toUpperCase(),
        style: TextStyle(
          color:
          isActive ? Colors.purple : Colors.grey,
          fontWeight: isActive
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
    );
  }
}

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() =>
      _AddTaskScreenState();
}

class _AddTaskScreenState
    extends State<AddTaskScreen> {
  final TextEditingController titleController =
  TextEditingController();

  final TextEditingController
  deadlineController =
  TextEditingController();

  final TextEditingController
  priorityController =
  TextEditingController();

  @override
  void dispose() {
    titleController.dispose();
    deadlineController.dispose();
    priorityController.dispose();
    super.dispose();
  }

  void _saveTask() {
    final title = titleController.text.trim();

    final deadline =
    deadlineController.text.trim();

    final priority =
    priorityController.text.trim();

    if (title.isEmpty ||
        deadline.isEmpty ||
        priority.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Uzupełnij wszystkie pola.",
          ),
        ),
      );

      return;
    }

    Navigator.pop(
      context,
      Task(
        id: Random().nextInt(1000000),
        title: title,
        deadline: deadline,
        done: false,
        priority: priority,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
      AppBar(title: const Text("Nowe zadanie")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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

class EditTaskScreen extends StatefulWidget {
  final Task task;

  const EditTaskScreen({
    super.key,
    required this.task,
  });

  @override
  State<EditTaskScreen> createState() =>
      _EditTaskScreenState();
}

class _EditTaskScreenState
    extends State<EditTaskScreen> {
  late TextEditingController titleController;

  late TextEditingController
  deadlineController;

  late TextEditingController
  priorityController;

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(
      text: widget.task.title,
    );

    deadlineController = TextEditingController(
      text: widget.task.deadline,
    );

    priorityController = TextEditingController(
      text: widget.task.priority,
    );
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
      appBar:
      AppBar(title: const Text("Edytuj zadanie")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Tytuł",
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
                onPressed: () {
                  Navigator.pop(
                    context,
                    Task(
                      id: widget.task.id,
                      title: titleController.text,
                      deadline:
                      deadlineController.text,
                      done: widget.task.done,
                      priority:
                      priorityController.text,
                    ),
                  );
                },
                child:
                const Text("Zapisz zmiany"),
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

  const TaskCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.done,
    this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: Checkbox(
          value: done,
          onChanged: onChanged,
        ),
        title: Text(
          title,
          style: TextStyle(
            decoration: done
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            color:
            done ? Colors.grey : Colors.black,
          ),
        ),
        subtitle: Text(subtitle),
        trailing:
        const Icon(Icons.chevron_right),
      ),
    );
  }
}