import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quantum_assignment/model/model.dart';
import 'package:quantum_assignment/services/notification.dart';
import 'package:quantum_assignment/utils/task_bloc.dart';
import 'package:intl/intl.dart';

class TaskDetailPage extends StatefulWidget {
  final Task? task;

  const TaskDetailPage({Key? key, this.task}) : super(key: key);

  @override
  _TaskDetailPageState createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TaskPriority _priority;
  DateTime? _dueDate;
  final NotificationService _notificationService = NotificationService();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    _priority = widget.task?.priority ?? TaskPriority.low;
    _dueDate = widget.task?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now,
      lastDate: DateTime(2101),
    );

    if (pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    final selectedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (selectedDateTime.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a future date and time')),
      );
      return;
    }

    setState(() {
      _dueDate = selectedDateTime;
    });
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      if (_dueDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a due date and time')),
        );
        return;
      }

      final now = DateTime.now();
      if (_dueDate!.isBefore(now)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Due date must be in the future')),
        );
        return;
      }

      final task = Task(
        id: widget.task?.id,
        title: _titleController.text,
        description: _descriptionController.text,
        priority: _priority,
        dueDate: _dueDate,
        createdAt: widget.task?.createdAt,
        isCompleted: widget.task?.isCompleted ?? false,
      );

      final notificationTime = _dueDate!.subtract(const Duration(minutes: 1));
      if (notificationTime.isAfter(DateTime.now())) {
        _notificationService.scheduleTaskNotification(
          id: task.id.hashCode,
          title: 'Task Reminder',
          body: 'Your task "${task.title}" is due in 1 minute!',
          scheduledDate: notificationTime,
        );
      } else {
        print('Notification time is in the past, skipping notification');
      }

      if (widget.task == null) {
        context.read<TaskBloc>().add(AddTask(task));
      } else {
        context.read<TaskBloc>().add(UpdateTask(task));
      }

      Navigator.pop(context);
    }
  }

  void _deleteTask() {
    if (widget.task != null) {
      context.read<TaskBloc>().add(DeleteTask(widget.task!.id));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Add Task' : 'Edit Task'),
        actions: widget.task != null
            ? [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _deleteTask,
                ),
              ]
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Task Title', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Enter task title'),
                validator: (value) => value == null || value.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Enter description'),
                maxLines: 3,
                validator: (value) => value == null || value.isEmpty ? 'Description is required' : null,
              ),
              const SizedBox(height: 16),
              const Text('Priority', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              DropdownButtonFormField<TaskPriority>(
                value: _priority,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: TaskPriority.values
                    .map((priority) => DropdownMenuItem(value: priority, child: Text(priority.toString().split('.').last)))
                    .toList(),
                onChanged: (value) => setState(() => _priority = value!),
              ),
              const SizedBox(height: 16),
              const Text('Select Date & Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              InkWell(
                onTap: _selectDueDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    _dueDate == null ? 'Select date and time' : DateFormat('EEEE, MMM d, yyyy – hh:mm a').format(_dueDate!),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveTask,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
