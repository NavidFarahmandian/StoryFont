import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import '../models/task_model.dart';

class TaskService {
  final _firestore = FirebaseFirestore.instance;
  final _collection = 'tasks';

  Future<List<Task>> fetchTasks(String userId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('dueDate')
        .get();
    return snapshot.docs
        .map((doc) => Task.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<void> addTask(String userId, Task task) async {
    await _firestore.collection(_collection).add({
      ...task.toJson(),
      'userId': userId,
    });
  }


  Stream<List<Task>> streamTasks(String userId) {
    return FirebaseFirestore.instance
        .collectionGroup('tasks')
        .where('userId', isEqualTo: userId)
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) {
      final tasks = snapshot.docs.map((doc) => Task.fromJson(doc.data(), doc.id)).toList();
      debugPrint("STREAM TASK COUNT: ${tasks.length}");
      return tasks;
    });
  }




  Future<void> toggleStatus(String taskId, bool isCompleted) async {
    await _firestore.collection(_collection).doc(taskId).update({
      'isCompleted': isCompleted,
    });
  }

  Future<void> deleteTask(String taskId) async {
    await _firestore.collection(_collection).doc(taskId).delete();
  }

  Future<void> updateTask(Task task) async {
    await _firestore.collection(_collection).doc(task.id).update(task.toJson());
  }

}
