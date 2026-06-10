import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/constants.dart';
import '../state/app_state.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.authLoading) {
      return const Scaffold(
        backgroundColor: RetroColor.cream,
        body: Center(
          child: Text(
            'LOADING...',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              fontFamily: 'monospace',
              fontSize: 24,
            ),
          ),
        ),
      );
    }
    if (state.user == null) return const LoginScreen();
    return const HomeScreen();
  }
}
