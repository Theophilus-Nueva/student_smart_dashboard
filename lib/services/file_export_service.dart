import 'dart:io';
import 'dart:ui' show Rect;

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/student.dart';

class ExportResult {
  const ExportResult({required this.path, required this.content});

  final String path;
  final String content;

  String get fileName => path.split(Platform.pathSeparator).last;
}

/// Opens the phone's Share sheet for a file. Returns true when the user
/// picked a destination (Files, Messenger, Gmail…). [origin] anchors the
/// sheet on iPad.
typedef FileSharer = Future<bool> Function(String path, {Rect? origin});

Future<bool> shareWithSystemSheet(String path, {Rect? origin}) async {
  final name = path.split(Platform.pathSeparator).last;
  final result = await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile(
          path,
          mimeType: name.endsWith('.csv') ? 'text/csv' : 'text/plain',
        ),
      ],
      subject: name,
      sharePositionOrigin: origin,
    ),
  );
  return result.status == ShareResultStatus.success;
}

/// Week 3 file export: writes `student_info.txt` to the app documents folder,
/// then hands it to the Share sheet.
class FileExportService {
  FileExportService({
    Future<Directory> Function()? documentsDirectory,
    FileSharer? share,
  }) : _documentsDirectory =
           documentsDirectory ?? getApplicationDocumentsDirectory,
       _share = share ?? shareWithSystemSheet;

  static const fileName = 'student_info.txt';
  static const directoryFileName = 'student_directory.csv';
  static const recordFileName = 'student_record.txt';

  final Future<Directory> Function() _documentsDirectory;
  final FileSharer _share;

  Future<ExportResult> exportStudent(Student student) async {
    final dir = await _documentsDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    final content = student.toExportText();
    await file.writeAsString(content);
    return ExportResult(path: file.path, content: content);
  }

  /// Week 3 first file exercise: `student_record.txt` with the fields kept
  /// in SharedPreferences (name, ID, programme).
  Future<ExportResult> saveRecord(Student student) async {
    final dir = await _documentsDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$recordFileName');
    final content =
        'Name: ${student.name}\n'
        'ID: ${student.id}\n'
        'Program: ${student.program}\n';
    await file.writeAsString(content);
    return ExportResult(path: file.path, content: content);
  }

  /// Faculty Student Directory export: one row per student. [withGrades]
  /// adds the Grade column (Week 4).
  Future<ExportResult> exportDirectoryCsv(
    List<Student> students, {
    bool withGrades = false,
  }) async {
    final rows = [
      [
        'Student ID',
        'Name',
        'Email',
        'Program',
        'Year Level',
        'Contact Number',
        'Address',
        if (withGrades) 'Grade',
      ],
      for (final s in students)
        [
          s.id,
          s.name,
          s.email,
          s.program,
          s.yearLevel,
          s.contact,
          s.address,
          if (withGrades) s.grade.toStringAsFixed(1),
        ],
    ];
    final content =
        '${rows.map((r) => r.map(_csvField).join(',')).join('\r\n')}\r\n';
    final dir = await _documentsDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$directoryFileName');
    await file.writeAsString(content);
    return ExportResult(path: file.path, content: content);
  }

  /// Quotes a CSV field when it holds a comma, quote or line break.
  static String _csvField(String value) => RegExp(r'[",\r\n]').hasMatch(value)
      ? '"${value.replaceAll('"', '""')}"'
      : value;

  /// Shows the Share sheet for an exported file.
  Future<bool> share(ExportResult result, {Rect? origin}) =>
      _share(result.path, origin: origin);
}
