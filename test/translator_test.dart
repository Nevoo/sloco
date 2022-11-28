// ignore_for_file: unused_local_variable

import 'dart:convert' show utf8;
import 'dart:io' show File, Directory;

import 'package:sloco/argument_handler.dart';
import 'package:sloco/deepl_exception.dart';
import 'mock/translation_string_extension.dart';
import 'package:sloco/translator.dart';
import 'package:test/test.dart';

import 'mock/mock_env.dart';

void main() {
  String testing = 'Dusche'.tr;
  String example =
      'Achtung: Bitte beachte bei der Bestellung, dass die Ware immer erst am folgenden Werktag ausgeliefert wird. Bitte brech um'
          .tr;
  String example2 =
      'Du kommst immer wieder zurück zur Übersicht, wenn du auf das Logo klickst.\n\nSo kannst du schnell & einfach durch die Bereiche navigieren.'
          .tr;

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

      var baseTranslationFile = File('lib/locale/translations/base_translations/de.dart');

      var contentStream = baseTranslationFile.openRead();
      var decoded = await utf8.decodeStream(contentStream);

      var expectedResult = r'''final Map<String, String> de = {

	//  translator_test.dart
	'Dusche': 'Dusche',
	'Achtung: Bitte beachte bei der Bestellung, dass die Ware immer erst am folgenden Werktag ausgeliefert wird. Bitte brech um': 'Achtung: Bitte beachte bei der Bestellung, dass die Ware immer erst am folgenden Werktag ausgeliefert wird. Bitte brech um',
	'Du kommst immer wieder zurück zur Übersicht, wenn du auf das Logo klickst.\n\nSo kannst du schnell & einfach durch die Bereiche navigieren.': 'Du kommst immer wieder zurück zur Übersicht, wenn du auf das Logo klickst.\n\nSo kannst du schnell & einfach durch die Bereiche navigieren.',
};
''';

      expect(expectedResult, equals(decoded));
    });

    test('uses deepl', () async {
      final mockedApiEnv = MockEnv("MockApiKey");
      final handler = ArgumentHandler(
        updateDeepLKey: false,
        deleteDeepLKey: false,
        useDeepL: true,
        languageCodes: 'en',
        env: mockedApiEnv,
      );

      await handler.handleArguments();

      final translator = Translator(
        defaultLanguage: 'de',
        useDeepL: true,
        env: mockedApiEnv,
      );

      var translationFile = File(
        'lib/locale/translations/en.dart',
      );

      await translationFile.writeAsString('');

      await translator.translate();

      var contentStream = translationFile.openRead();
      var decoded = await utf8.decodeStream(contentStream);

      var expectedResult = r'''final Map<String, String> en = {

	//  translator_test.dart
	'Dusche': '--missing translation--',
	'Achtung: Bitte beachte bei der Bestellung, dass die Ware immer erst am folgenden Werktag ausgeliefert wird. Bitte brech um': '--missing translation--',
	'Du kommst immer wieder zurück zur Übersicht, wenn du auf das Logo klickst.\n\nSo kannst du schnell & einfach durch die Bereiche navigieren.': '--missing translation--',
};
''';

      expect(expectedResult, equals(decoded));
    });

    test("formats escpaed characters correctly in old translations", () async {
      final mockingDeepLKey = MockEnv('abcdefg');
      final handler = ArgumentHandler(
        updateDeepLKey: false,
        deleteDeepLKey: false,
        useDeepL: true,
        languageCodes: 'en',
        env: mockingDeepLKey,
      );

      await handler.handleArguments();

      final translator = Translator(
        defaultLanguage: 'de',
        useDeepL: true,
        env: mockingDeepLKey,
      );

      var translationFile = File('lib/locale/translations/en.dart');

      // mocking empty file to force range error
      await translationFile.writeAsString(r'''final Map<String, String> en = {

	//  translator_test.dart
  'Dusche': 'Shower',
	'Achtung: Bitte beachte bei der Bestellung, dass die Ware immer erst am folgenden Werktag ausgeliefert wird. Bitte brech um': 'Attention: When ordering, please note that the goods will always be delivered on the following business day.',
	'Du kommst immer wieder zurück zur Übersicht, wenn du auf das Logo klickst.\n\nSo kannst du schnell & einfach durch die Bereiche navigieren.': 'You can always get back to the overview by clicking on the logo.\n\nSo you can navigate quickly & easily through the sections.',
};''');

      await translator.translate();

      var contentStream = translationFile.openRead();
      var decoded = await utf8.decodeStream(contentStream);
      var expectedResult = r'''final Map<String, String> en = {

	//  translator_test.dart
	'Dusche': 'Shower',
	'Achtung: Bitte beachte bei der Bestellung, dass die Ware immer erst am folgenden Werktag ausgeliefert wird. Bitte brech um': 'Attention: When ordering, please note that the goods will always be delivered on the following business day.',
	'Du kommst immer wieder zurück zur Übersicht, wenn du auf das Logo klickst.\n\nSo kannst du schnell & einfach durch die Bereiche navigieren.': 'You can always get back to the overview by clicking on the logo.\n\nSo you can navigate quickly & easily through the sections.',
};
''';
      expect(expectedResult, equals(decoded));
    });

    test("uses empty old Translations, when translation file contains invalid json", () async {
      final handler = ArgumentHandler(
        updateDeepLKey: false,
        deleteDeepLKey: false,
        useDeepL: false,
        languageCodes: 'en,es',
        env: mockEnv,
      );

      await handler.handleArguments();

      final translator = Translator(
        defaultLanguage: 'de',
        useDeepL: false,
        env: mockEnv,
      );

      var translationFile = File(
        'lib/locale/translations/en.dart',
      );

      // mocking empty file to force range error
      await translationFile.writeAsString('');

      await translator.translate();

      var contentStream = translationFile.openRead();
      var decoded = await utf8.decodeStream(contentStream);

      var expectedResult = r'''final Map<String, String> en = {

	//  translator_test.dart
	'Dusche': '--missing translation--',
	'Achtung: Bitte beachte bei der Bestellung, dass die Ware immer erst am folgenden Werktag ausgeliefert wird. Bitte brech um': '--missing translation--',
	'Du kommst immer wieder zurück zur Übersicht, wenn du auf das Logo klickst.\n\nSo kannst du schnell & einfach durch die Bereiche navigieren.': '--missing translation--',
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
          containsAll(['lib/locale/translations/es.dart', 'lib/locale/translations/en.dart']),
        );
      },
    );

    // test('delete deepl auth key', () async {
    //   final handler = ArgumentHandler(
    //     updateDeepLKey: false,
    //     deleteDeepLKey: true,
    //     useDeepL: false,
    //     languageCodes: '',
    //     env: Env(),
    //   );

    //   await handler.handleArguments();

    //   final env = Env();

    //   expect(env.deeplAuthKey, equals(''));
    // });

    test('throws DeepLException if both updateDeepLKey and deleteDeepLKey are passed', () async {
      final handler = ArgumentHandler(
        updateDeepLKey: true,
        deleteDeepLKey: true,
        useDeepL: false,
        languageCodes: '',
        env: mockEnv,
      );

      await expectLater(
        handler.handleArguments(),
        throwsA(isA<DeepLException>()),
      );
    });
  });
}
