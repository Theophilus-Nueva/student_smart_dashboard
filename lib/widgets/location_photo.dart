import 'dart:io';

import 'package:flutter/material.dart';

import '../models/tour.dart';

/// A tour location's photo: the one taken or picked in the app (saved on
/// the phone) if there is one, otherwise its bundled photo or the campus
/// photo.
class LocationPhoto extends StatelessWidget {
  const LocationPhoto({
    super.key,
    required this.location,
    this.height,
    this.width,
    this.borderRadius = 8,
  });

  final TourLocation location;
  final double? height;
  final double? width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final file = location.photoFile;
    final label = 'Photo of ${location.title}';
    final fallback = Image.asset(
      location.image,
      height: height,
      width: width,
      fit: BoxFit.cover,
      semanticLabel: label,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: file == null
          ? fallback
          : Image.file(
              File(file),
              height: height,
              width: width,
              fit: BoxFit.cover,
              semanticLabel: label,
              errorBuilder: (_, _, _) => fallback,
            ),
    );
  }
}
