import 'dart:io';

import 'package:translator/deepl_exception.dart';

import 'env/env.dart';

/// Helper class to handle arguments
class ArgumentHandler {
  final bool useDeepL;
  final bool updateDeepLKey;
  final bool deleteDeepLKey;
  final String? languageCodes;

  Env env;

  ArgumentHandler({
    required this.updateDeepLKey,
    required this.deleteDeepLKey,
    required this.useDeepL,
    required this.languageCodes,
    required this.env,
  });

  Future<void> handleArguments() async {
    try {
      await _enterDeepLAuthKey();
      await _createLanguageFiles();
    } on DeepLException catch (exception) {
      stdout.writeln('❗ ${exception.message}');
    }
  }

  /// Saving the DeepL Auth Key in the environment of the CLI
  Future<void> _enterDeepLAuthKey() async {
    if (updateDeepLKey && deleteDeepLKey) {
      throw DeepLException(
        'You cant update and delete your Auth Key simultaneously',
        stackTrace: StackTrace.current,
      );
    }

    if ((updateDeepLKey || deleteDeepLKey) ||
        useDeepL && (env.deeplAuthKey == null || env.deeplAuthKey!.isEmpty)) {
      if (!deleteDeepLKey) stdout.writeln('Creating .env...');
      final envFile = await File('.env').create();

      !deleteDeepLKey
          ? stdout.writeln('Enter your DeepL Auth Key:\n')
          : stdout.writeln('Deleting your Auth Key\n');

      final authKeyInput = !deleteDeepLKey ? stdin.readLineSync() : '';

      await envFile.writeAsString('DEEPL_AUTH_KEY="$authKeyInput"');

      env = Env();

      !deleteDeepLKey
          ? stdout.writeln(
              '💡 Your DeepL Auth Key was saved to the CLIs environment variables. You can delete or update it any time.',
            )
          : stdout.writeln('✅ Your Key was removed successfully\n');
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
