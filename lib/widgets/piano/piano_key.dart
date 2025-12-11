import 'package:flutter/material.dart';

class PianoKey extends StatelessWidget {
  final bool isBlackKey;
  final bool isPressed;
  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onTapUp;

  const PianoKey({
    super.key,
    this.isBlackKey = false,
    this.isPressed = false,
    this.label = '',
    this.onTap,
    this.onTapUp,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onTap?.call(),
      onTapUp: (_) => onTapUp?.call(),
      onTapCancel: () => onTapUp?.call(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: isPressed
              ? Colors.blueAccent
              : (isBlackKey ? Colors.black : Colors.white),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(4),
          ),
          border: Border.all(color: Colors.black87, width: 1),
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              label,
              style: TextStyle(
                color: isPressed
                    ? Colors.white
                    : (isBlackKey ? Colors.white : Colors.black),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
