import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Enter = [onSubmit], Shift+Enter = nový riadok (pri viacerých riadkoch).
class SubmitOnEnterField extends StatelessWidget {
  const SubmitOnEnterField({
    super.key,
    required this.controller,
    required this.onSubmit,
    this.maxLines = 1,
    this.decoration,
    this.style,
    this.enabled = true,
    this.textInputAction,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;
  final int maxLines;
  final InputDecoration? decoration;
  final TextStyle? style;
  final bool enabled;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (!enabled) return KeyEventResult.ignored;
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey != LogicalKeyboardKey.enter) {
          return KeyEventResult.ignored;
        }
        if (HardwareKeyboard.instance.isShiftPressed && maxLines > 1) {
          return KeyEventResult.ignored;
        }
        onSubmit();
        return KeyEventResult.handled;
      },
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        enabled: enabled,
        style: style,
        textInputAction: textInputAction ??
            (maxLines > 1 ? TextInputAction.newline : TextInputAction.done),
        decoration: decoration,
        onSubmitted: maxLines == 1 ? (_) => onSubmit() : null,
      ),
    );
  }
}

/// FormField s Enter = odoslanie (registrácia, login).
class SubmitOnEnterFormField extends StatelessWidget {
  const SubmitOnEnterFormField({
    super.key,
    required this.controller,
    required this.onSubmit,
    this.onNext,
    this.decoration,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.textInputAction,
    this.enabled = true,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;
  final VoidCallback? onNext;
  final InputDecoration? decoration;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final action = textInputAction ??
        (onNext != null ? TextInputAction.next : TextInputAction.done);

    return Focus(
      onKeyEvent: (node, event) {
        if (!enabled) return KeyEventResult.ignored;
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey != LogicalKeyboardKey.enter) {
          return KeyEventResult.ignored;
        }
        if (action == TextInputAction.next && onNext != null) {
          onNext!();
        } else {
          onSubmit();
        }
        return KeyEventResult.handled;
      },
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        enabled: enabled,
        textInputAction: action,
        decoration: decoration,
        onFieldSubmitted: (_) {
          if (action == TextInputAction.next && onNext != null) {
            onNext!();
          } else {
            onSubmit();
          }
        },
      ),
    );
  }
}
