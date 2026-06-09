enum AgeTier {
  under13Blocked,
  coppaLimited,
  junior, // 13-15
  teen, // 16-17
  adult, // 18+
  undetermined,
}

extension AgeTierExtension on AgeTier {
  bool get isBlocked => this == AgeTier.under13Blocked;
  bool get isCoppaLimited => this == AgeTier.coppaLimited;
  bool get isJunior => this == AgeTier.junior;
  bool get isTeen => this == AgeTier.teen;
  bool get isAdult => this == AgeTier.adult;

  bool get canUseVibeTalk => this == AgeTier.adult || this == AgeTier.undetermined || this == AgeTier.teen;
  bool get canStrangerChat => this == AgeTier.junior || this == AgeTier.teen || this == AgeTier.adult;
  bool get canBeDiscovered => this != AgeTier.under13Blocked && this != AgeTier.coppaLimited;
}

class AgeStatus {

  AgeStatus({
    required this.tier,
    this.dateOfBirth,
    this.isVerified = false,
  });

  factory AgeStatus.initial() => AgeStatus(tier: AgeTier.undetermined);
  final AgeTier tier;
  final DateTime? dateOfBirth;
  final bool isVerified;

  AgeStatus copyWith({
    AgeTier? tier,
    DateTime? dateOfBirth,
    bool? isVerified,
  }) => AgeStatus(
      tier: tier ?? this.tier,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      isVerified: isVerified ?? this.isVerified,
    );
}
