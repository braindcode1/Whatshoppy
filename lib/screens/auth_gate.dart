import 'package:flutter/material.dart';
import 'package:whatshoppy2/services/local_storage_service.dart';
import 'package:whatshoppy2/screens/welcome_screen.dart';
import 'package:whatshoppy2/screens/dashboard_screens.dart';

/// Decides the initial route at app startup.
///
/// Logic:
///   • Reads SharedPreferences synchronously (via async init).
///   • If a userId is stored → user was previously logged in → go to Dashboard.
///   • Otherwise → go to WelcomeScreen.
///
/// This is the ONLY place that auto-navigates to Dashboard.
/// After logout, LocalStorageService.clear() removes the userId,
/// so the next cold start will land on WelcomeScreen.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    final loggedIn = await LocalStorageService.isLoggedIn();
    if (!mounted) return;

    if (loggedIn) {
      final userId = await LocalStorageService.getUserId();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreens(userId: userId),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Shown for the brief moment while SharedPreferences loads (~50ms).
    return const Scaffold(
      backgroundColor: Color(0xFFF4F6F9),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF00C853),
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}
