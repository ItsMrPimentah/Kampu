import 'package:flutter_test/flutter_test.dart';
import 'package:showtime_mobile/shared/ui/ui.dart';

void main() {
  test('Stitch presentation resources are local and centralized', () {
    expect(StitchAssets.placeholderImage, startsWith('assets/'));
    expect(StitchAssets.showtimeMark, startsWith('assets/'));
    expect(StitchAssets.bodyFont, 'Inter');
    expect(StitchAssets.displayFont, 'Inter');
    expect(StitchAssets.dataFont, 'JetBrains Mono');
  });
}
