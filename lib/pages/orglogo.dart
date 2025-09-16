import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class OrgLogo extends StatelessWidget {
  final double radius;               // e.g., 50
  final String? base64Image;         // optional Base64 for web
  final String? filePath;            // optional file path for mobile
  final Widget? placeholder;         // optional placeholder icon

  const OrgLogo({
    super.key,
    required this.radius,
    this.base64Image,
    this.filePath,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final double size = radius * 2;

    Widget inner;
    if (kIsWeb) {
      if (base64Image != null && base64Image!.isNotEmpty) {
        final Uint8List bytes = base64Decode(base64Image!); // Base64 -> bytes [9]
        inner = ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.memory(bytes, fit: BoxFit.cover, width: size, height: size),
        );
      } else {
        inner = placeholder ??
            const Icon(Icons.business, color: Colors.white, size: 24);
      }
    } else {
      if (filePath != null) {
        inner = ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.file(File(filePath!), fit: BoxFit.cover, width: size, height: size),
        );
      } else if (base64Image != null && base64Image!.isNotEmpty) {
        final Uint8List bytes = base64Decode(base64Image!);
        inner = ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.memory(bytes, fit: BoxFit.cover, width: size, height: size),
        );
      } else {
        inner = placeholder ??
            const Icon(Icons.business, color: Colors.white, size: 24);
      }
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFE94560), Color(0xFFD63384)],
        ),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: inner,
    );
  }
}
