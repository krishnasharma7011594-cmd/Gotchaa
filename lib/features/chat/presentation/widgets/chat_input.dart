import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class ChatInput extends StatelessWidget {

  const ChatInput({
    required this.controller, required this.onChanged, required this.onSend, required this.onMediaPick, super.key,
  });
  final TextEditingController controller;
  final Function(String) onChanged;
  final VoidCallback onSend;
  final Function(ImageSource, {bool isVideo}) onMediaPick;

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 30),
      decoration: BoxDecoration(
        color: context.surface,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: context.surface,
                builder: (context) => Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.image, color: Colors.purple),
                        title: Text(context.tr('chat_image_gallery')),
                        onTap: () {
                          Navigator.pop(context);
                          onMediaPick(ImageSource.gallery);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.videocam, color: Colors.blue),
                        title: Text(context.tr('chat_video_gallery')),
                        onTap: () {
                          Navigator.pop(context);
                          onMediaPick(ImageSource.gallery, isVideo: true);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add, color: AppColors.electricBlue),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: context.inputFill,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: context.tr('chat_type_message'),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSend,
            child: const CircleAvatar(
              backgroundColor: AppColors.electricBlue,
              radius: 22,
              child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
}

