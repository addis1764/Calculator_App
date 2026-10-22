import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class CalcDisplay extends StatelessWidget {
  final String display;
  final String expression;
  final VoidCallback? onSecretTap;

  const CalcDisplay({
    super.key,
    required this.display,
    required this.expression,
    this.onSecretTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      color: AppTheme.calcDisplayBg,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Previous Expression
          if (expression.isNotEmpty)
            GestureDetector(
              onLongPress: onSecretTap,
              child: Text(
                expression,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          const SizedBox(height: 4),
          // Main Display Output
          Expanded(
            child: GestureDetector(
              onLongPress: onSecretTap,
              child: Align(
                alignment: Alignment.bottomRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomRight,
                  child: Text(
                    display,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 64,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
