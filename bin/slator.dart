import 'package:args/args.dart';
import 'package:slator/argument_handler.dart';
import 'package:slator/core/classes/commands.dart';
import 'package:slator/deepl_exception.dart';
import 'package:slator/env/env.dart';
import 'package:slator/translator.dart';
import 'dart:io' show Platform, exit;

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag(
      Commands.useDeepl,
      abbr: 'u',
      defaultsTo: true,
      help: 'Translate all texts via the DeepL API',
    )
    ..addFlag(
      Commands.deleteDeeplKey,
      defaultsTo: false,
      negatable: false,
      help: 'Delete your DeepL Auth Key from the environment',
    )
    ..addFlag(
      Commands.updateDeeplKey,
      defaultsTo: false,
      negatable: false,
      help: 'Update your DeepL Auth Key',
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
    updateDeepLKey: result[Commands.updateDeeplKey],
    deleteDeepLKey: result[Commands.deleteDeeplKey],
    env: Env(),
  );

  try {
    await argumentHandler.handleArguments();
  } on DeepLException catch (_) {
    exit(2);
  }

  final translator = Translator(
    defaultLanguage: result[Commands.defaultLanguage],
    useDeepL: result[Commands.useDeepl],
    env: Env(),
  );

  if (!result[Commands.deleteDeeplKey] && !result[Commands.updateDeeplKey]) {
    await translator.translate();
  }

  exit(0);
}
