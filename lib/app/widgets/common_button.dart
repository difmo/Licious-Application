import 'package:flutter/material.dart';

class CommonButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final double borderRadius;
  final double height;
  final Widget? icon;
  final bool isLoading;

  const CommonButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = const Color(0xFF438E5A),
    this.textColor = Colors.white,
    this.borderRadius = 8.0,
    this.height = 54.0,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: textColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      elevation: 0,
      padding: icon != null ? const EdgeInsets.symmetric(vertical: 16) : null,
    );

    final widgetContent = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              color: textColor,
              strokeWidth: 2,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: TextStyle(
                  fontSize: icon != null ? 15 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        style: style,
        onPressed: isLoading ? null : onPressed,
        child: widgetContent,
      ),
    );
  }
}
