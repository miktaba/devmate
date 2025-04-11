// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_repository.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GithubRepositoryAdapter extends TypeAdapter<GithubRepository> {
  @override
  final int typeId = 3;

  @override
  GithubRepository read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GithubRepository(
      id: fields[0] as String,
      name: fields[1] as String,
      owner: fields[3] as String,
      ownerAvatarUrl: fields[4] as String,
      isPrivate: fields[5] as bool,
      starCount: fields[6] as int,
      forkCount: fields[7] as int,
      defaultBranch: fields[8] as String,
      updatedAt: fields[9] as DateTime,
      htmlUrl: fields[10] as String,
      hasIssues: fields[11] as bool,
      description: fields[2] as String?,
      language: fields[12] as String?,
      selected: fields[13] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, GithubRepository obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.owner)
      ..writeByte(4)
      ..write(obj.ownerAvatarUrl)
      ..writeByte(5)
      ..write(obj.isPrivate)
      ..writeByte(6)
      ..write(obj.starCount)
      ..writeByte(7)
      ..write(obj.forkCount)
      ..writeByte(8)
      ..write(obj.defaultBranch)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.htmlUrl)
      ..writeByte(11)
      ..write(obj.hasIssues)
      ..writeByte(12)
      ..write(obj.language)
      ..writeByte(13)
      ..write(obj.selected);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GithubRepositoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
