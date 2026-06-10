import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../state/app_state.dart';

class PopupOverlay extends StatelessWidget {
  const PopupOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final popup = context.select<AppState, ({String message, String type})?>((s) => s.popup);
    if (popup == null) return const SizedBox.shrink();
    final isError = popup.type == 'error';
    final accent = isError ? RetroColor.red500 : RetroColor.green500;
    return Positioned(
      right: 16,
      bottom: 24,
      child: AnimatedOpacity(
        opacity: 1,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: RetroColor.surface,
            border: Border.all(color: RetroColor.ink, width: 1),
            boxShadow: const [
              BoxShadow(color: RetroColor.ink, offset: Offset(3, 3)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 8, height: 8, color: accent),
              const SizedBox(width: 10),
              Text(
                popup.message,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: RetroColor.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
