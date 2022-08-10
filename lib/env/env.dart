import 'package:dotenv/dotenv.dart';

/// Is loading the environment variables
class Env {
  /// Auth key for DeepL
  late final String? deeplAuthKey;

  Env() {
    final env = DotEnv()..load();

    deeplAuthKey = env['DEEPL_AUTH_KEY'];
  }
}
