import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:folder_file_saver_example/app_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('folder_file_saver'),
          (call) async =>
              call.method == 'getPlatformVersion' ? 'Android 42' : null,
        );
  });

  testWidgets('Shows the platform version and the actions', (tester) async {
    await tester.pumpWidget(const AppPage());
    await tester.pumpAndSettle();

    expect(find.text('Running on: Android 42'), findsOneWidget);
    expect(find.text('Download Image and Resize'), findsOneWidget);
    expect(find.text('Save Image From URL'), findsOneWidget);
    expect(find.text('Open App Settings'), findsOneWidget);
  });
}
