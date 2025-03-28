import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:quantum_assignment/utils/task_repo.dart';
import '../model/model.dart';

// Events
abstract class TaskEvent extends Equatable {
  const TaskEvent();
  
  @override
  List<Object> get props => [];
}

class LoadTasks extends TaskEvent {}
class AddTask extends TaskEvent {
  final Task task;
  const AddTask(this.task);

  @override
  List<Object> get props => [task];
}

class UpdateTask extends TaskEvent {
  final Task task;
  const UpdateTask(this.task);

  @override
  List<Object> get props => [task];
}

class DeleteTask extends TaskEvent {
  final String taskId;
  const DeleteTask(this.taskId);

  @override
  List<Object> get props => [taskId];
}

class SearchTasks extends TaskEvent {
  final String query;
  const SearchTasks(this.query);

  @override
  List<Object> get props => [query];
}

class SortTasks extends TaskEvent {
  final TaskSortType sortType;
  const SortTasks(this.sortType);

  @override
  List<Object> get props => [sortType];
}

enum TaskSortType {
  priority,
  dueDate,
  createdAt
}

// States
class TaskState extends Equatable {
  final List<Task> tasks;
  final bool isLoading;
  final String? error;

  const TaskState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
  });

  TaskState copyWith({
    List<Task>? tasks,
    bool? isLoading,
    String? error,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [tasks, isLoading, error];
}

// BLoC
class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository _repository;

  TaskBloc(this._repository) : super(const TaskState()) {
    on<LoadTasks>(_onLoadTasks);
    on<AddTask>(_onAddTask);
    on<UpdateTask>(_onUpdateTask);
    on<DeleteTask>(_onDeleteTask);
    on<SearchTasks>(_onSearchTasks);
    on<SortTasks>(_onSortTasks);
  }

  Future<void> _onLoadTasks(LoadTasks event, Emitter<TaskState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final tasks = await _repository.getTasks();
      emit(state.copyWith(tasks: tasks, isLoading: false));
    } catch (e) {
      emit(state.copyWith(
        error: 'Failed to load tasks',
        isLoading: false,
      ));
    }
  }

  Future<void> _onAddTask(AddTask event, Emitter<TaskState> emit) async {
    try {
     
      await _repository.addTask(event.task);
      add(LoadTasks());
    } catch (e) {
      emit(state.copyWith(error: 'Failed to add task'));
    }
  }

  Future<void> _onUpdateTask(UpdateTask event, Emitter<TaskState> emit) async {
    try {
      await _repository.updateTask(event.task);
      add(LoadTasks());
    } catch (e) {
      emit(state.copyWith(error: 'Failed to update task'));
    }
  }

  Future<void> _onDeleteTask(DeleteTask event, Emitter<TaskState> emit) async {
    try {
      await _repository.deleteTask(event.taskId);
      add(LoadTasks());
    } catch (e) {
      emit(state.copyWith(error: 'Failed to delete task'));
    }
  }

  Future<void> _onSearchTasks(SearchTasks event, Emitter<TaskState> emit) async {
    final tasks = await _repository.getTasks();
    final filteredTasks = tasks.where((task) => 
      task.title.toLowerCase().contains(event.query.toLowerCase()) ||
      task.description.toLowerCase().contains(event.query.toLowerCase())
    ).toList();
    emit(state.copyWith(tasks: filteredTasks));
  }

  Future<void> _onSortTasks(SortTasks event, Emitter<TaskState> emit) async {
    final tasks = [...state.tasks];
    switch (event.sortType) {
      case TaskSortType.priority:
        tasks.sort((a, b) => b.priority.index.compareTo(a.priority.index));
        break;
      case TaskSortType.dueDate:
        tasks.sort((a, b) {
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case TaskSortType.createdAt:
        tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    emit(state.copyWith(tasks: tasks));
  }
}