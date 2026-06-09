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
    this.textAlign = TextAlign.center,
    this.hasBackground = false,
    this.fontSize = 24.0,
  });
  final String id;
  final EditableItemType type;
  final String value;
  Offset position;
  double scale;
  double rotation;
  Color? color;
  TextStyle? style;

  final TextAlign textAlign;
  final bool hasBackground;
  final double fontSize;

  EditableItem copyWith({
    String? id,
    EditableItemType? type,
    String? value,
    Offset? position,
    double? scale,
    double? rotation,
    Color? color,
    TextStyle? style,
    TextAlign? textAlign,
    bool? hasBackground,
    double? fontSize,
  }) => EditableItem(
      id: id ?? this.id,
      type: type ?? this.type,
      value: value ?? this.value,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      color: color ?? this.color,
      style: style ?? this.style,
      textAlign: textAlign ?? this.textAlign,
      hasBackground: hasBackground ?? this.hasBackground,
      fontSize: fontSize ?? this.fontSize,
    );
}
