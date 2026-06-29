import 'package:flutter/material.dart';
import '../constants/colors.dart';

class BrutalButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color backgroundColor;
  final double width;
  final double height;
  final double borderRadius;

  const BrutalButton({
    super.key,
    required this.child,
    required this.onTap,
    this.backgroundColor = BrutalColors.cardBg,
    this.width = double.infinity,
    this.height = 50.0,
    this.borderRadius = 16.0,
  });

  @override
  State<BrutalButton> createState() => _BrutalButtonState();
}

class _BrutalButtonState extends State<BrutalButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final offsetVal = _isPressed ? 1.0 : 4.0;
    
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        width: widget.width,
        height: widget.height,
        transform: Matrix4.translationValues(
          _isPressed ? 3.0 : 0.0,
          _isPressed ? 3.0 : 0.0,
          0.0,
        ),
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: BrutalColors.border,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: BrutalColors.border,
              offset: Offset(offsetVal, offsetVal),
              blurRadius: 0.0,
            ),
          ],
        ),
        child: Center(child: widget.child),
      ),
    );
  }
}
