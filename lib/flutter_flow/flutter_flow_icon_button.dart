import 'package:flutter/material.dart';

class FlutterFlowIconButton extends StatelessWidget {
  final double? buttonSize;
  final double? borderRadius;
  final Widget icon;
  final VoidCallback? onPressed;

  const FlutterFlowIconButton({
    super.key,
    this.buttonSize,
    this.borderRadius,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 8),
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: icon,
        ),
      ),
    );
  }
}

