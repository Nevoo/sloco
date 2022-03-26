import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:translator/env/env.dart';
import 'package:translator/translation_string_extension.dart';

// TODO: implement Path package, to make this work on windows aswell https://pub.dev/packages/path
// TODO: provide langauge codes via cli
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

// FIND TRANSLATIONS IN CODE
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

        var fileContent = await readFileContent(fileEntity.path);

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

  Future<List<FileSystemEntity>> _getDirectorysContents(Directory dir) {
    var files = <FileSystemEntity>[];
    final completer = Completer<List<FileSystemEntity>>();
    var lister = dir.list(recursive: true);
    lister.listen((file) => files.add(file),
        onError: (error) => completer.completeError(error),
        onDone: () => completer.complete(files));
    return completer.future;
  }

  Iterable<File> _getDartFiles(List<FileSystemEntity> files) =>
      files.whereType<File>().where((file) => file.path.endsWith('.dart'));

  Future<String> readFileContent(String filePath) async {
    final readStream = File(filePath).openRead();
    return await utf8.decodeStream(readStream);
  }

  String _removeLastThreeChars(String value) =>
      value.length > 3 ? value.substring(0, value.length - 3) : value;

  String _basePath(FileSystemEntity fileEntity) =>
      fileEntity.uri.pathSegments.last;

// BASE TRANSLATIONS

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

  String _getLanguage(FileSystemEntity file) => _basePath(file).split('.')[0];

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

// TRANSLATIONS

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
          file, allTranslations, fileNamesWithTranslation);
    });

    stdout.writeln('🍻🍻🍻 Successfully updated translations! 🍻🍻🍻\n\n\n');
  }

  Future<void> _updateTranslations(
    FileSystemEntity fileEntity,
    List<String> allTranslations,
    Map<String, List<String>> fileNamesWithTranslation,
  ) async {
    stdout.writeln('Update translations in ${_basePath(fileEntity)} ...\n');
    var missingTranslationCounter = 0;

    final fileContent = await readFileContent(fileEntity.path);
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
