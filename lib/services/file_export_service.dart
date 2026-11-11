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
  final result = await SharePlus.instance.share(
    ShareParams(
      files: [XFile(path, mimeType: 'text/plain')],
      subject: FileExportService.fileName,
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

  final Future<Directory> Function() _documentsDirectory;
  final FileSharer _share;

  Future<ExportResult> exportStudent(Student student) async {
    final dir = await _documentsDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    final content = student.toExportText();
    await file.writeAsString(content);
    return ExportResult(path: file.path, content: content);
  }

  /// Shows the Share sheet for an exported file.
  Future<bool> share(ExportResult result, {Rect? origin}) =>
      _share(result.path, origin: origin);
}
