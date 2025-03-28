import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:quantum_assignment/model/model.dart';
import 'package:quantum_assignment/utils/date_time_helper.dart';
import 'package:quantum_assignment/utils/task_bloc.dart';
import 'package:quantum_assignment/utils/task_detail.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({Key? key}) : super(key: key);

  @override
  _TaskListPageState createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  final TextEditingController _searchController = TextEditingController();
  TaskSortType _currentSortType = TaskSortType.createdAt;

  @override
  void initState() {
    super.initState();
    context.read<TaskBloc>().add(LoadTasks());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo List'),
        actions: [
          PopupMenuButton<TaskSortType>(
            icon: const Icon(Icons.sort),
            onSelected: (TaskSortType sortType) {
              setState(() {
                _currentSortType = sortType;
                context.read<TaskBloc>().add(SortTasks(sortType));
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<TaskSortType>>[
              const PopupMenuItem<TaskSortType>(
                value: TaskSortType.priority,
                child: Text('Sort by Priority'),
              ),
              const PopupMenuItem<TaskSortType>(
                value: TaskSortType.dueDate,
                child: Text('Sort by Due Date'),
              ),
              const PopupMenuItem<TaskSortType>(
                value: TaskSortType.createdAt,
                child: Text('Sort by Created Date'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 10, top: 30),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<TaskBloc>().add(LoadTasks());
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                context.read<TaskBloc>().add(SearchTasks(value));
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<TaskBloc, TaskState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.tasks.isEmpty) {
                  return const Center(
                    child: Text(
                      'No tasks found. Add a new task!',
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: state.tasks.length,
                  itemBuilder: (context, index) {
                    final task = state.tasks[index];
                    return TaskListItem(
                      task: task,
                      onTap: () => _navigateToTaskDetail(task),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToTaskDetail(null),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToTaskDetail(Task? task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailPage(task: task),
      ),
    );
  }
}

class TaskListItem extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;

  const TaskListItem({
    Key? key,
    required this.task,
    required this.onTap,
  }) : super(key: key);

  IconData _getPriorityIcon(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Icons.priority_high;
      case TaskPriority.medium:
        return Icons.trending_up;
      case TaskPriority.low:
      default:
        return Icons.low_priority;
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.low:
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10,10,10,0),
      child: InkWell(
        onTap: (){
          onTap();
        },
        child: Card(
          color: Colors.purple.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          task.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                       
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18, color: Colors.black54),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('dd MMM yyyy hh:mm a').format(task.dueDate ?? DateTime.now()),
                          style: const TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        const Spacer(),
                       
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 12,
                top: 50,
                child: Icon(
                  _getPriorityIcon(task.priority),
                  color: _getPriorityColor(task.priority),
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
