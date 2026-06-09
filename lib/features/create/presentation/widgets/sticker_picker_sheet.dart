import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StickerPickerSheet extends StatelessWidget {
  const StickerPickerSheet({super.key});

  final List<String> emojis = const [
    '🔥',
    '❤️',
    '😂',
    '🫠',
    '🙌',
    '✨',
    '💀',
    '💯',
    '😍',
    '🥺',
    '😭',
    '🫣',
    '🫡',
    '🤯',
    '🥳',
    '😎',
    '🤩',
    '🥵',
    '🥶',
    '🎭',
    '🎨',
    '🎬',
    '🍿',
    '🎸',
    '🌈',
    '⚡',
    '🌙',
    '☀️',
    '🌸',
    '🦋',
    '🐶',
    '🐱',
    '🍕',
    '🍔',
    '🍦',
    '🍩',
    '🌍',
    '✈️',
    '🏝️',
    '🎮',
    '🚀',
    '💎',
    '💸',
    '👑',
    '✌️',
    '🤙',
    '🫶',
    '✅'
  ];

  @override
  Widget build(BuildContext context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    'Choose Sticker',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: emojis.length,
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () => Navigator.pop(context, emojis[index]),
                  child: Center(
                    child: Text(
                      emojis[index],
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
