import 'package:dotenv/dotenv.dart';

class Env {
  late final String? deeplAuthKey;

  Env() {
    load();

    deeplAuthKey = env['DEEPL_AUTH_KEY'];
  }
}
