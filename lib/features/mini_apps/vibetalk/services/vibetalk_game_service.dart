import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/vibe_game.dart';

class VibeTalkGameService {
  static final _random = Random();
  static const _uuid = Uuid();

  static const List<String> _icebreakers = [
    'Would you rather be rich or famous?',
    "What's your biggest fear?",
    'If you could travel anywhere, where would you go?',
    "What's the best piece of advice you've ever received?",
    'If you had to eat one meal everyday for the rest of your life, what would it be?',
    "What's your favorite movie of all time?",
    "If you could have any superpower, what would it be?",
    "What's the most adventurous thing you've ever done?",
    "What's your dream job?",
    "If you could meet any historical figure, who would it be?",
  ];

  static const List<Map<String, String>> _thisOrThat = [
    {'q': 'Pizza or Burger?', 'a': 'Pizza 🍕', 'b': 'Burger 🍔'},
    {'q': 'Morning Person or Night Owl?', 'a': 'Morning ☀️', 'b': 'Night 🌙'},
    {'q': 'Coffee or Tea?', 'a': 'Coffee ☕', 'b': 'Tea 🍵'},
    {'q': 'Mountains or Beach?', 'a': 'Mountains 🏔️', 'b': 'Beach 🏖️'},
    {'q': 'Netflix or YouTube?', 'a': 'Netflix 🎬', 'b': 'YouTube ▶️'},
    {'q': 'Android or iOS?', 'a': 'Android 🤖', 'b': 'iOS 🍎'},
    {'q': 'Marvel or DC?', 'a': 'Marvel 🦸', 'b': 'DC 🦇'},
    {'q': 'Dogs or Cats?', 'a': 'Dogs 🐶', 'b': 'Cats 🐱'},
    {'q': 'Summer or Winter?', 'a': 'Summer ☀️', 'b': 'Winter ❄️'},
    {'q': 'Book or Movie?', 'a': 'Book 📚', 'b': 'Movie 🎬'},
  ];

  static const List<Map<String, String>> _emojiGuess = [
    {'q': '🎬🦁👑', 'a': 'The Lion King'},
    {'q': '👨‍🚀🚀🥦🌚', 'a': 'Interstellar'},
    {'q': '🌍🦍🐒⚔️', 'a': 'Planet of the Apes'},
    {'q': '🤑💰👩‍🦰', 'a': 'Richie Rich'},
    {'q': '🌚🦇🏙️', 'a': 'Batman'},
    {'q': '👸🍎💤', 'a': 'Snow White'},
    {'q': '⚡👓🪄', 'a': 'Harry Potter'},
    {'q': '🤡🎈🩸', 'a': 'It'},
    {'q': '🐭🏰🎢', 'a': 'Disneyland'},
    {'q': '🛸👽🚲', 'a': 'E.T.'},
  ];

  static const List<String> _tongueTwisters = [
    'She sells seashells by the seashore.',
    'How much wood would a woodchuck chuck if a woodchuck could chuck wood?',
    'I saw Susie sitting in a shoeshine shop.',
    'Fuzzy Wuzzy was a bear. Fuzzy Wuzzy had no hair.',
    'Six slippery snails slid slowly seaward.',
    'Peter Piper picked a peck of pickled peppers.',
    'I scream, you scream, we all scream for ice cream.',
    'Red lorry, yellow lorry.',
    'A proper copper coffee pot.',
    'Rubber baby buggy bumpers.',
  ];

  static const List<String> _voiceStories = [
    'Make up a 30-second story about a time traveler meeting a dinosaur.',
    'Tell a quick 30-second story about the worst date ever.',
    'Invent a 30-second story about a person discovering they have a superpower.',
  ];

  static const List<String> _voiceDares = [
    'Speak like a robot 🤖 for 30 seconds.',
    'Imitate your favorite celebrity.',
    'Sing the chorus of your favorite song.',
    'Talk in a British accent for the next 30 seconds.',
    'Whisper your next message.',
  ];

  static const List<String> _truthOrDare = [
    "Truth: What's your most embarrassing childhood memory?",
    "Truth: What's a secret you've never told anyone online?",
    'Dare: Send a voice note doing your best animal impression.',
    "Dare: Close your eyes and type 'I love Gotchaa' without looking.",
    "Truth: What's the biggest lie you've ever told?",
    "Truth: Have you ever cheated on a test?",
    "Dare: Speak in a whisper for the next 2 minutes.",
    "Dare: Tell the other person a cheesy pickup line.",
  ];

  static VibeGameContext getRandomGame(String type, String initiatorId) {
    if (type == 'this_or_that') {
      final item = _thisOrThat[_random.nextInt(_thisOrThat.length)];
      return VibeGameContext(
        id: _uuid.v4(),
        type: type,
        prompt: item['q']!,
        optionA: item['a'],
        optionB: item['b'],
        initiatorId: initiatorId,
      );
    } else if (type == 'emoji_guess') {
      final item = _emojiGuess[_random.nextInt(_emojiGuess.length)];
      return VibeGameContext(
        id: _uuid.v4(),
        type: type,
        prompt: "Guess the Movie: ${item["q"]!}",
        answer: item['a'],
        initiatorId: initiatorId,
      );
    } else {
      String prompt = '';
      if (type == 'icebreaker') prompt = _icebreakers[_random.nextInt(_icebreakers.length)];
      if (type == 'tongue_twister') prompt = 'Voice Challenge: Say this fast 3 times!\n${_tongueTwisters[_random.nextInt(_tongueTwisters.length)]}';
      if (type == 'voice_story') prompt = 'Voice Challenge!\n${_voiceStories[_random.nextInt(_voiceStories.length)]}';
      if (type == 'voice_dare') prompt = 'Voice Dare!\n${_voiceDares[_random.nextInt(_voiceDares.length)]}';
      if (type == 'truth_or_dare') prompt = _truthOrDare[_random.nextInt(_truthOrDare.length)];
      
      return VibeGameContext(
        id: _uuid.v4(),
        type: type,
        prompt: prompt,
        initiatorId: initiatorId,
      );
    }
  }

  static List<String> get availableGameTypes => [
    'icebreaker',
    'this_or_that',
    'emoji_guess',
    'truth_or_dare',
    'tongue_twister',
    'voice_story',
    'voice_dare',
  ];

  static String getLabelForType(String type) {
    switch(type) {
      case 'icebreaker': return 'Icebreaker 🧊';
      case 'this_or_that': return 'This or That ⚖️';
      case 'emoji_guess': return 'Emoji Guess 🤔';
      case 'truth_or_dare': return 'Truth or Dare 😈';
      case 'tongue_twister': return 'Tongue Twister 👅';
      case 'voice_story': return '30s Story 📖';
      case 'voice_dare': return 'Voice Dare 🎤';
      default: return 'Game 🎮';
    }
  }
}
