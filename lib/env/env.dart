import 'package:dotenv/dotenv.dart';

/// Loading the environment variables
class Env {
  /// Auth key for DeepL
  late final String? deeplAuthKey;

  Env() {
    load();

    deeplAuthKey = env['DEEPL_AUTH_KEY'];
  }
}
