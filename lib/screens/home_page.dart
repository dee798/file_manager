import 'dart:io';
import 'package:file_manager/controllers/controller.dart';
import 'package:file_manager/widgets/widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FileController());
    final List<Tab> tabs = const [
      Tab(text: 'All Files'),
      Tab(text: 'Download Files'),
      Tab(text: 'Recent Files'),
      Tab(text: 'Bookmark'),
      Tab(text: 'PDF'),
      Tab(text: 'Images'),
      Tab(text: 'Docs'),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 100,
          backgroundColor: Colors.white,
          title: Obx(() {
            final allSelected = controller.filteredFiles
                .every((file) => controller.selectedFiles.contains(file));
            return  controller.selectedFiles.isNotEmpty
                ? Column(
                  children: [
                    Row(
                        children: [
                    TextButton(
                        onPressed: () {
                          if (allSelected) {
                            controller.cleanFile();
                          } else {
                            controller.selectAllFilteredFiles();
                          }
                        },
                        child: Row(
                          children: [
                            text1(allSelected ? 'Unselect' : 'All Select', 13),
                            const SizedBox(width: 10),
                            icon2(Icons.checklist, const Color(0xff0023ff)),
                          ],
                        ),
                      ),
                    const Spacer(),
                    TextButton(
                            onPressed: controller.selectedFiles.isEmpty
                                ? null
                                : () => controller.deleteSelectedFiles1(),
                            child: Row(
                              children: [
                                text1('Delete', 13),
                                const SizedBox(width: 10),
                                icon2(Icons.delete_sweep, Colors.red),
                              ],
                            ),
                          ),
                        ]),
                    Row(
                      children: [
                        TextButton(
                          onPressed: controller.selectedFiles.isEmpty ? null
                              : () => controller.shareSelectedFiles(),
                          child: Row(
                            children: [
                              text1('Share', 13),
                              const SizedBox(width: 10),
                              icon2(Icons.ios_share, Colors.red),
                            ],
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: controller.selectedFiles.isEmpty
                              ? null
                              : () {
                            for (var file in controller.selectedFiles) {
                              if (file is File) {
                                controller.toggleBookmark(file);
                              }
                            }
                          },
                          child: Row(
                            children: [
                              text1('Bookmark', 13),
                              const SizedBox(width: 10),
                              icon2(Icons.bookmark_added, Colors.amber),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                )
                : Column(
                  children: [
                    text1('File Manager', 16),
                    const SizedBox(height: 15),
                    Row(
                        children: [
                          Expanded(
                            child: Obx(() => TextFormField(
                              controller: controller.textController,
                              focusNode: controller.searchFocusNode,
                              onChanged: (value) => controller.searchQuery.value = value,
                              decoration: InputDecoration(
                                hintText: 'Search Files...',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: controller.focus.value
                                    ? IconButton(
                                  onPressed: controller.clearText,
                                  icon: icon2(Icons.clear, Colors.red),
                                )
                                    : PopupMenuButton<String>(
                                  color: Colors.white,
                                  icon: icon2(Icons.filter_list),
                                  onSelected: (value) =>
                                  controller.fileTypeFilter.value = value,
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(value: 'all', child: Text('All')),
                                    PopupMenuItem(value: 'pdf', child: Text('Pdf')),
                                    PopupMenuItem(value: 'doc', child: Text('Docs')),
                                    PopupMenuItem(value: 'image', child: Text('Images')),
                                    PopupMenuItem(value: 'download', child: Text('Downloads')),
                                  ],
                                ),
                                contentPadding: const EdgeInsets.all(10),
                                filled: true,
                                fillColor: Colors.white,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                  const BorderSide(color: Colors.blueAccent, width: 0.2),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                  const BorderSide(color: Colors.pinkAccent, width: 0.2),
                                ),
                              ),
                            )),
                          )
                        ]),
                  ],
                );
          }),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.blueAccent,
            tabs: tabs,
            labelColor: Colors.blueAccent.shade400,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Colors.white,
        body: TabBarView(
          children: [
            /// All file page
            Obx(() {
                if (controller.filteredFiles.isEmpty) {
                  return const Center(child: Text("No files found."));
                }
                return RefreshIndicator(
                  color: Colors.black,
                  backgroundColor: Colors.white,
                  onRefresh: controller.refreshFiles,
                  child: ListView.builder(
                    itemCount: controller.filteredFiles.length,
                    itemBuilder: (_, index) {
                      final file = controller.filteredFiles[index] as File;
                      final name = file.path.split('/').last;
                      return Obx(() {
                        final selected = controller.selectedFiles.contains(file);
                        return ListTile(
                          subtitle: text1(file.path, 12),
                          title: text1(name, 14),
                          leading: getFileIcon(file.path),
                          onTap: () {
                            controller.openFile(file);
                            controller.addToRecent(file);
                          },
                          onLongPress: () => controller.toggleSelection(file),
                          trailing: selected
                              ? IconButton(
                            onPressed: () {
                              controller.cleanSelectedFile(file);
                            },
                            icon: icon2(Icons.check_circle, const Color(0xff0023ff)),
                          )
                              : const SizedBox.shrink(),
                        );
                      });
                    },
                  ),
                );
              }),

            /// Download page
            Scaffold(
              backgroundColor: Colors.white,
              floatingActionButton: Obx(() => controller.isLoading.value
                  ? const CircularProgressIndicator(
                color: Colors.black,
              )
                  : FloatingActionButton(
                backgroundColor: Colors.blue,
                child: const Icon(Icons.download,color: Colors.black,),
                onPressed: () async {
                  final url = "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf";
                  final fileName = "report_${DateTime.now().millisecondsSinceEpoch}.pdf";
                  await controller.downloadFile(url, fileName);
                },
              )),
              body: Obx(() {
                final files = controller.filteredFilesX;
                if (files.isEmpty) {
                  return const Center(child: Text("No Pdf files found."));
                }
                return lists(fileList: files);
              }),
            ),

            /// Recent page
            Obx(() {
              if (controller.recentFiles.isEmpty) {
                return const Center(child: Text("No files found."));
              }
              return ListView.builder(
                itemCount: controller.recentFiles.length,
                  itemBuilder: (_, index) {
                    final file = controller.recentFiles[index];
                    final name = file.path.split('/').last;
                    return ListTile(
                      subtitle: text1(file.path, 12),
                      title: text1(name, 14),
                      leading: getFileIcon(file.path),
                      onTap: () => controller.openFile(file),
                    );
                  }
              );
            }),

            /// Bookmark page
            Obx(() {
              if (controller.bookmarkedFile.isEmpty) {
                return const Center(child: Text("No files found."));
              }
              return ListView.builder(
                itemCount: controller.bookmarkedFile.length,
                itemBuilder: (_, index) {
                  final file = controller.bookmarkedFile[index];
                  final name = file.path.split('/').last;
                  return ListTile(
                    subtitle: text1(file.path, 12),
                    title: text1(name, 14),
                    leading: getFileIcon(file.path),
                    onTap: () {
                      controller.openFile(file);
                      controller.addToRecent(file);
                    },
                    onLongPress: () => controller.openFile(file),
                    trailing: IconButton(onPressed: () => controller.removeFromBookmark(file),
                      icon: icon2(Icons.bookmark_remove, Colors.teal),
                    ),
                  );
                },
              );
            }),

            /// Pdf page
            Obx(() {
              final files = controller.pdfFiles;
              if (files.isEmpty) {
                return const Center(child: Text("No Pdf files found."));
              }
              return lists(fileList: files);
            }),

            /// Image page
            Obx(() {
              final files = controller.imageFiles;
              if (files.isEmpty) {
                return const Center(child: Text("No Images files found."));
              }
              return lists(fileList: files);
            }),

            /// Doc page
            Obx(() {
              final files = controller.docFiles;
              if (files.isEmpty) {
                return const Center(child: Text("No Docs files found."));
              }
              return lists(fileList: files);
            }),
          ],
        ),
      ),
    );
  }
}
