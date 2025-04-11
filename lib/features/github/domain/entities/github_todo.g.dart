// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_todo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GithubTodoAdapter extends TypeAdapter<GithubTodo> {
  @override
  final int typeId = 6;

  @override
  GithubTodo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GithubTodo(
      id: fields[0] as String,
      repositoryId: fields[1] as String,
      title: fields[2] as String,
      description: fields[3] as String,
      createdAt: fields[5] as DateTime,
      completed: fields[4] as bool,
      dueDate: fields[6] as DateTime?,
      priority: fields[7] as TodoPriority,
      category: fields[8] as TodoCategory,
      relatedFilePath: fields[9] as String?,
      issueNumber: fields[10] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, GithubTodo obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.repositoryId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.completed)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.dueDate)
      ..writeByte(7)
      ..write(obj.priority)
      ..writeByte(8)
      ..write(obj.category)
      ..writeByte(9)
      ..write(obj.relatedFilePath)
      ..writeByte(10)
      ..write(obj.issueNumber);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GithubTodoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TodoPriorityAdapter extends TypeAdapter<TodoPriority> {
  @override
  final int typeId = 4;

  @override
  TodoPriority read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TodoPriority.low;
      case 1:
        return TodoPriority.medium;
      case 2:
        return TodoPriority.high;
      default:
        return TodoPriority.low;
    }
  }

  @override
  void write(BinaryWriter writer, TodoPriority obj) {
    switch (obj) {
      case TodoPriority.low:
        writer.writeByte(0);
        break;
      case TodoPriority.medium:
        writer.writeByte(1);
        break;
      case TodoPriority.high:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodoPriorityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TodoCategoryAdapter extends TypeAdapter<TodoCategory> {
  @override
  final int typeId = 5;

  @override
  TodoCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TodoCategory.feature;
      case 1:
        return TodoCategory.bug;
      case 2:
        return TodoCategory.improvement;
      case 3:
        return TodoCategory.documentation;
      case 4:
        return TodoCategory.other;
      default:
        return TodoCategory.feature;
    }
  }

  @override
  void write(BinaryWriter writer, TodoCategory obj) {
    switch (obj) {
      case TodoCategory.feature:
        writer.writeByte(0);
        break;
      case TodoCategory.bug:
        writer.writeByte(1);
        break;
      case TodoCategory.improvement:
        writer.writeByte(2);
        break;
      case TodoCategory.documentation:
        writer.writeByte(3);
        break;
      case TodoCategory.other:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodoCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
