import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskViewModel extends ChangeNotifier {
  final TaskService _taskService = TaskService();
  List<Task> tasks = [];
  bool isLoading = false;

  Future<void> loadTasks() async {
    isLoading = true;
    notifyListeners();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      tasks = await _taskService.fetchTasks(userId);
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> toggleTaskStatus(Task task) async {
    final newStatus = !task.isCompleted;
    await _taskService.toggleStatus(task.id, newStatus);
    await loadTasks();
  }
}
