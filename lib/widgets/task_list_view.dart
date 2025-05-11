// task_list_view.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import 'task_tile.dart';

// TaskListView displays a list of tasks grouped by due date with animations
class TaskListView extends StatefulWidget {
  final String userId;
  final TaskService taskService;
  final bool showCompletedTasks;
  final VoidCallback onToggleCompletedTasks;

  const TaskListView({
    super.key,
    required this.userId,
    required this.taskService,
    required this.showCompletedTasks,
    required this.onToggleCompletedTasks,
  });

  @override
  State<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView> with SingleTickerProviderStateMixin {
  // Animation controller for list transitions
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Global key for AnimatedList to manage insertions/removals
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<Task> _tasks = [];
  int _itemCount = 1; // Initial count includes toggle button

  @override
  void initState() {
    super.initState();
    // Initialize animations for list transitions
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(TaskListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Restart animation when showCompletedTasks changes
    if (oldWidget.showCompletedTasks != widget.showCompletedTasks) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Task>>(
      stream: widget.taskService.streamTasks(widget.userId),
      builder: (context, snapshot) {
        // Show loading indicator while waiting for data
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // Display error message if data fetch fails
        if (snapshot.hasError) {
          debugPrint("${snapshot.error}");
          return const Center(child: Text('Error: Try again later.'));
        }
        // Display message if no tasks exist
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          _itemCount = 1; // Only toggle button
          return Center(
            child: Text(
              "No tasks yet",
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          );
        }

        // Filter tasks based on completion status
        final tasks = snapshot.data!
            .where((task) => widget.showCompletedTasks || !task.isCompleted)
            .toList();
        if (tasks.isEmpty && !widget.showCompletedTasks) {
          _itemCount = 1; // Only toggle button
          return Center(
            child: Text(
              "No incomplete tasks",
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          );
        }

        // Update local task list and animate changes
        _updateTaskList(tasks);

        // Group tasks by due date
        final groupedTasks = _groupTasksByDueDate(_tasks);

        // Update item count for AnimatedList
        _itemCount = groupedTasks.length + 1;

        // Build the animated list with slide and fade transitions
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: AnimatedList(
              key: _listKey,
              initialItemCount: _itemCount,
              itemBuilder: (context, index, animation) {
                // Add toggle button before the first group (Today)
                if (index == 0) {
                  return ScaleTransition(
                    scale: animation,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: TextButton(
                        onPressed: widget.onToggleCompletedTasks,
                        child: Text(
                          widget.showCompletedTasks
                              ? "Hide Completed Tasks"
                              : "Show Completed Tasks",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                // Defensive check to prevent index out of range
                if (index - 1 >= groupedTasks.length) {
                  return const SizedBox.shrink();
                }

                // Display task groups
                final dateKey = groupedTasks.keys.elementAt(index - 1);
                final tasksForDate = groupedTasks[dateKey]!;
                return SizeTransition(
                  sizeFactor: animation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Display header for the date group
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          dateKey,
                          style: GoogleFonts.poppins(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                      // Display task tiles for this date
                      ...tasksForDate.map((task) => TaskTile(
                        key: ValueKey(task.id),
                        task: task,
                        animation: animation,
                      )),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // Updates the task list and animates insertions/removals
  void _updateTaskList(List<Task> newTasks) {
    // Store old tasks for comparison
    final oldTasks = List<Task>.from(_tasks);
    // Update current tasks
    _tasks = List.from(newTasks);

    // Get task IDs
    final oldIds = oldTasks.map((t) => t.id).toSet();
    final newIds = newTasks.map((t) => t.id).toSet();

    // Identify added and removed tasks
    final addedIds = newIds.difference(oldIds).toList();
    final removedIds = oldIds.difference(newIds).toList();

    // Handle removals (e.g., deleted tasks or completed tasks when hiding completed)
    for (var id in removedIds) {
      // Find the task in the current _tasks list
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        // Task is still in _tasks, remove it
        final removedTask = _tasks[index];
        _tasks.removeAt(index);
        _listKey.currentState?.removeItem(
          index + 1, // +1 for toggle button
              (context, animation) => SizeTransition(
            sizeFactor: animation,
            child: TaskTile(task: removedTask, animation: animation),
          ),
          duration: const Duration(milliseconds: 300),
        );
      } else {
        // Task might be in oldTasks (e.g., completed and filtered out)
        final oldIndex = oldTasks.indexWhere((t) => t.id == id);
        if (oldIndex != -1) {
          // Find the group index in the AnimatedList
          final groupedTasks = _groupTasksByDueDate(oldTasks);
          int listIndex = 1; // Start after toggle button
          for (var key in groupedTasks.keys) {
            final tasksForDate = groupedTasks[key]!;
            final taskIndex = tasksForDate.indexWhere((t) => t.id == id);
            if (taskIndex != -1) {
              _listKey.currentState?.removeItem(
                listIndex,
                    (context, animation) => SizeTransition(
                  sizeFactor: animation,
                  child: TaskTile(task: oldTasks[oldIndex], animation: animation),
                ),
                duration: const Duration(milliseconds: 300),
              );
              break;
            }
            listIndex += 1; // Increment for each group
          }
        }
      }
    }

    // Handle additions (e.g., new tasks)
    for (var id in addedIds) {
      final task = newTasks.firstWhere((t) => t.id == id);
      final index = _tasks.indexOf(task);
      if (index != -1) {
        // Insert item into AnimatedList
        _listKey.currentState?.insertItem(
          index + 1, // +1 for toggle button
          duration: const Duration(milliseconds: 300),
        );
      }
    }

    // Schedule item count update post-build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final groupedTasks = _groupTasksByDueDate(_tasks);
      final newItemCount = groupedTasks.length + 1;
      if (_itemCount != newItemCount) {
        setState(() {
          _itemCount = newItemCount;
        });
      }
    });
  }

  // Groups tasks by due date, labeling as "Today," "Tomorrow," or formatted date
  Map<String, List<Task>> _groupTasksByDueDate(List<Task> tasks) {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final dateFormat = DateFormat('MMMM d, yyyy');

    // Initialize map to store grouped tasks
    final groupedTasks = <String, List<Task>>{};

    for (var task in tasks) {
      final dueDate = task.dueDate.toLocal();
      String key;

      // Determine the display label for the due date
      if (dueDate.year == today.year &&
          dueDate.month == today.month &&
          dueDate.day == today.day) {
        key = "Today";
      } else if (dueDate.year == tomorrow.year &&
          dueDate.month == tomorrow.month &&
          dueDate.day == tomorrow.day) {
        key = "Tomorrow";
      } else {
        key = dateFormat.format(dueDate);
      }

      // Add task to the corresponding date group
      groupedTasks.putIfAbsent(key, () => []).add(task);
    }

    // Sort tasks within each group by due date/time
    groupedTasks.forEach((key, taskList) {
      taskList.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    });

    // Create a sorted map by date for consistent display order
    final sortedGroupedTasks = <String, List<Task>>{};
    final sortedKeys = groupedTasks.keys.toList()
      ..sort((a, b) {
        if (a == "Today") return -2;
        if (b == "Today") return 2;
        if (a == "Tomorrow") return -1;
        if (b == "Tomorrow") return 1;
        final dateA = dateFormat.parse(a);
        final dateB = dateFormat.parse(b);
        return dateA.compareTo(dateB);
      });

    for (var key in sortedKeys) {
      sortedGroupedTasks[key] = groupedTasks[key]!;
    }

    return sortedGroupedTasks;
  }
}