import 'package:args/args.dart';
import 'package:translator/argument_handler.dart';
import 'package:translator/core/classes/commands.dart';
import 'package:translator/env/env.dart';
import 'package:translator/translator.dart';
import 'dart:io' show Platform;

void main(List<String> arguments) async {
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
      help: 'Provide the languages your project should support',
    );

  print(parser.usage);

  ArgResults result = parser.parse(arguments);

  final argumentHandler = ArgumentHandler(
    useDeepL: result[Commands.useDeepl],
    languageCodes: result[Commands.languageCodes],
    env: Env(),
  );

  await argumentHandler.handleArguments();

  final translator = Translator(
    defaultLanguage: result[Commands.defaultLanguage],
    useDeepL: result[Commands.useDeepl],
    env: Env(),
  );

  translator.translate();
}
