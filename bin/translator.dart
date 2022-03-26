import 'package:args/args.dart';
import 'package:translator/translator.dart' as translator;

/// ARGS:
// -default-language
// -project-path
// -language-file-path
// -language-codes
// -use-deepl

class Commands {
  const Commands._();

  static const defaultLanguage = 'default-language';
  static const projectPath = 'project-path';
  static const languageFilesPath = 'languageFilesPath';
  static const languageCodes = 'languageCodes';
  static const useDeepl = 'use-deepl';
}

void main(List<String> arguments) {
  final parser = ArgParser()
    ..addFlag(Commands.useDeepl, abbr: 'u', defaultsTo: true)
    // TODO: get system language as default
    ..addOption(
      Commands.defaultLanguage,
      abbr: 'd',
      valueHelp: 'de',
      defaultsTo: 'de',
    );

  ArgResults argResults = parser.parse(arguments);

  print(argResults.rest);
  //translator.translate();
}
