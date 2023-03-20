import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';
import 'dart:developer' as developer;

Future<void> main() async {
  try {
    await integrationDriver(
      onScreenshot: (String screenshotName, List<int> screenshotBytes) async {
        final File image = await File('screenshots/$screenshotName.png')
            .create(recursive: true);
        image.writeAsBytesSync(screenshotBytes);
        return true;
      },
    );
  } catch (e) {
    developer.log('Error occurred: $e', name: 'on screenshot');
  }
}
