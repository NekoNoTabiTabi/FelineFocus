import 'package:flutter/material.dart';

enum OverlayType {
  blocking,
  completion,
}

class OverlayManager {
  static OverlayType currentType = OverlayType.blocking;
  
  static void setOverlayType(OverlayType type) {
    currentType = type;
    debugPrint("🔄 Overlay type set to: $type");
  }
}