import 'dart:io';

import 'package:media_store_plus/media_store_plus.dart';
import 'package:path_provider/path_provider.dart';

class TxtExporter {
  static const String folderName = 'LPU Student Records';

  static Future<String> save({required String fileName, required String content}) async {
    if (Platform.isAndroid) {
      await MediaStore.ensureInitialized();
      MediaStore.appFolder = folderName;

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsString(content, flush: true);

      final dynamic result = await MediaStore().saveFile(
        tempFilePath: tempFile.path,
        dirType: DirType.download,
        dirName: DirName.download,
      );

      try {
        if (await tempFile.exists()) await tempFile.delete();
      } catch (_) {}

      final saved = result is bool ? result : result != null;
      if (!saved) throw Exception('Android could not save the file.');
      return 'Internal storage > Download > $folderName > $fileName';
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(content, flush: true);
    return file.path;
  }
}

