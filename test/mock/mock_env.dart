import 'package:sloco/env/env.dart';

class MockEnv implements Env {
  @override
  String? deeplAuthKey;

  MockEnv(this.deeplAuthKey);
}
