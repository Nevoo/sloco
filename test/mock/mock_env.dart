import 'package:translator/env/env.dart';

class MockEnv implements Env {
  @override
  String? deeplAuthKey;

  MockEnv(this.deeplAuthKey);
}
