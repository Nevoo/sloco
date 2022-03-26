import 'package:envify/envify.dart';

part 'env.g.dart';

@Envify()
class Env {
  const Env._();

  static const deeplAuthKey = _Env.deeplAuthKey;
}
