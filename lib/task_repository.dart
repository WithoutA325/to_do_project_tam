class Task {
  final String title;
  final String deadline;
  final bool done;
  final String priority;

  const Task({
    required this.title,
    required this.deadline,
    required this.done,
    required this.priority,
  });
}

class TaskRepository {
  static List<Task> tasks = [
    Task(
      title:"Prezentacją na TAM",
      deadline:"jutro",
      done: false,
      priority:"wysoki",
    ),
    Task(
      title:"Raport z labów na AISO",
      deadline:"dzisiaj",
      done: true,
      priority:"wysoki",
    ),
    Task(
      title:"Nauka na kolokwium z matematyki",
      deadline:"za 7 dni",
      done: false,
      priority: "niski",
    ),
    Task(
      title:"Przeczytać dokumentację do projektu z Fluttera",
      deadline: "za 3 dni",
      done: false,
      priority: "niski",
    ),
  ];
}