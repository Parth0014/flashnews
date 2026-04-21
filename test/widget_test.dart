import 'package:flutter_test/flutter_test.dart';

import 'package:flashnews/app.dart';
import 'package:flashnews/features/news/data/news_repository_mock.dart';

void main() {
  testWidgets('Shows app title and first headline', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(FlashNewsApp(repository: MockNewsRepository()));
    await tester.pumpAndSettle();

    expect(
      find.text('Global Markets Rally as Tech Stocks Lead Gains'),
      findsOneWidget,
    );
  });
}
