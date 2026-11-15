import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:showtime_mobile/app/theme.dart';
import 'package:showtime_mobile/shared/ui/ui.dart';

void main() {
  testWidgets('app and registration themes load bundled Inter offline', (
    tester,
  ) async {
    final appTheme = createAppTheme();

    expect(GoogleFonts.config.allowRuntimeFetching, isFalse);
    expect(appTheme.textTheme.bodyMedium?.fontFamily, startsWith('Inter_'));
    expect(appTheme.textTheme.headlineLarge?.fontFamily, startsWith('Inter_'));

    expect(MidnightTheme.defaults.displayStyle.fontFamily, 'Inter');
    expect(MidnightTheme.defaults.labelStyle.fontFamily, 'Inter');
    expect(MidnightTheme.defaults.bodyStyle.fontFamily, 'Inter');
    expect(MidnightTheme.defaults.monoStyle.fontFamily, 'JetBrains Mono');

    await tester.runAsync(() => GoogleFonts.pendingFonts());
  });
}
