import 'package:flutter/material.dart';

enum EditableItemType { text, sticker, tag }

class EditableItem {
  EditableItem({
    required this.id,
    required this.type,
    required this.value,
    required this.position,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.color,
    this.style,
  });
  final String id;
  final EditableItemType type;
  final dynamic value; // String for text/sticker, UserProfile for tag
  Offset position;
  double scale;
  double rotation;
  Color? color;
  TextStyle? style;
}
