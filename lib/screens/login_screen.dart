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
                  color: RetroColor.purple100,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: RetroColor.yellow400,
                            border: Border.all(color: Colors.black, width: 4),
                            boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
                          ),
                          child: const Icon(Icons.videogame_asset, size: 48),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('KieWallet',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                              fontFamily: 'monospace')),
                      const SizedBox(height: 4),
                      const Text("kiezu's Money Management",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                              fontFamily: 'monospace')),
                      const SizedBox(height: 24),
                      RetroTextField(
                          controller: _email,
                          label: 'Email',
                          keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 12),
                      RetroTextField(controller: _pwd, label: 'Password', obscureText: true),
                      const SizedBox(height: 16),
                      RetroButton(
                        onPressed: busy ? null : _submit,
                        color: isRegister ? RetroColor.blue400 : RetroColor.green400,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Center(
                          child: Text(
                            isRegister ? 'DAFTAR AKUN BARU' : 'LOGIN / MASUK',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
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
                                fontWeight: FontWeight.w700),
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
