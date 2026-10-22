import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CalcButton extends StatelessWidget {
  final String? text;
  final Widget? icon;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final double fontSize;
  final int flex;

  const CalcButton({
    super.key,
    this.text,
    this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
    this.onLongPress,
    this.fontSize = 28,
    this.flex = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            onLongPress: () {
              if (onLongPress != null) {
                HapticFeedback.mediumImpact();
                onLongPress!();
              }
            },
            child: Container(
              height: 64,
              constraints: const BoxConstraints(minHeight: 44, maxHeight: 72),
              alignment: Alignment.center,
              child: icon ??
                  Text(
                    text ?? '',
                    style: TextStyle(
                      color: textColor,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
