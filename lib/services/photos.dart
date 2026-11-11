import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Фото клиентов и заказов. Файлы лежат в папке приложения `photos/`,
/// в базе хранится только имя файла (так копия переносится на другой телефон).
class Photos {
  static late String dir;

  static Future<void> init() async {
    final docs = await getApplicationDocumentsDirectory();
    dir = p.join(docs.path, 'photos');
    await Directory(dir).create(recursive: true);
  }

  static File file(String name) => File(p.join(dir, name));

  static bool exists(String? name) => name != null && file(name).existsSync();

  /// Снять или выбрать фото, сохранить к себе. Возвращает имя файла.
  static Future<String?> pick({required bool camera, required String prefix}) async {
    final x = await ImagePicker().pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 82,
    );
    if (x == null) return null;
    final ext = p.extension(x.path).isEmpty ? '.jpg' : p.extension(x.path);
    final name = '${prefix}_${DateTime.now().millisecondsSinceEpoch}$ext';
    await File(x.path).copy(p.join(dir, name));
    return name;
  }

  static Future<void> delete(String? name) async {
    if (name == null) return;
    final f = file(name);
    if (await f.exists()) await f.delete();
  }

  /// Удаляет файлы, на которые больше ничего не ссылается.
  static Future<void> cleanup(Set<String> used) async {
    final d = Directory(dir);
    if (!await d.exists()) return;
    await for (final e in d.list()) {
      if (e is File && !used.contains(p.basename(e.path))) {
        try {
          await e.delete();
        } catch (_) {}
      }
    }
  }
}
