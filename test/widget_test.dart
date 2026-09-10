import 'package:flutter_test/flutter_test.dart';
import 'package:articulicare/core/constants/app_constants.dart';
import 'package:articulicare/core/theme/app_colors.dart';

void main() {
  test('App constants and theme verification', () {
    expect(AppConstants.appName, equals('ArticuliCare'));
    expect(AppColors.primary, isNotNull);
  });
}
