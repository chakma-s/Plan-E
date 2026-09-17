import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: const PlanETravelApp(),
    ),
  );
}

class PlanETravelApp extends StatelessWidget {
  const PlanETravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        return MaterialApp(
          title: 'Plan-E Travel',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: state.currentTheme,
          home: const HomeScreen(),
          builder: (context, child) {
            return LayoutBuilder(
              builder: (context, constraints) {
                // When running on web in a wide desktop browser (> 500px):
                // Enforce a realistic mobile phone simulation viewport (e.g. 430px wide)
                if (kIsWeb && constraints.maxWidth > 500) {
                  const double mobileWidth = 430.0;
                  final currentMq = MediaQuery.of(context);
                  final simulatedMq = currentMq.copyWith(
                    size: Size(mobileWidth, currentMq.size.height),
                  );
                  return Container(
                    color: const Color(0xFF0F172A), // Slate 900 canvas
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: mobileWidth),
                        child: MediaQuery(
                          data: simulatedMq,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.18),
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 30,
                                  spreadRadius: 4,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(25),
                              child: child ?? const SizedBox(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }
                // On real mobile device or Chrome DevTools Mobile View (<= 500px width):
                return child ?? const SizedBox();
              },
            );
          },
        );
      },
    );
  }
}

