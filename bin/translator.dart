import 'package:args/args.dart';
import 'package:translator/core/classes/commands.dart';
import 'package:translator/translator.dart' as translator;
import 'dart:io' show Platform;

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
    );

  print(parser.usage);
  ArgResults argResults = parser.parse(arguments);

  print(argResults.rest);
  //translator.translate();
}
