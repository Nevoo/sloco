import 'package:args/args.dart';
import 'package:translator/argument_handler.dart';
import 'package:translator/core/classes/commands.dart';
import 'package:translator/env/env.dart';
import 'package:translator/translator.dart';
import 'dart:io' show Directory, Platform;

void main(List<String> arguments) {
  final parser = ArgParser()
    ..addFlag(
      Commands.useDeepl,
      abbr: 'u',
      defaultsTo: true,
      help: 'Translate all texts via the DeepL API',
    )
    ..addOption(
      Commands.defaultLanguage,
      abbr: 'd',
      valueHelp: 'de',
      defaultsTo: Platform.localeName,
      help: 'Set your default project language',
    )
    ..addOption(
      Commands.languageCodes,
      abbr: 'c',
      valueHelp: 'en,es,ru',
      help: 'Provide the languages your project can support',
    )
    ..addOption(
      Commands.languageFilesPath,
      abbr: 'f',
      valueHelp: 'lib/locale/translations/',
      defaultsTo: 'lib/locale/translations/',
      help:
          'Add a custom path where your translations are saved. Is using the project path like <projectPath>/<languageFilesPath>.',
    )
    ..addOption(
      Commands.projectPath,
      abbr: 'p',
      valueHelp: '/Users/name/projects/translator',
      defaultsTo: Directory.current.path,
      help: 'Add a custom project path.',
    );

  ArgResults result = parser.parse(arguments);
  print(parser.usage);

  final argumentHandler = ArgumentHandler(
    defaultLanguage: result[Commands.defaultLanguage],
    useDeepL: result[Commands.useDeepl],
    languageCodes: result[Commands.languageCodes],
    languageFilesPath: result[Commands.languageFilesPath],
    projectPath: result[Commands.projectPath],
    env: Env(),
  );

  argumentHandler.handleArguments();

  // final translator = Translator(
  // defaultLanguage: result[Commands.defaultLanguage],
  // useDeepL: result[Commands.useDeepl],
  // languageCodes: result[Commands.languageCodes],
  // languageFilesPath: result[Commands.languageFilesPath],
  // projectPath: result[Commands.projectPath],
  // );

  // translator.handleArguments();
  // translator.translate();
}
