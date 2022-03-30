import 'dart:convert' show utf8;
import 'dart:io' show File, Directory;

import 'package:translator/argument_handler.dart';
import 'package:translator/translator.dart';
import 'package:test/test.dart';

import 'mock/mock_env.dart';

void main() {
  group("Translator class", () {
    late final MockEnv mockEnv;

    setUpAll(() {
      mockEnv = MockEnv(null);
    });
    test('calls translate and generates base_translation file', () async {
      final translator = Translator(
        defaultLanguage: 'de',
        useDeepL: false,
        env: mockEnv,
      );

      expect(translator.useDeepL, isFalse);
      expect(translator.defaultLanguage, equals('de'));

      await translator.translate();

      var baseTranslationFile = File(
        'lib/locale/translations/base_translations/de.dart',
      );

      var contentStream = baseTranslationFile.openRead();
      var decoded = await utf8.decodeStream(contentStream);

      var expectedResult = r'''final Map<String, String> de = {

	//  translator.dart
	'Dusche': 'Dusche',
};
''';

      expect(expectedResult, equals(decoded));
    });
  });

  group('Argument Handler', () {
    late final MockEnv mockEnv;

    setUpAll(() {
      mockEnv = MockEnv(null);
    });
    test(
      'generates translation files for supported langauge, if language codes are provided',
      () async {
        final handler = ArgumentHandler(
          updateDeepLKey: false,
          deleteDeepLKey: false,
          useDeepL: false,
          languageCodes: 'en,es',
          env: mockEnv,
        );

        await handler.handleArguments();

        final dir = Directory('lib/locale/translations/');
        var lister = dir.list();
        var filePaths = <String>[];

        await for (var file in lister) {
          expect(file.exists(), completion(isTrue));

          filePaths.add(file.path);
        }

        expect(
          filePaths,
          containsAll([
            'lib/locale/translations/es.dart',
            'lib/locale/translations/en.dart'
          ]),
        );
      },
    );
  });
}
