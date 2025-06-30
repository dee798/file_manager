import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import '../services/file_service.dart';


class FileController extends GetxController {

  List<File> get pdfFiles => filteredFiles
      .where((file) => file.path.toLowerCase().endsWith('.pdf'))
      .map((e) => File(e.path))
      .toList();

  List<File> get docFiles => filteredFiles
      .where((file) =>
  file.path.toLowerCase().endsWith('.doc') ||
      file.path.toLowerCase().endsWith('.docx'))
      .map((e) => File(e.path))
      .toList();

  List<File> get imageFiles => filteredFiles
      .where((file) {
    final ext = file.path.toLowerCase();
    return ext.endsWith('.jpg') ||
        ext.endsWith('.jpeg') ||
        ext.endsWith('.png') ||
        ext.endsWith('.gif');
  })
      .map((e) => File(e.path))
      .toList();

  List<File> get downloadFiles => filteredFiles
      .where((file) => file.path.toLowerCase().contains('download'))
      .map((e) => File(e.path))
      .toList();

  RxList<FileSystemEntity> allFiles = <FileSystemEntity>[].obs;
  RxList<FileSystemEntity> filteredFiles = <FileSystemEntity>[].obs;
  RxList<FileSystemEntity> selectedFiles = <FileSystemEntity>[].obs;
  RxString searchQuery = ''.obs;
  RxString fileTypeFilter = 'all'.obs;
  RxBool isLoading = false.obs;

  var recentFiles = <File>[].obs;
  var bookmarkedFile = <File>[].obs;

  final textController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  final RxBool focus = false.obs;
  final allowedExtensions = {
    'pdf': ['.pdf'],
    'doc': ['.doc', '.docx'],
    'image': ['.jpg', '.jpeg', '.png']
  };
  final Box recentBox = Hive.box('recentFiles');
  final Box bookmarkBox = Hive.box('bookmarkedFiles');

  /// Download Logic
  var files = <FileSystemEntity>[].obs;

  @override
  void onInit() {
    super.onInit();
    searchQuery.listen((_) => _applyFilters());
    fileTypeFilter.listen((_) => _applyFilters());
    loadRecentFiles();
    loadBookmarkedFile();
    /// Download Logic
    loadFiles();
    Future.delayed(Duration.zero, () async {
      bool granted = await requestStoragePermission();
      if (granted) {
        await fetchFiles();
      }
    });
    searchFocusNode.addListener(() {
      focus.value = searchFocusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    Hive.close();
    super.dispose();
  }

  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.isGranted) {
        return true;
      }

      final result = await Permission.storage.request();
      if (result.isGranted) {
        Fluttertoast.showToast(msg: 'Storage permission granted.');
        return true;
      } else {
        Fluttertoast.showToast(msg: 'Permission denied. Open app settings.');
        openAppSettings();
        return false;
      }
    }
    return true;
  }

  Future<void> fetchFiles() async {
    isLoading.value = true;

    // Check if files are already stored in Hive
    final List<dynamic> cachedPaths = Hive.box('fileCache').get('cachedFiles', defaultValue: []);
    if (cachedPaths.isNotEmpty) {
      allFiles.value = cachedPaths.map((p) => File(p)).toList();
      _applyFilters();
      isLoading.value = false;
      return;
    }

    allFiles.clear();
    final granted = await _requestPermission();
    if (!granted) {
      Fluttertoast.showToast(msg: 'Storage permission not granted');
      isLoading.value = false;
      return;
    }

    try {
      final Directory dir = Directory('/storage/emulated/0/');
      final List<String> filePaths = [];

      await for (var entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          String ext = p.extension(entity.path).toLowerCase();
          if (allowedExtensions.values.expand((e) => e).contains(ext)) {
            allFiles.add(entity);
            filePaths.add(entity.path);
          }
        }
      }

      Hive.box('fileCache').put('cachedFiles', filePaths);
      _applyFilters();
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error while scanning: $e');
    }

    isLoading.value = false;
  }

  Future<void> deleteSelectedFiles() async {
    for (var file in selectedFiles) {
      try {
        if (await file.exists()) {
          await file.delete();
          allFiles.remove(file);
        } else {
          Fluttertoast.showToast(msg: 'File does not exist: ${file.path}');
        }
      } catch (e) {
        Fluttertoast.showToast(msg: 'Failed to delete: $e');
      }
    }
    selectedFiles.clear();
    _applyFilters();
  }

  Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.isGranted) {
        return true;
      }

      final result = await Permission.storage.request();
      return result.isGranted;
    }
    return true;
  }

  Future<void> refreshFiles() async {
    isLoading.value = true;
    allFiles.clear();
    filteredFiles.clear();
    await fetchFiles();
    loadRecentFiles();
    loadBookmarkedFile();
    isLoading.value = false;
    Fluttertoast.showToast(msg: 'Files refreshed successfully.');
  }

  bool isBookmarked(File file) {
    return bookmarkedFile.any((f) => f.path == file.path);
  }

  void clearText(){
    textController.clear();
    searchQuery.value = '';
  }

  void addToRecent(File file) {
    if (!recentFiles.any((f) => f.path == file.path)) {
      recentFiles.add(file);
      recentBox.put(file.path, file.path);
    }
  }

  void loadRecentFiles(){
    final paths = recentBox.values.cast<String>().toList();
    recentFiles.value = paths.map((p) => File(p)).toList();
  }

  void removeFromBookmark(File file){
    bookmarkedFile.removeWhere((f) => f.path == file.path);
    bookmarkBox.delete(file.path);
    Fluttertoast.showToast(msg: 'File is bookmark removed');
  }

  void toggleBookmark(File file) {
    if (isBookmarked(file)) {
      removeFromBookmark(file);
      Fluttertoast.showToast(msg: 'File is bookmark removed');
    } else {
      bookmarkedFile.add(file);
      bookmarkBox.put(file.path, file.path);
      selectedFiles.clear();
      Fluttertoast.showToast(msg: 'File is bookmark');
    }
  }

  void loadBookmarkedFile(){
    final paths = bookmarkBox.values.cast<String>().toList();
    bookmarkedFile.value = paths.map((p) => File(p)).toList();
  }

  void _applyFilters() {
    final query = searchQuery.value.toLowerCase();
    final type = fileTypeFilter.value;
    filteredFiles.value = allFiles.where((file) {
      final name = file.path.split('/').last.toLowerCase();
      final ext = p.extension(file.path).toLowerCase();

      final matchesQuery = name.contains(query);
      final matchesType = type == 'all'
          || (type == 'pdf' && ext == '.pdf')
          || (type == 'doc' && ['.doc', '.docx', '.txt'].contains(ext))
          || (type == 'image' && ['.jpg', '.jpeg', '.png'].contains(ext))
          || (type == 'download' && file.path.contains('/Download/'));

      return matchesQuery && matchesType;
    }).toList();
  }

  void toggleSelection(FileSystemEntity file) {
    if (selectedFiles.contains(file)) {
      selectedFiles.remove(file);
    } else {
      selectedFiles.add(file);
    }
  }

  void cleanSelectedFile(File file) {
    selectedFiles.remove(file);
  }

  void selectAllFilteredFiles() {
    selectedFiles.clear();
    selectedFiles.addAll(filteredFilesX);
    selectedFiles.addAll(filteredFiles);
  }

  void cleanFile() {
    selectedFiles.clear();
  }

  void openFile(FileSystemEntity file) {
    OpenFile.open(file.path);
  }

  void shareSelectedFiles() {
    if (selectedFiles.isEmpty) return;

    final files = selectedFiles.map((f) => XFile(f.path)).toList();
    Share.shareXFiles(files, text: 'Sharing ${files.length} file(s)');
  }

  /// Download Logic

  Future<void> loadFiles() async {
    final list = await FileService.listDownloadedFiles();
    files.assignAll(list);
    selectedFiles.clear();
  }

  Future<void> downloadFile(String url, String filename) async {
    isLoading.value = true;
    await FileService.downloadPdf(url, filename);
    await loadFiles();
    isLoading.value = false;
    selectedFiles.clear();
  }

  void deleteSelectedFiles1() {
    final selected = List<File>.from(selectedFiles);
    for (var file in selected) {
      files.remove(file); // main file list
      file.delete(); // actual deletion if needed
    }
    selectedFiles.clear();
    Fluttertoast.showToast(msg: 'Selected files deleted');
    update();
  }


  List<FileSystemEntity> get filteredFilesX => searchQuery.value.isEmpty
      ? files
      : files.where((f) => f.path.split('/').last.toLowerCase().contains(searchQuery.value.toLowerCase())).toList();

}