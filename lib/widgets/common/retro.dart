import 'package:flutter/material.dart';
import '../../config/constants.dart';

/// Kotak kertas: border tinta tipis, tanpa bayangan (flat) secara default.
/// `shadowOffset` > 0 memberi bayangan keras kecil ala cetakan offset.
class RetroBox extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final double borderWidth;
  final double shadowOffset;
  final BorderRadius borderRadius;
  final double? width;

  const RetroBox({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(14),
    this.borderWidth = 1,
    this.shadowOffset = 0,
    this.borderRadius = BorderRadius.zero,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: RetroColor.ink, width: borderWidth),
        borderRadius: borderRadius,
        boxShadow: shadowOffset <= 0
            ? null
            : [
                BoxShadow(
                  color: RetroColor.ink,
                  offset: Offset(shadowOffset, shadowOffset),
                  blurRadius: 0,
                ),
              ],
      ),
      child: child,
    );
  }
}

/// Judul seksi minimal: label kecil kapital + garis tipis di bawahnya.
class RetroSectionTitle extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Widget? trailing;

  const RetroSectionTitle(this.text, {super.key, this.icon, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: RetroColor.ink),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                text.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 1.5,
                  color: RetroColor.ink,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 8),
        Container(height: 1, color: RetroColor.ink),
        const SizedBox(height: 12),
      ],
    );
  }
}

class RetroButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color color;
  final Color textColor;
  final EdgeInsetsGeometry padding;
  final double borderWidth;
  final double shadowOffset;

  const RetroButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color = Colors.white,
    this.textColor = RetroColor.ink,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.borderWidth = 1,
    this.shadowOffset = 2,
  });

  @override
  State<RetroButton> createState() => _RetroButtonState();
}

class _RetroButtonState extends State<RetroButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: disabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 60),
          transform: Matrix4.translationValues(
              _pressed ? 1 : 0, _pressed ? 1 : 0, 0),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.color,
            border: Border.all(color: RetroColor.ink, width: widget.borderWidth),
            boxShadow: _pressed || widget.shadowOffset <= 0
                ? null
                : [
                    BoxShadow(
                      color: RetroColor.ink,
                      offset: Offset(widget.shadowOffset, widget.shadowOffset),
                    ),
                  ],
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(
              color: widget.textColor,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
              fontSize: 12,
              letterSpacing: 0.5,
            ),
            child: IconTheme.merge(
              data: IconThemeData(color: widget.textColor, size: 14),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

Widget _fieldLabel(String label) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 9.5,
          letterSpacing: 0.8,
          color: RetroColor.gray500,
        ),
      ),
    );

class RetroTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final String? label;
  final String? hint;
  final TextInputType keyboardType;
  final bool required;
  final int? maxLines;
  final bool obscureText;
  final Color background;
  final TextStyle? textStyle;

  const RetroTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.label,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.required = false,
    this.maxLines = 1,
    this.obscureText = false,
    this.background = Colors.white,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) _fieldLabel(label!),
        Container(
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: RetroColor.ink, width: 1),
          ),
          child: TextFormField(
            controller: controller,
            initialValue: initialValue,
            onChanged: onChanged,
            keyboardType: keyboardType,
            obscureText: obscureText,
            maxLines: obscureText ? 1 : maxLines,
            style: textStyle ??
                const TextStyle(
                    fontFamily: 'monospace', fontSize: 13, color: RetroColor.ink),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              filled: false,
              hintText: hint,
              hintStyle: const TextStyle(
                  color: RetroColor.gray400, fontFamily: 'monospace', fontSize: 12),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            ),
            validator: required
                ? (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null
                : null,
          ),
        ),
      ],
    );
  }
}

class RetroDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;
  final String? label;
  final Color background;

  const RetroDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
    this.label,
    this.background = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) _fieldLabel(label!),
        Container(
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: RetroColor.ink, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          child: DropdownButton<T>(
            value: items.contains(value) ? value : (items.isNotEmpty ? items.first : null),
            items: items
                .map((it) => DropdownMenuItem<T>(value: it, child: Text(labelOf(it))))
                .toList(),
            onChanged: onChanged,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            dropdownColor: RetroColor.surface,
            icon: const Icon(Icons.keyboard_arrow_down,
                size: 16, color: RetroColor.ink),
            style: const TextStyle(
              color: RetroColor.ink,
              fontFamily: 'monospace',
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

Future<bool> confirmDialog(BuildContext context, String message) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black45,
    builder: (ctx) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Material(
              color: Colors.transparent,
              child: RetroBox(
                color: RetroColor.surface,
                padding: const EdgeInsets.all(24),
                shadowOffset: 4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: RetroColor.red500, size: 36),
                    const SizedBox(height: 10),
                    const Text('KONFIRMASI',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: 3)),
                    const SizedBox(height: 10),
                    Text(message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12)),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: RetroButton(
                            color: RetroColor.ink,
                            textColor: RetroColor.cream,
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('YA, LANJUT',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RetroButton(
                            color: Colors.white,
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('BATAL',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
  return result ?? false;
}
