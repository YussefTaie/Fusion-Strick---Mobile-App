import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fusionstrick/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: FusionStrikeApp()),
    );

    // Verify the app renders (shows splash or login screen)
    expect(find.byType(FusionStrikeApp), findsOneWidget);
  });
}
