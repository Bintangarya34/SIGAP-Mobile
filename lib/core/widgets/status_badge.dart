import 'package:flutter/material.dart';
import '../constants/colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor = BrutalColors.success;
    Color textColor = Colors.white;
    bool isStripe = false;

    switch (status.toUpperCase()) {
      case 'AMAN':
        bgColor = BrutalColors.success;
        textColor = Colors.white;
        break;
      case 'WASPADA':
        bgColor = BrutalColors.warning;
        textColor = Colors.black;
        isStripe = true; // Represented in design as striped/warning border
        break;
      case 'SIAGA':
        bgColor = BrutalColors.danger;
        textColor = Colors.white;
        break;
      case 'GLITCH':
      case 'OFFLINE':
        bgColor = Colors.grey;
        textColor = Colors.white;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(
          color: BrutalColors.border,
          width: 1.5,
        ),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
