import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/editable_item.dart';

class EditableItemWidget extends StatefulWidget {

  const EditableItemWidget({
    required this.item, required this.onTap, required this.onDoubleTap, required this.onUpdate, super.key,
    this.isSelected = false,
    this.onDelete,
    this.onDragStart,
    this.onDragEnd,
  });
  final EditableItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final VoidCallback? onDelete;
  final Function(EditableItem) onUpdate;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;

  @override
  State<EditableItemWidget> createState() => _EditableItemWidgetState();
}

class _EditableItemWidgetState extends State<EditableItemWidget> {
  late Offset _initialPosition;
  late double _initialScale;
  late double _initialRotation;
  late Offset _initialFocalPoint;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Positioned(
      // The position in the model is the CENTER of the item
      left: widget.item.position.dx - 150, // Large enough canvas for rotation
      top: widget.item.position.dy - 100,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        onScaleStart: (details) {
          _initialPosition = widget.item.position;
          _initialScale = widget.item.scale;
          _initialRotation = widget.item.rotation;
          _initialFocalPoint = details.focalPoint;
          widget.onDragStart?.call();
          HapticFeedback.lightImpact();
        },
        onScaleUpdate: (details) {
          // 1. Precise Scaling & Rotation
          final newScale = (_initialScale * details.scale).clamp(0.4, 6.0);
          final newRotation = _initialRotation + details.rotation;

          // 2. Precise Movement
          final delta = details.focalPoint - _initialFocalPoint;
          double x = _initialPosition.dx + delta.dx;
          double y = _initialPosition.dy + delta.dy;

          // 3. Instagram-like Snap Physics
          const snapThreshold = 15.0;
          bool snapped = false;
          
          if ((x - screenSize.width / 2).abs() < snapThreshold) {
            x = screenSize.width / 2;
            snapped = true;
          }
          if ((y - screenSize.height / 2).abs() < snapThreshold) {
            y = screenSize.height / 2;
            snapped = true;
          }

          if (snapped) {
            // HapticFeedback.selectionClick(); // Could be too annoying if frequent, but user wants smooth
          }

          final newPosition = Offset(x, y);

          widget.onUpdate(widget.item.copyWith(
            position: newPosition,
            scale: details.pointerCount > 1 ? newScale : widget.item.scale,
            rotation: details.pointerCount > 1 ? newRotation : widget.item.rotation,
          ));
        },
        onScaleEnd: (details) {
          widget.onDragEnd?.call();
        },
        child: Container(
          width: 300,
          height: 200,
          alignment: Alignment.center,
          color: Colors.transparent, // Important for hit-testing
          child: Transform.rotate(
            angle: widget.item.rotation,
            child: Transform.scale(
              scale: widget.item.scale,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Bounding Box
                  if (widget.isSelected)
                    Positioned.fill(
                      child: Container(
                        margin: const EdgeInsets.all(-8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  
                  // Content
                  _buildContent(),

                  // Handles
                  if (widget.isSelected) ...[
                    Positioned(
                      top: -25,
                      right: -25,
                      child: _buildHandle(Icons.close, Colors.black87, widget.onDelete),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHandle(IconData icon, Color color, VoidCallback? onTap) => GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );

  Widget _buildContent() {
    switch (widget.item.type) {
      case EditableItemType.text:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: widget.item.hasBackground
              ? BoxDecoration(
                  color: (widget.item.color ?? Colors.black).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: Text(
            widget.item.value,
            textAlign: widget.item.textAlign,
            style: widget.item.style?.copyWith(
                  color: widget.item.hasBackground ? Colors.white : widget.item.color,
                  fontSize: widget.item.fontSize,
                ) ??
                TextStyle(
                  color: widget.item.hasBackground ? Colors.white : (widget.item.color ?? Colors.white),
                  fontSize: widget.item.fontSize,
                  fontWeight: FontWeight.bold,
                ),
          ),
        );
      case EditableItemType.sticker:
        return Text(
          widget.item.value,
          style: TextStyle(fontSize: widget.item.fontSize * 2),
        );
      case EditableItemType.tag:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.alternate_email_rounded, size: 16, color: Colors.blue),
              const SizedBox(width: 6),
              Text(
                widget.item.value,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
    }
  }
}
