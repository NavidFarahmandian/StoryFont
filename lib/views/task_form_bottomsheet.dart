import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskFormBottomSheet extends StatefulWidget {
  final Task? existingTask;

  const TaskFormBottomSheet({super.key, this.existingTask});

  @override
  State<TaskFormBottomSheet> createState() => _TaskFormBottomSheetState();
}

class _TaskFormBottomSheetState extends State<TaskFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _dueDate;
  bool _isCompleted = false;
  bool _isLoading = false;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingTask != null) {
      _titleController.text = widget.existingTask!.title;
      _descController.text = widget.existingTask!.description;
      _dueDate = widget.existingTask!.dueDate;
      _isCompleted = widget.existingTask!.isCompleted;
    } else {
      _dueDate = DateTime.now().add(const Duration(days: 1));
    }

    _titleController.addListener(_validateForm);
    _descController.addListener(_validateForm);
  }

  void _validateForm() {
    final isValid = _titleController.text.trim().isNotEmpty &&
        _descController.text.trim().isNotEmpty;
    if (isValid != _isFormValid) {
      setState(() => _isFormValid = isValid);
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate() || _dueDate == null) return;

    setState(() => _isLoading = true);

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final task = Task(
      id: widget.existingTask?.id ?? '',
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      dueDate: _dueDate!,
      isCompleted: _isCompleted,
    );

    final taskService = TaskService();
    try {
      if (widget.existingTask == null) {
        await taskService.addTask(userId, task);
      } else {
        await taskService.updateTask(task);
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint("Error saving task: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme);

    return Theme(
      data: Theme.of(context).copyWith(textTheme: textTheme),
      child: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.existingTask == null ? "Add Task" : "Edit Task",
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: "Title",
                    border: OutlineInputBorder(),
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                  ),
                  validator: (value) =>
                  value == null || value.isEmpty ? "Title is required" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Description",
                    border: OutlineInputBorder(),
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Due: ${_dueDate?.toLocal().toString().split(' ')[0]}",
                        style: textTheme.bodyMedium,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today),
                      label: const Text("Pick Date"),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: _isFormValid && !_isLoading
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade400,
                  ),
                  child: TextButton(
                    onPressed:
                    (_isFormValid && !_isLoading) ? _saveTask : null,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                      "Save",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
