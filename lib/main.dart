import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'config/firebase_options.dart';
import 'config/theme.dart';
import 'state/app_state.dart';
import 'screens/root_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const KieWalletApp());
}

class KieWalletApp extends StatelessWidget {
  const KieWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: MaterialApp(
        title: 'KieWallet | Tracker',
        debugShowCheckedModeBanner: false,
        theme: buildRetroTheme(),
        home: const RootScreen(),
      ),
    );
  }
}
