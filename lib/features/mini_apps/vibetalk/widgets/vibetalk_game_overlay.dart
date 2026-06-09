import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../models/vibe_game.dart';
import '../providers/vibetalk_providers.dart';

class VibeTalkGameOverlay extends ConsumerWidget {
  const VibeTalkGameOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vibeState = ref.watch(vibeTalkProvider);
    final game = vibeState.activeGame;
    
    if (game == null) return const SizedBox.shrink();

    return Positioned(
      top: 100, // Show below the headers
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          tween: Tween(begin: 0, end: 1),
          builder: (context, value, child) => Transform.translate(
              offset: Offset(0, -20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.accent.withValues(alpha: 0.3), width: 1),
              boxShadow: [
                BoxShadow(
                  color: context.accent.withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getGameTitle(game.type),
                      style: TextStyle(
                        color: context.accent,
                        fontWeight: bold,
                        fontSize: 14,
                      ),
                    ),
                IconButton(
                  icon: Icon(Icons.close, color: context.textSecondary, size: 20),
                  onPressed: () {
                    // End or clear game
                    ref.read(vibeTalkProvider.notifier).endGame();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              ],
            ),
            const SizedBox(height: 12),
            Text(
              game.prompt,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
                const SizedBox(height: 16),
                _buildGameInteractions(context, ref, vibeState, game),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getGameTitle(String type) {
    switch (type) {
      case 'this_or_that': return 'This or That ⚖️';
      case 'icebreaker': return 'Icebreaker 🧊';
      case 'emoji_guess': return 'Emoji Guess 🤔';
      case 'tongue_twister': return 'Tongue Twister 👅';
      case 'voice_story': return '30s Story 📖';
      case 'voice_dare': return 'Voice Dare 🎤';
      case 'truth_or_dare': return 'Truth or Dare 😈';
      default: return 'Mini Game 🎮';
    }
  }

  Widget _buildGameInteractions(BuildContext context, WidgetRef ref, VibeTalkState state, VibeGameContext game) {
    final currentUserId = state.currentUserId ?? '';
    final hasAnswered = game.userAnswers.containsKey(currentUserId);
    final bothAnswered = game.userAnswers.length >= 2;

    if (game.type == 'this_or_that') {
      if (bothAnswered) {
         // Show results
         return Column(
           children: game.userAnswers.entries.map((e) {
             final isMe = e.key == currentUserId;
             return Padding(
               padding: const EdgeInsets.symmetric(vertical: 4),
               child: Text(
                 "${isMe ? 'You' : 'Stranger'}: ${e.value}",
                 style: TextStyle(color: isMe ? context.accent : context.textSecondary),
               ),
             );
           }).toList()..add(
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: context.divider),
                  onPressed: () {
                     // Next game
                     ref.read(vibeTalkProvider.notifier).startGame('this_or_that');
                  },
                  child: Text('Next Round', style: TextStyle(color: context.textPrimary)),
                ),
              )
            ),
         );
      }

      if (hasAnswered) {
        return Center(child: Text('Waiting for stranger...', style: TextStyle(color: context.textSecondary, fontStyle: FontStyle.italic)));
      }

      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent.withValues(alpha: 0.8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => ref.read(vibeTalkProvider.notifier).submitGameAnswer(game.optionA ?? 'A'),
                  child: Text(game.optionA ?? 'Option A', style: const TextStyle(color: Colors.white), textAlign: TextAlign.center,),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent.withValues(alpha: 0.8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => ref.read(vibeTalkProvider.notifier).submitGameAnswer(game.optionB ?? 'B'),
                  child: Text(game.optionB ?? 'Option B', style: const TextStyle(color: Colors.white), textAlign: TextAlign.center,),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => ref.read(vibeTalkProvider.notifier).startGame('this_or_that'),
            child: Text('Skip', style: TextStyle(color: context.textSecondary)),
          ),
        ],
      );
    }
    
    // For Icebreaker, Voice games, display a "Next" or "I did it" button
    if (game.type == 'icebreaker' || game.type.startsWith('voice_') || game.type == 'tongue_twister' || game.type == 'truth_or_dare') {
       return Wrap(
         spacing: 12,
         children: [
           OutlinedButton(
             style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white30)),
             onPressed: () => ref.read(vibeTalkProvider.notifier).endGame(),
             child: const Text('End'),
           ),
           ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: context.accent),
              onPressed: () => ref.read(vibeTalkProvider.notifier).startGame(game.type),
              child: const Text('Next Prompt', style: TextStyle(color: Colors.white)),
           ),
         ]
       );
    }

    if (game.type == 'emoji_guess') {
      if (hasAnswered || bothAnswered) {
        return Text('Answer: ${game.answer}', style: const TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold));
      }
      return ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
        onPressed: () => ref.read(vibeTalkProvider.notifier).submitGameAnswer('revealed'),
        child: const Text('Reveal Answer', style: TextStyle(color: Colors.white)),
      );
    }

    return const SizedBox();
  }
}

const FontWeight bold = FontWeight.bold;

