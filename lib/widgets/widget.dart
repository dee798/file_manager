import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/controller.dart';

Widget text1(String text, double siz, [FontWeight? widget, Color? color] ) {
  return Text(text,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      fontSize: siz,
      fontWeight: FontWeight.w500,
      color: Colors.black,
    ),
  );
}

Widget icon1(String name) {
  return Image.asset('assets/icons/$name',height:25,);
}

Widget icon2(IconData icons, [Color? color]) {
  return Icon(icons, color: color?? Colors.black, size: 20,);
}

Widget getFileIcon(String filePath) {
  final extension = filePath.split('.').last.toLowerCase();

  const iconMap = {
    'jpg': 'image.png',
    'jpeg': 'image.png',
    'png': 'image.png',
    'gif': 'image.png',
    'pdf': 'pdf.png',
    'doc': 'doc.png',
    'docx': 'doc.png',
    'txt': 'doc.png',
  };

  final iconName = iconMap[extension] ?? 'file.png';
  return icon1(iconName);
}

Widget lists({
  required List<FileSystemEntity> fileList,
}) {
  final controller = Get.find<FileController>();

  return ListView.builder(
    itemCount: fileList.length,
    itemBuilder: (_, index) {
      final file = fileList[index];
      final name = file.path.split('/').last;
      final fileSize = File(file.path).lengthSync();
      final fileDate = File(file.path).lastModifiedSync();

      return Obx(() {
        final selected = controller.selectedFiles.contains(file);
        return ListTile(
          subtitle: text1("${(fileSize / 1024).toStringAsFixed(1)} KB · ${fileDate.toLocal()}", 12),
          title: text1(name, 14),
          leading: getFileIcon(file.path),
          onTap: () {
            controller.openFile(file);
            controller.addToRecent(File(file.path));
          },
          onLongPress: () => controller.toggleSelection(file),
          trailing: selected
              ? IconButton(
            onPressed: () => controller.cleanSelectedFile(file as File),
            icon: icon2(Icons.check_circle, const Color(0xff0023ff)),
          )
              : const SizedBox.shrink(),
        );
      });
    },
  );
}

