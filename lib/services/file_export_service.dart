import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/student.dart';

class ExportResult {
  const ExportResult({required this.path, required this.content});

  final String path;
  final String content;

  String get fileName => path.split(Platform.pathSeparator).last;
}

/// Week 3 file export: writes `student_info.txt` to the app documents folder.
class FileExportService {
  FileExportService({Future<Directory> Function()? documentsDirectory})
    : _documentsDirectory =
          documentsDirectory ?? getApplicationDocumentsDirectory;

  static const fileName = 'student_info.txt';

  final Future<Directory> Function() _documentsDirectory;

  Future<ExportResult> exportStudent(Student student) async {
    final dir = await _documentsDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    final content = student.toExportText();
    await file.writeAsString(content);
    return ExportResult(path: file.path, content: content);
  }
}
