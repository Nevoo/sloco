import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:translator/env/env.dart';
import 'package:translator/translation_string_extension.dart';

// TODO: implement Path package, to make this work on windows aswell https://pub.dev/packages/path
// TODO: implement logic, to provide a base language from the cli if a base file is missing
// TODO: provide arg for custom path to project
// TODO: add arg to specify custom paths for saving the language files
// TODO: provide langauge codes via cli

String testing = 'Dusche'.tr;

void translate() async {
  final fileNamesWithTranslation = await getFileNamesWithTranslations();
  await writeTranslationsToBaseFile(fileNamesWithTranslation);

  final allTranslations = <String>[];
  for (var value in fileNamesWithTranslation.values) {
    allTranslations.addAll(value);
  }

  await writeTranslationsToAllTranslationFiles(
    allTranslations,
    fileNamesWithTranslation,
  );

  exit(0);
}

// FIND TRANSLATIONS IN CODE
Future<Map<String, List<String>>> getFileNamesWithTranslations() async {
  stdout.writeln('Getting all Strings to translate...\n');

  var currentDir = Directory.current;

  var allStringsToTranslate = List<String>.empty(growable: true);
  var fileNamesWithTranslation = <String, List<String>>{};

  try {
    var files = await getDirectorysContents(currentDir);
    var dartFiles = getDartFiles(files);

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
          translationForSpecificFile.add(removeLastThreeChars(word));
        }
      }

      if (translationForSpecificFile.isNotEmpty) {
        var fileName = basePath(fileEntity);
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

Future<List<FileSystemEntity>> getDirectorysContents(Directory dir) {
  var files = <FileSystemEntity>[];
  final completer = Completer<List<FileSystemEntity>>();
  var lister = dir.list(recursive: true);
  lister.listen((file) => files.add(file),
      onError: (error) => completer.completeError(error),
      onDone: () => completer.complete(files));
  return completer.future;
}

Iterable<File> getDartFiles(List<FileSystemEntity> files) =>
    files.whereType<File>().where((file) => file.path.endsWith('.dart'));

Future<String> readFileContent(String filePath) async {
  final readStream = File(filePath).openRead();
  return await utf8.decodeStream(readStream);
}

String removeLastThreeChars(String value) =>
    value.length > 3 ? value.substring(0, value.length - 3) : value;

String basePath(FileSystemEntity fileEntity) =>
    fileEntity.uri.pathSegments.last;

// BASE TRANSLATIONS

Future<void> writeTranslationsToBaseFile(
  Map<String, List<String>> fileNamesWithTranslation,
) async {
  stdout.writeln('Updating base translation file...\n');
  final currentDir = Directory.current;

  final translationDir = 'lib/locale/translations/base_translations/de.dart';
  final baseTranslationFile =
      await File('${currentDir.path}/$translationDir').create(
    recursive: true,
  );

  await writeTranslationsToFile(
    baseTranslationFile,
    fileNamesWithTranslation,
    language: getLanguage(baseTranslationFile),
    writeKeyAndValue: (translation, sink) {
      sink.writeln('\t$translation: $translation,');
    },
  );

  stdout.writeln('✅ Done!\n\n');
}

String getLanguage(FileSystemEntity file) => basePath(file).split('.')[0];

Future<void> writeTranslationsToFile(
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

Future<void> writeTranslationsToAllTranslationFiles(
  List<String> allTranslations,
  Map<String, List<String>> fileNamesWithTranslation,
) async {
  final currentDir = Directory.current;
  final relativeTranslationPath = 'lib/locale/translations/';
  final translationDir =
      Directory('${currentDir.path}/$relativeTranslationPath');
  final translationFiles = await getDirectorysContents(translationDir);

  final filteredFiles = translationFiles
      .whereType<File>()
      .where((file) => !file.path.contains('/base_translations'));

  await Future.forEach(filteredFiles, (File file) async {
    await updateTranslations(file, allTranslations, fileNamesWithTranslation);
  });

  stdout.writeln('🍻🍻🍻 Successfully updated translations! 🍻🍻🍻\n\n\n');
}

Future<void> updateTranslations(
  FileSystemEntity fileEntity,
  List<String> allTranslations,
  Map<String, List<String>> fileNamesWithTranslation,
) async {
  stdout.writeln('Update translations in ${basePath(fileEntity)} ...\n');
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
  final language = getLanguage(file);

  await writeTranslationsToFile(
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
          ? await deepLTranslate(oldTranslationKey, language)
          : oldTranslations[oldTranslationKey];

      sink.writeln("\t$translation: '$value',");
    },
  );

  stdout.writeln('✅ Done!\n');
  stdout.writeln(
      '💡  $missingTranslationCounter missing translation${missingTranslationCounter == 1 ? '' : 's'}\n\n');
}

Future<String> deepLTranslate(String text, String language) async {
  final url = Uri.https('api-free.deepl.com', '/v2/translate');

  Map<String, dynamic> body = {
    "auth_key": Env.deeplAuthKey,
    "text": text,
    "target_lang": language,
    // TODO: add variable for base language
    "source_lang": "DE"
  };

  var response = await http.post(url, body: body);
  var json = jsonDecode(
    utf8.decode(response.bodyBytes),
  ) as Map<String, dynamic>;
  var result = json['translations'][0]['text'];
  return result;
}
