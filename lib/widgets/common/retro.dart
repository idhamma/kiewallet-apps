import 'package:flutter/material.dart';
import '../../config/constants.dart';

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
    this.padding = const EdgeInsets.all(12),
    this.borderWidth = 4,
    this.shadowOffset = 4,
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
        border: Border.all(color: Colors.black, width: borderWidth),
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            offset: Offset(shadowOffset, shadowOffset),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
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
    this.textColor = Colors.black,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.borderWidth = 2,
    this.shadowOffset = 3,
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
      opacity: disabled ? 0.6 : 1,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: disabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 60),
          transform: Matrix4.translationValues(
              _pressed ? 2 : 0, _pressed ? 2 : 0, 0),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.color,
            border: Border.all(color: Colors.black, width: widget.borderWidth),
            boxShadow: _pressed
                ? const [BoxShadow(color: Colors.black, offset: Offset(1, 1))]
                : [
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(widget.shadowOffset, widget.shadowOffset),
                    ),
                  ],
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(
              color: widget.textColor,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
              fontSize: 13,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

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
        if (label != null)
          Text(label!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
        Container(
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: TextFormField(
            controller: controller,
            initialValue: initialValue,
            onChanged: onChanged,
            keyboardType: keyboardType,
            obscureText: obscureText,
            maxLines: obscureText ? 1 : maxLines,
            style: textStyle ??
                const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Colors.black),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              hintText: hint,
              hintStyle: const TextStyle(color: RetroColor.gray400, fontFamily: 'monospace'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
        if (label != null)
          Text(label!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
        Container(
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: Colors.black, width: 2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: DropdownButton<T>(
            value: items.contains(value) ? value : (items.isNotEmpty ? items.first : null),
            items: items
                .map((it) => DropdownMenuItem<T>(value: it, child: Text(labelOf(it))))
                .toList(),
            onChanged: onChanged,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            style: const TextStyle(
              color: Colors.black,
              fontFamily: 'monospace',
              fontSize: 13,
              fontWeight: FontWeight.w700,
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
    barrierColor: Colors.black54,
    builder: (ctx) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Material(
              color: Colors.transparent,
              child: RetroBox(
                color: RetroColor.yellow100,
                padding: const EdgeInsets.all(24),
                shadowOffset: 8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_rounded, color: Colors.red, size: 48),
                    const SizedBox(height: 8),
                    const Text('KONFIRMASI',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                    const SizedBox(height: 8),
                    Text(message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: RetroButton(
                            color: RetroColor.red400,
                            textColor: Colors.white,
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('YA, LANJUTKAN',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RetroButton(
                            color: RetroColor.gray300,
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('BATAL',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12)),
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
