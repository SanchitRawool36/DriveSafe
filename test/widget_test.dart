import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drive_safe_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders the Drive Safe login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('DriveSafe'), findsOneWidget);
    expect(find.text('Safe Driving for Everyone'), findsOneWidget);
    expect(find.text('Login'), findsWidgets);
    expect(find.text('Register'), findsOneWidget);
  });
}
