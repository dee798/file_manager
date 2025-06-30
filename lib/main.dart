import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_manager/screens/home_page.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'controllers/controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);
  await Hive.openBox('fileCache');
  await Hive.openBox('recentFiles');
  await Hive.openBox('bookmarkedFiles');
  runApp(GetMaterialApp(
    debugShowCheckedModeBanner: false,
    home: HomePage(),
  ));
}
