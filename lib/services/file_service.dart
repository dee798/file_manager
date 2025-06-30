import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

class FileService {
  static Future<String> getLocalPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  static Future<File> downloadPdf(String url, String fileName) async {
    final path = await getLocalPath();
    final file = File('$path/$fileName');
    if (await file.exists()) return file;
    await Dio().download(url, file.path);
    return file;
  }

  static Future<List<FileSystemEntity>> listDownloadedFiles() async {
    final dir = Directory(await getLocalPath());
    return dir.listSync().where((f) => f.path.endsWith('.pdf')).toList();
  }

  static Future<void> deleteFiles(List<FileSystemEntity> files) async {
    for (var file in files) {
      if (await File(file.path).exists()) {
        await File(file.path).delete();
      }
    }
  }
}