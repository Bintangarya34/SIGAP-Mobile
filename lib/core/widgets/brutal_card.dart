import 'package:flutter/material.dart';
import '../constants/colors.dart';

class BrutalCard extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final double borderWidth;
  final double shadowOffset;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const BrutalCard({
    super.key,
    required this.child,
    this.backgroundColor = BrutalColors.cardBg,
    this.borderWidth = 1.5,
    this.shadowOffset = 3.0,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = const EdgeInsets.all(0.0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: BrutalColors.border,
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: BrutalColors.border,
            offset: Offset(shadowOffset, shadowOffset),
            blurRadius: 0.0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - borderWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
