// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SkillAdapter extends TypeAdapter<Skill> {
  @override
  final int typeId = 1;

  @override
  Skill read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Skill(
      id: fields[0] as String,
      name: fields[1] as String,
      category: fields[2] as SkillCategory,
      isCustom: fields[3] as bool,
      level: fields[4] as int,
      description: fields[5] as String?,
      icon: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Skill obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.isCustom)
      ..writeByte(4)
      ..write(obj.level)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.icon);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkillAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SkillCategoryAdapter extends TypeAdapter<SkillCategory> {
  @override
  final int typeId = 2;

  @override
  SkillCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SkillCategory.language;
      case 1:
        return SkillCategory.framework;
      case 2:
        return SkillCategory.tool;
      case 3:
        return SkillCategory.database;
      case 4:
        return SkillCategory.other;
      default:
        return SkillCategory.language;
    }
  }

  @override
  void write(BinaryWriter writer, SkillCategory obj) {
    switch (obj) {
      case SkillCategory.language:
        writer.writeByte(0);
        break;
      case SkillCategory.framework:
        writer.writeByte(1);
        break;
      case SkillCategory.tool:
        writer.writeByte(2);
        break;
      case SkillCategory.database:
        writer.writeByte(3);
        break;
      case SkillCategory.other:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkillCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
