import 'dart:convert' show utf8;
import 'dart:io' show File;

import 'package:translator/env/env.dart';
import 'package:translator/translator.dart';
import 'package:test/test.dart';

void main() {
  test('Calls translate and generates base_translation file', () async {
    final translator = Translator(
      defaultLanguage: 'de',
      useDeepL: false,
      env: Env(),
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
}
