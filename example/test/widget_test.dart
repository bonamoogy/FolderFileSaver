import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folder_file_saver/folder_file_saver.dart';
import 'package:folder_file_saver_example/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('folder_file_saver');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'saveFromUrl') {
            return {
              'name': 'fff.png',
              'path': '/storage/emulated/0/Pictures/Example Pictures/fff.png',
              'uri': 'content://media/external/images/media/1',
              'location': 'pictures',
            };
          }
          throw PlatformException(code: 'DOWNLOAD_FAILED', message: 'HTTP 404');
        });
  });

  testWidgets('shows a button for each example', (tester) async {
    await tester.pumpWidget(const ExampleApp());

    expect(find.text('Save an image from a URL'), findsOneWidget);
    expect(find.text('Save a resized image'), findsOneWidget);
    expect(find.text('Open app settings'), findsOneWidget);
  });

  testWidgets('shows where the file was saved', (tester) async {
    await tester.pumpWidget(const ExampleApp());

    await tester.tap(find.text('Save an image from a URL'));
    await tester.pumpAndSettle();

    expect(calls.single.method, 'saveFromUrl');
    expect(
      find.text(
        'Saved to /storage/emulated/0/Pictures/Example Pictures/fff.png',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows why a save failed', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ExampleTile(title: 'Fail', run: _failingSave),
        ),
      ),
    );

    await tester.tap(find.text('Fail'));
    await tester.pumpAndSettle();

    expect(find.text('Failed: HTTP 404'), findsOneWidget);
  });
}

Future<SavedFile> _failingSave() => saver.saveFile('/missing.txt');
