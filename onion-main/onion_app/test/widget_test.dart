import 'package:flutter_test/flutter_test.dart';
import 'package:onion_app/core/constants/app_constants.dart';

void main() {
  test('App constants and OnionClass parsing works', () {
    expect(AppConstants.formatOnionClass(OnionClass.healthy), 'Healthy');
    expect(AppConstants.parseOnionClass('damaged'), OnionClass.damaged);
    expect(AppConstants.parseOnionClass('rotten'), OnionClass.rotten);
  });
}
