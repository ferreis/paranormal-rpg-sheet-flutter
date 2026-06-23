import 'package:flutter/material.dart';

class AttributeSelector extends StatelessWidget {
  const AttributeSelector({
    required this.label,
    required this.currentValue,
    required this.onChanged,
    super.key,
  });

  final String label;
  final int currentValue;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.titleSmall),
            ),
            IconButton(
              tooltip: 'Diminuir',
              onPressed: currentValue <= 0
                  ? null
                  : () => onChanged(currentValue - 1),
              icon: const Icon(Icons.remove),
            ),
            SizedBox(
              width: 36,
              child: Text(
                currentValue.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: 'Aumentar',
              onPressed: () => onChanged(currentValue + 1),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}
