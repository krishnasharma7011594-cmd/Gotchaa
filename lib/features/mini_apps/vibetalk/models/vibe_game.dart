class VibeGameContext { // store answers e.g. {uid: "Pizza"}

  const VibeGameContext({
    required this.id,
    required this.type,
    required this.prompt,
    required this.initiatorId,
    this.optionA,
    this.optionB,
    this.answer,
    this.userAnswers = const {},
  });

  factory VibeGameContext.fromMap(Map<String, dynamic> map) => VibeGameContext(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      prompt: map['prompt'] ?? '',
      optionA: map['optionA'],
      optionB: map['optionB'],
      answer: map['answer'],
      initiatorId: map['initiatorId'] ?? '',
      userAnswers: Map<String, dynamic>.from(map['userAnswers'] ?? {}),
    );
  final String id;
  final String type; // 'icebreaker', 'this_or_that', 'rapid_fire', 'emoji_guess', 'truth_or_dare', 'tongue_twister', 'voice_story', 'voice_dare'
  final String prompt;
  final String? optionA;
  final String? optionB;
  final String? answer;
  final String initiatorId;
  final Map<String, dynamic> userAnswers;

  Map<String, dynamic> toMap() => {
      'id': id,
      'type': type,
      'prompt': prompt,
      'optionA': optionA,
      'optionB': optionB,
      'answer': answer,
      'initiatorId': initiatorId,
      'userAnswers': userAnswers,
    };
}
