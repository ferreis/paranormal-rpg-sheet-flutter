import 'package:flutter/material.dart';

class StandardNumberField extends StatelessWidget {
  const StandardNumberField({
    required this.label,
    required this.initialNumber,
    required this.onChanged,
    this.allowNegative = true,
    super.key,
  });

  final String label;
  final int initialNumber;
  final bool allowNegative;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        initialValue: initialNumber.toString(),
        keyboardType: const TextInputType.numberWithOptions(signed: true),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onChanged: (String rawText) {
          final int? parsedNumber = int.tryParse(rawText);

          if (parsedNumber == null) {
            return;
          }

          if (!allowNegative && parsedNumber < 0) {
            onChanged(0);
            return;
          }

          onChanged(parsedNumber);
        },
      ),
    );
  }
}
