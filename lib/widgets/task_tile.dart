// task_tile.dart
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storyfont/views/task_form_bottomsheet.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';

// TaskTile displays an individual task with animated status changes
class TaskTile extends StatefulWidget {
  final Task task;
  final Animation<double> animation;

  const TaskTile({
    super.key,
    required this.task,
    required this.animation,
  });

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> with SingleTickerProviderStateMixin {
  // Animation controller for status change
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    // Trigger animation if task is completed
    if (widget.task.isCompleted) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(TaskTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Animate when completion status changes
    if (oldWidget.task.isCompleted != widget.task.isCompleted) {
      if (widget.task.isCompleted) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: widget.animation,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Define text style based on completion status
          final textStyle = GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.color
                ?.withOpacity(_opacityAnimation.value),
            decoration: widget.task.isCompleted ? TextDecoration.lineThrough : null,
          );

          final subtitleStyle = GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.color
                ?.withOpacity(_opacityAnimation.value),
            decoration: widget.task.isCompleted ? TextDecoration.lineThrough : null,
          );

          return ScaleTransition(
            scale: _scaleAnimation,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 36),
              titleAlignment: ListTileTitleAlignment.center,
              title: Text(widget.task.title, style: textStyle),
              subtitle: Text(
                "${widget.task.description}\nDue: ${widget.task.dueDate.toLocal().toString().split(' ')[0]}",
                style: subtitleStyle,
              ),
              isThreeLine: true,
              leading: InkWell(
                onTap: () async {
                  await TaskService()
                      .toggleStatus(widget.task.id, !widget.task.isCompleted);
                },
                // Use dynamic color for SVG to ensure visibility
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: SvgPicture.asset(
                    widget.task.isCompleted
                        ? "assets/images/check.svg"
                        : "assets/images/check_outline.svg",
                    key: ValueKey(widget.task.isCompleted),
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).colorScheme.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      EvaIcons.trashOutline,
                      color: Colors.red,
                      size: 22,
                    ),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Delete Task"),
                          content:
                          const Text("Are you sure you want to delete this task?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("Delete"),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        await TaskService().deleteTask(widget.task.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Task deleted")),
                        );
                      }
                    },
                  ),
                ],
              ),
              // Open task edit form on tap with scale animation
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) =>
                      TaskFormBottomSheet(existingTask: widget.task),
                );
              },
            ),
          );
        },
      ),
    );
  }
}