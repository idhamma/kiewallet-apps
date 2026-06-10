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
    return Positioned(
      right: 16,
      bottom: 24,
      child: AnimatedOpacity(
        opacity: 1,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isError ? RetroColor.red400 : RetroColor.green400,
            border: Border.all(color: Colors.black, width: 4),
            boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isError ? Icons.error : Icons.check_circle,
                  size: 22, color: Colors.black),
              const SizedBox(width: 8),
              Text(
                popup.message,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
