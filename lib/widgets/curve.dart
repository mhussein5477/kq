import 'package:flutter/material.dart';

// Add this CustomClipper class for the curved button effect
class CurvedButtonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // Start from top-left with a curve
    path.moveTo(0, 20);

    // Curve inward on the left side
    path.quadraticBezierTo(
      0,
      0, // Control point
      20,
      0, // End point
    );

    // Top edge
    path.lineTo(size.width - 16, 0);

    // Top-right corner curve
    path.quadraticBezierTo(size.width, 0, size.width, 16);

    // Right edge
    path.lineTo(size.width, size.height - 16);

    // Bottom-right corner curve
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width - 16,
      size.height,
    );

    // Bottom edge
    path.lineTo(20, size.height);

    // Bottom-left corner curve
    path.quadraticBezierTo(0, size.height, 0, size.height - 20);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
