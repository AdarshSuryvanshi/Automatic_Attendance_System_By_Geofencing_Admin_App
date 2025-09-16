import 'package:flutter/material.dart';

class FlutterFlowTheme {
  final Color primary;
  final Color info;
  final Color primaryBackground;
  final Color alternate;
  final TextStyle titleSmall;
  final TextStyle titleMedium;

  FlutterFlowTheme._({
    required this.primary,
    required this.info,
    required this.primaryBackground,
    required this.alternate,
    required this.titleSmall,
    required this.titleMedium,
  });

  static FlutterFlowTheme of(BuildContext context) {
    final theme = Theme.of(context);
    return FlutterFlowTheme._(
      primary: theme.colorScheme.primary,
      info: theme.colorScheme.secondary,
      primaryBackground: theme.scaffoldBackgroundColor,
      alternate: theme.dividerColor,
      titleSmall: theme.textTheme.titleSmall ?? const TextStyle(fontSize: 14),
      titleMedium:
          theme.textTheme.titleMedium ?? const TextStyle(fontSize: 18),
    );
  }
}

