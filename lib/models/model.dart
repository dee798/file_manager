import 'package:hive/hive.dart';

part 'model.g.dart'; // run build_runner after this

@HiveType(typeId: 0)
class FileModel extends HiveObject {
  @HiveField(0)
  final String path;

  FileModel(this.path);
}
