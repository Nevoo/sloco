import 'dart:io';

import 'env/env.dart';

/// Helper class to handle arguments
class ArgumentHandler {
  final bool useDeepL;
  final String? languageCodes;

  Env env;

  ArgumentHandler({
    required this.useDeepL,
    required this.languageCodes,
    required this.env,
  });

  Future<void> handleArguments() async {
    await _enterDeepLAuthKey();
    await _createLanguageFiles();
  }

  /// Saving the DeepL Auth Key in the environment of the CLI
  Future<void> _enterDeepLAuthKey() async {
    if (useDeepL && (env.deeplAuthKey == null || env.deeplAuthKey!.isEmpty)) {
      stdout.writeln('Creating .env...');
      final envFile = await File('.env').create();

      stdout.writeln('Enter your DeepL Auth Key:\n');
      final authKeyInput = stdin.readLineSync();

      await envFile.writeAsString('DEEPL_AUTH_KEY="$authKeyInput"');

      env = Env();

      stdout.writeln(
        '💡 Your DeepL Auth Key was saved to the CLIs environment variables. You can delete or update it any time.',
      );
    }
  }

  /// Create empty files for the supported languages
  Future<void> _createLanguageFiles() async {
    if (languageCodes == null || languageCodes!.isEmpty) return;

    final matchLowerCaseWords = RegExp(r'[a-z]\w+');

    var matches = matchLowerCaseWords.allMatches(languageCodes!);
    var codes = matches.expand((match) => [match.group(0)]).toList();

    for (var code in codes) {
      // TODO: Use language file path / project path
      await File('lib/locale/translations/$code.dart').create(recursive: true);
    }
  }
}
