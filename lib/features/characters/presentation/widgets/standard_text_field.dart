import 'package:flutter/material.dart';

class StandardTextField extends StatelessWidget {
  const StandardTextField({
    required this.label,
    required this.initialText,
    required this.onChanged,
    this.maxLines = 1,
    this.textInputAction,
    super.key,
  });

  final String label;
  final String initialText;
  final int maxLines;
  final TextInputAction? textInputAction;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        initialValue: initialText,
        maxLines: maxLines,
        textInputAction: textInputAction,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
