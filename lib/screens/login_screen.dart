import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/constants.dart';
import '../config/firebase_options.dart' show enableRegistration;
import '../state/app_state.dart';
import '../widgets/common/retro.dart';
import '../widgets/common/popup_overlay.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pwd = TextEditingController();
  bool isRegister = false;
  bool busy = false;

  Future<void> _submit() async {
    final s = context.read<AppState>();
    setState(() => busy = true);
    try {
      if (isRegister) {
        await s.auth.register(_email.text.trim(), _pwd.text);
        s.showPopup('Registrasi & Login Berhasil!');
      } else {
        await s.auth.signIn(_email.text.trim(), _pwd.text);
        s.showPopup('Login Berhasil!');
      }
    } catch (_) {
      s.showPopup(
        isRegister ? 'Gagal Registrasi!' : 'Gagal Login: Email/Password salah!',
        type: 'error',
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RetroColor.cream,
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: RetroBox(
                  color: RetroColor.surface,
                  padding: const EdgeInsets.all(28),
                  shadowOffset: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 56,
                          height: 56,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: RetroColor.ink),
                          child: const Icon(Icons.videogame_asset,
                              size: 30, color: RetroColor.cream),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('KIEWALLET',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 6,
                              color: RetroColor.ink,
                              fontFamily: 'monospace')),
                      const SizedBox(height: 6),
                      const Text("kiezu's money management",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                              color: RetroColor.gray500,
                              fontFamily: 'monospace')),
                      const SizedBox(height: 20),
                      Container(height: 1, color: RetroColor.ink),
                      const SizedBox(height: 20),
                      RetroTextField(
                          controller: _email,
                          label: 'Email',
                          keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 12),
                      RetroTextField(controller: _pwd, label: 'Password', obscureText: true),
                      const SizedBox(height: 16),
                      RetroButton(
                        onPressed: busy ? null : _submit,
                        color: RetroColor.ink,
                        textColor: RetroColor.cream,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Center(
                          child: Text(
                            isRegister ? 'DAFTAR AKUN BARU' : 'LOGIN / MASUK',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                letterSpacing: 2),
                          ),
                        ),
                      ),
                      if (enableRegistration) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => setState(() => isRegister = !isRegister),
                          child: Text(
                            isRegister
                                ? 'Sudah punya akun? Login di sini'
                                : 'Belum punya akun? Daftar di sini',
                            style: const TextStyle(
                                decoration: TextDecoration.underline,
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: RetroColor.gray500,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          const PopupOverlay(),
        ],
      ),
    );
  }
}
