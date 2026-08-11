import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/movil/core/theme.dart';
import 'package:frontend/movil/providers/auth_provider.dart';
import 'package:frontend/movil/screens/login/login_screen.dart';
import 'package:frontend/movil/widgets/google_sign_in_button.dart';

void main() {
  testWidgets('Login screen renders brand elements', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AuthScope(
          authProvider: AuthProvider(),
          child: LoginScreen(),
        ),
      ),
    );

    expect(find.text('Mesa Chapaca'), findsOneWidget);
    expect(find.byType(GoogleSignInButton), findsOneWidget);
    expect(find.text('Continuar con Google'), findsOneWidget);
  });
}