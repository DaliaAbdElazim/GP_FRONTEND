// Clipper for the curved bottom of the red bar
import 'dart:ui';

import 'package:flutter/material.dart';

class CurvedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    // Start at top-left
    path.lineTo(0, size.height);
    // Draw line to almost bottom-right
    path.lineTo(size.width - 50, size.height);
    // Create curve for bottom-right corner
    path.quadraticBezierTo(
      size.width - 20,
      size.height,
      size.width,
      size.height - 20,
    );
    // Line to top-right
    path.lineTo(size.width, 0);
    // Back to start
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
