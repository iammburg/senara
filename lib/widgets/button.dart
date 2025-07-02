import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;
  final String text;
  final double elevation;
  final double iconSize;
  final double fontSize;
  final String fontFamily;
  final FontWeight fontWeight;

  const CustomButton({
    super.key,
    required this.onPressed,
    required this.backgroundColor,
    this.foregroundColor = Colors.white,
    required this.icon,
    required this.text,
    this.elevation = 3.0,
    this.iconSize = 24.0,
    this.fontSize = 16.0,
    this.fontFamily = 'Lexend',
    this.fontWeight = FontWeight.w600,
  });

  factory CustomButton.scan({
    Key? key,
    required VoidCallback onPressed,
    required bool isScanning,
  }) {
    return CustomButton(
      key: key,
      onPressed: onPressed,
      backgroundColor: isScanning ? Colors.red : Colors.blue[700]!,
      foregroundColor: Colors.white,
      icon: isScanning ? Icons.stop : Icons.play_arrow,
      text: isScanning ? 'Stop Scan' : 'Mulai Scan',
    );
  }

  // Factory constructor for creating an upload button
  factory CustomButton.upload({
    Key? key,
    required VoidCallback onPressed,
  }) {
    return CustomButton(
      key: key,
      onPressed: onPressed,
      backgroundColor: Colors.orange[600]!,
      icon: Icons.upload_file,
      text: 'Upload Media',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: elevation,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: iconSize,
            color: foregroundColor,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
          ),
        ],
      ),
    );
  }
}
