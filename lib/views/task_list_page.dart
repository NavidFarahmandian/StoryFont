// task_list_page.dart
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storyfont/views/task_form_bottomsheet.dart';
import 'package:storyfont/widgets/task_list_view.dart';
import '../main.dart';
import '../services/task_service.dart';

// TaskListPage is a StatefulWidget to manage the state of showing/hiding completed tasks
class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> with SingleTickerProviderStateMixin {
  // Tracks whether completed tasks should be shown
  bool _showCompletedTasks = true;
  // Animation controller for FAB scale animation
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize FAB animation
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fabAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the current user's ID from FirebaseAuth
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const Center(child: Text("Not logged in"));
    }

    // Initialize TaskService for task operations
    final taskService = TaskService();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "StoryFont Test",
          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        actions: [
          // Toggle theme with scale animation
          IconButton(
            icon: AnimatedScale(
              scale: themeNotifier.value == ThemeMode.dark ? 1.0 : 1.1,
              duration: const Duration(milliseconds: 200),
              child: Icon(themeNotifier.value == ThemeMode.dark
                  ? EvaIcons.sun
                  : EvaIcons.moon),
            ),
            onPressed: () {
              themeNotifier.value = themeNotifier.value == ThemeMode.dark
                  ? ThemeMode.light
                  : ThemeMode.dark;
            },
          ),
          // User profile avatar with logout functionality
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Logout"),
                    content: const Text("Do you want to logout?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.pop(context);
                        },
                        child: const Text("Logout"),
                      ),
                    ],
                  ),
                );
              },
              child: CircleAvatar(
                backgroundImage:
                FirebaseAuth.instance.currentUser?.photoURL != null
                    ? NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!)
                    : null,
                child: FirebaseAuth.instance.currentUser?.photoURL == null
                    ? const Icon(Icons.person)
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: TaskListView(
        userId: userId,
        taskService: taskService,
        showCompletedTasks: _showCompletedTasks,
        // Callback to toggle visibility of completed tasks
        onToggleCompletedTasks: () {
          setState(() {
            _showCompletedTasks = !_showCompletedTasks;
          });
        },
      ),
      // Floating action button with scale animation
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton(
          onPressed: () {
            _fabController.forward().then((_) => _fabController.reverse());
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) => const TaskFormBottomSheet(),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}