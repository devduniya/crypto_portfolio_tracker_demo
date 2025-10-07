import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChangeIndicator extends StatelessWidget {
  final double changeValue;
  final double changePercentage;
  final TextStyle? style;
  final bool showArrow;

  const ChangeIndicator({
    Key? key,
    required this.changeValue,
    required this.changePercentage,
    this.style,
    this.showArrow = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isPositive = changeValue > 0;
    final isNegative = changeValue < 0;
    final isZero = changeValue == 0;

    final color = isPositive
        ? Colors.green.shade400
        : isNegative
            ? Colors.red.shade400
            : Colors.grey.shade400;

    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final percentageFormatter = NumberFormat('#,##0.00');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showArrow && !isZero)
          Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            color: color,
            size: style?.fontSize ?? 16,
          ),
        if (showArrow && !isZero) const SizedBox(width: 4),
        Text(
          '${formatter.format(changeValue.abs())} (${percentageFormatter.format(changePercentage.abs())}%)',
          style: (style ?? const TextStyle()).copyWith(color: color),
        ),
      ],
    );
  }
}
