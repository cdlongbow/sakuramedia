import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

export 'package:file_picker/file_picker.dart' show FileType;

/// 通过 file_picker 选择单个文件并读取字节的结果。
class PickedFileWithBytes {
  const PickedFileWithBytes({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;
}

/// 文件选择失败（读取失败 / 平台插件不可用 / 平台异常）的领域异常。
class FilePickerWithBytesException implements Exception {
  const FilePickerWithBytesException(this.message);

  final String message;
}

/// 选择单个文件并读取字节。
Future<PickedFileWithBytes?> pickFileWithBytes({
  List<String>? allowedExtensions,
  FileType type = FileType.custom,
  String? initialDirectory,
  required String unreadableMessage,
  required String pickerUnavailableMessage,
  required String openFailureMessage,
}) async {
  try {
    final file = await FilePicker.pickFile(
      initialDirectory: initialDirectory,
      type: type,
      allowedExtensions: type == FileType.custom ? allowedExtensions : null,
      compressionQuality: 0,
    );
    if (file == null) {
      return null;
    }

    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (_) {
      throw FilePickerWithBytesException(unreadableMessage);
    }
    if (bytes.isEmpty) {
      throw FilePickerWithBytesException(unreadableMessage);
    }
    return PickedFileWithBytes(bytes: bytes, fileName: file.name);
  } on MissingPluginException catch (error, stackTrace) {
    debugPrint('File picker plugin is unavailable: $error');
    debugPrintStack(stackTrace: stackTrace);
    throw FilePickerWithBytesException(pickerUnavailableMessage);
  } on PlatformException catch (error, stackTrace) {
    debugPrint('File picker failed: ${error.message ?? error.code}');
    debugPrintStack(stackTrace: stackTrace);
    throw FilePickerWithBytesException(error.message ?? openFailureMessage);
  }
}
