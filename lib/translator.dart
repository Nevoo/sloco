import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:translator/env/env.dart';
import 'package:translator/translation_string_extension.dart';

// TODO: implement Path package, to make this work on windows aswell https://pub.dev/packages/path
// TODO: provide arg for custom path to project
// TODO: add arg to specify custom paths for saving the language files

String testing = 'Dusche'.tr;

class Translator {
  final String defaultLanguage;
  final bool useDeepL;
  final Env env;

  Translator({
    required this.defaultLanguage,
    required this.useDeepL,
    required this.env,
  });

  /// Searching for all Strings in the project that use the `.tr` extension.
  /// Creates language files based on the provided language codes
  /// and translates via DeepL if wanted.
  void translate() async {
    final fileNamesWithTranslation = await _getFileNamesWithTranslations();
    await _writeTranslationsToBaseFile(fileNamesWithTranslation);

    final allTranslations = <String>[];

    for (var value in fileNamesWithTranslation.values) {
      allTranslations.addAll(value);
    }

    await _writeTranslationsToAllTranslationFiles(
      allTranslations,
      fileNamesWithTranslation,
    );

    exit(0);
  }

  /// Searching for all Strings in the project that use the `.tr` extension.
  ///
  /// Returns a map where the key is the file in which the translation were found
  /// and the values are all translation for that specific file.
  /// ```dart
  /// {
  ///   'example.dart': ["'Hello'", "'World'"],
  /// }
  /// ```
  Future<Map<String, List<String>>> _getFileNamesWithTranslations() async {
    stdout.writeln('Getting all Strings to translate...\n');

    var currentDir = Directory.current;

    var allStringsToTranslate = List<String>.empty(growable: true);
    var fileNamesWithTranslation = <String, List<String>>{};

    try {
      var files = await _getDirectorysContents(currentDir);
      var dartFiles = _getDartFiles(files);

      await Future.forEach(dartFiles, (File fileEntity) async {
        var translationForSpecificFile = List<String>.empty(growable: true);

        var fileContent = await _readFileContent(fileEntity.path);

        var matchTranslationExtension =
            RegExp(r"('[^'\\]*(?:\\.[^'\\]*)*'\s*\.tr\b)");
        var wordMatches = matchTranslationExtension.allMatches(fileContent);

        for (var wordMatch in wordMatches) {
          var word = wordMatch.group(0)!;

          if (!allStringsToTranslate.contains(word)) {
            allStringsToTranslate.add(word);
            translationForSpecificFile.add(_removeLastThreeChars(word));
          }
        }

        if (translationForSpecificFile.isNotEmpty) {
          var fileName = _basePath(fileEntity);
          fileNamesWithTranslation[fileName] = translationForSpecificFile;
        }
      });

      stdout.writeln('✅ Done!\n\n');
      return fileNamesWithTranslation;
    } catch (exception) {
      stdout.writeln('Something went wrong while translating');
      return fileNamesWithTranslation;
    }
  }

  /// Returns all files and directorys of a given [directory].
  Future<List<FileSystemEntity>> _getDirectorysContents(Directory directory) {
    var files = <FileSystemEntity>[];
    final completer = Completer<List<FileSystemEntity>>();
    var lister = directory.list(recursive: true);
    lister.listen((file) => files.add(file),
        onError: (error) => completer.completeError(error),
        onDone: () => completer.complete(files));
    return completer.future;
  }

  /// Returns an iterable of all dart files in a list of [files].
  Iterable<File> _getDartFiles(List<FileSystemEntity> files) =>
      files.whereType<File>().where((file) => file.path.endsWith('.dart'));

  /// Reads, decodes and returns the content of a given [filePath]
  Future<String> _readFileContent(String filePath) async {
    final readStream = File(filePath).openRead();
    return await utf8.decodeStream(readStream);
  }

  /// Helper function to remove the last 3 chars of a [value].
  String _removeLastThreeChars(String value) =>
      value.length > 3 ? value.substring(0, value.length - 3) : value;

  String _basePath(FileSystemEntity fileEntity) =>
      fileEntity.uri.pathSegments.last;

  /// Writes all found Strings with the `tr` exentsion [fileNamesWithTranslation] into the base translation file.
  Future<void> _writeTranslationsToBaseFile(
    Map<String, List<String>> fileNamesWithTranslation,
  ) async {
    stdout.writeln('Updating base translation file...\n');
    final currentDir = Directory.current;

    final translationDir =
        'lib/locale/translations/base_translations/$defaultLanguage.dart';
    final baseTranslationFile =
        await File('${currentDir.path}/$translationDir').create(
      recursive: true,
    );

    await _writeTranslationsToFile(
      baseTranslationFile,
      fileNamesWithTranslation,
      language: _getLanguage(baseTranslationFile),
      writeKeyAndValue: (translation, sink) {
        sink.writeln('\t$translation: $translation,');
      },
    );

    stdout.writeln('✅ Done!\n\n');
  }

  /// Helper function to get the language of a given localization [file]
  ///
  /// The file should have the format `de.dart`
  String _getLanguage(FileSystemEntity file) => _basePath(file).split('.')[0];

  /// Function which writes the translations to the given [file]
  ///
  /// Needs the [fileNameWithTranslation] because based on that, the content of the [file]
  /// gets ordered.
  /// [writeKeyAndValue] is a callback function for a custom implementation on how to write
  /// the key and value of [fileNameWithTranslation].
  /// You should not flush the IOSink that get's passed to [writeKeyAndValue], because that happens at the end of this function.
  /// Creates a file with the [language] as a name
  Future<void> _writeTranslationsToFile(
    File file,
    Map<String, List<String>> fileNamesWithTranslation, {
    required void Function(String, IOSink) writeKeyAndValue,
    required String language,
  }) async {
    final sink = file.openWrite();

    sink.writeln('final Map<String, String> $language = {');

    // inkrementelles update von den files und nicht immer alles neuschreiben
    await Future.forEach(fileNamesWithTranslation.entries, (
      MapEntry<String, List<String>> entry,
    ) async {
      sink.writeln('\n\t//  ${entry.key}');
      await Future.forEach(
        entry.value,
        (String translation) => writeKeyAndValue(translation, sink),
      );
    });

    sink.writeln('};');

    await sink.flush();
    await sink.close();
  }

  /// Gets all language files in the `lib/locale/translations` path and updates the files
  /// incrementally with [allTranslations] and [fileNamesWithTranslation]
  Future<void> _writeTranslationsToAllTranslationFiles(
    List<String> allTranslations,
    Map<String, List<String>> fileNamesWithTranslation,
  ) async {
    final currentDir = Directory.current;
    final relativeTranslationPath = 'lib/locale/translations/';
    final translationDir =
        Directory('${currentDir.path}/$relativeTranslationPath');
    final translationFiles = await _getDirectorysContents(translationDir);

    final filteredFiles = translationFiles
        .whereType<File>()
        .where((file) => !file.path.contains('/base_translations'));

    await Future.forEach(filteredFiles, (File file) async {
      await _updateTranslations(
        file,
        allTranslations,
        fileNamesWithTranslation,
      );
    });

    stdout.writeln('🍻🍻🍻 Successfully updated translations! 🍻🍻🍻\n\n\n');
  }

  /// Updates each translation file and keeps track of all
  /// missing translations, or updates missing translations with the DeepL API
  Future<void> _updateTranslations(
    FileSystemEntity fileEntity,
    List<String> allTranslations,
    Map<String, List<String>> fileNamesWithTranslation,
  ) async {
    stdout.writeln('Update translations in ${_basePath(fileEntity)} ...\n');
    var missingTranslationCounter = 0;

    final fileContent = await _readFileContent(fileEntity.path);
    final matchComments = RegExp(r'\/\/.*\n?');
    final keysAndValues = fileContent.replaceAll(matchComments, '');

    Map<String, dynamic> oldTranslations;

    try {
      final json = keysAndValues.split('=')[1].replaceAll(r"'", '"').trim();
      final indexOfLastComma = json.lastIndexOf(',');
      final validJson = json
          .replaceFirst(',', '', indexOfLastComma - 1)
          .substring(0, json.length - 2);

      oldTranslations = jsonDecode(validJson) as Map<String, dynamic>;
    } catch (exception) {
      // if json is invalid oldTranslations are empty
      String message = exception is RangeError
          ? '❗️Translation file was empty or had an invalid format...\ngenerating from scratch...'
          : '💡Something went wrong...\ngenerating from scratch...';
      stdout.writeln(message);
      oldTranslations = {};
    }

    for (var key in [...oldTranslations.keys]) {
      if (!allTranslations.contains("'$key'")) {
        oldTranslations.remove(key);
      }
    }

    final missingTranslation = '--missing translation--';

    final file = File(fileEntity.path);
    final language = _getLanguage(file);

    await _writeTranslationsToFile(
      file,
      fileNamesWithTranslation,
      language: language,
      writeKeyAndValue: (translation, sink) async {
        final oldTranslationKey = translation.replaceAll("'", '');
        final isMissing = !oldTranslations.containsKey(oldTranslationKey) ||
            oldTranslations.containsKey(oldTranslationKey) &&
                oldTranslations[oldTranslationKey].isEmpty ||
            oldTranslations[oldTranslationKey] == missingTranslation;
        if (isMissing) missingTranslationCounter++;

        final value = isMissing
            ? useDeepL
                ? await _deepLTranslate(oldTranslationKey, language)
                : missingTranslation
            : oldTranslations[oldTranslationKey];

        sink.writeln("\t$translation: '$value',");
      },
    );

    stdout.writeln('✅ Done!\n');
    stdout.writeln(
        '💡  $missingTranslationCounter missing translation${missingTranslationCounter == 1 ? '' : 's'}\n\n');
  }

  /// Returns the translation for the given [text] and the [language] in which it should be translated
  /// via the DeepL API
  Future<String> _deepLTranslate(String text, String language) async {
    try {
      final url = Uri.https('api-free.deepl.com', '/v2/translate');

      Map<String, dynamic> body = {
        "auth_key": env.deeplAuthKey,
        "text": text,
        "target_lang": language,
        "source_lang": defaultLanguage.toUpperCase(),
      };

      var response = await http.post(url, body: body);
      var json = jsonDecode(
        utf8.decode(response.bodyBytes),
      ) as Map<String, dynamic>;
      var result = json['translations'][0]['text'];

      return result;
    } on Exception {
      stderr.writeln("❗️ Something went wrong while translating with deepl ");
      return "--missing translation--";
    }
  }
}
