// Runs the plugin for real on a device or emulator:
//
//   cd example
//   flutter test integration_test
//
// Android saves need no permission on Android 10 and higher. On iOS, the
// image test triggers the "add to Photos" permission prompt the first time.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:folder_file_saver/folder_file_saver.dart';
import 'package:folder_file_saver_example/main.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('saves a text file into a custom folder', (tester) async {
    final saved = await saveFileToCustomFolder();

    expect(saved.name, startsWith('note'));
    expect(saved.path, contains('Notes'));
    expect(File(saved.path!).existsSync(), isTrue);
  });

  testWidgets('saving the same name twice keeps both files', (tester) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/twice.txt')..writeAsStringSync('x');

    final first = await saver.saveFile(file.path);
    final second = await saver.saveFile(file.path);

    expect(second.name, isNot(first.name));
  });

  testWidgets('saves a resized image', (tester) async {
    final saved = await saveResizedImage();

    expect(saved.name, 'sample.png');
    if (Platform.isAndroid) {
      expect(saved.location, SaveLocation.pictures);
    } else {
      expect(saved.location, SaveLocation.photos);
    }
  });

  testWidgets('a missing file throws fileNotFound', (tester) async {
    await expectLater(
      saver.saveFile('/does/not/exist.txt'),
      throwsA(
        isA<FolderFileSaverException>().having(
          (e) => e.code,
          'code',
          FolderFileSaverErrorCode.fileNotFound,
        ),
      ),
    );
  });

  testWidgets('an HTTP error throws downloadFailed', (tester) async {
    await expectLater(
      saver.saveFromUrl(
        'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/missing.pdf',
      ),
      throwsA(
        isA<FolderFileSaverException>().having(
          (e) => e.code,
          'code',
          FolderFileSaverErrorCode.downloadFailed,
        ),
      ),
    );
  });
}
