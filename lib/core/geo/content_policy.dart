/// Firebase Remote Config Key: geo_policy_overrides
///
/// This key allows updating regional policies without an app release.
///
/// Expected Structure:
/// {
///   "AE": { "allowLGBTQContent": false },
///   "US": { "allowLGBTQContent": true }
/// }
library;

import 'geo_compliance_service.dart';

class ContentPolicy {
  ContentPolicy({
    required this.allowLGBTQContent,
    required this.allowAlcoholReferences,
    required this.allowDatingFeatures,
    required this.allowGamblingContent,
  });

  /// Factory to get policy for a specific region
  factory ContentPolicy.forRegion(ContentRegion region) {
    switch (region) {
      case ContentRegion.middleEast:
        return ContentPolicy(
          allowLGBTQContent: false,
          allowAlcoholReferences: false,
          allowDatingFeatures: false,
          allowGamblingContent: false,
        );

      case ContentRegion.southeastAsia:
        // Conservative Southeast Asian countries (ID, MY, BN)
        return ContentPolicy(
          allowLGBTQContent: false,
          allowAlcoholReferences: false,
          allowDatingFeatures: true, // Dating usually allowed but monitored
          allowGamblingContent: false,
        );

      case ContentRegion.russia:
        return ContentPolicy(
          allowLGBTQContent: false, // "LGBT propaganda" law
          allowAlcoholReferences: true,
          allowDatingFeatures: true,
          allowGamblingContent: false,
        );

      case ContentRegion.china:
        return ContentPolicy(
          allowLGBTQContent: false,
          allowAlcoholReferences: true,
          allowDatingFeatures: true,
          allowGamblingContent: false, // Gambling is illegal in mainland China
        );

      case ContentRegion.global:
      default:
        return ContentPolicy(
          allowLGBTQContent: true,
          allowAlcoholReferences: true,
          allowDatingFeatures: true,
          allowGamblingContent: true,
        );
    }
  }
  final bool allowLGBTQContent;
  final bool allowAlcoholReferences;
  final bool allowDatingFeatures;
  final bool allowGamblingContent;

  /// Creates a copy of this policy with some overrides
  ContentPolicy copyWith({
    bool? allowLGBTQContent,
    bool? allowAlcoholReferences,
    bool? allowDatingFeatures,
    bool? allowGamblingContent,
  }) =>
      ContentPolicy(
        allowLGBTQContent: allowLGBTQContent ?? this.allowLGBTQContent,
        allowAlcoholReferences:
            allowAlcoholReferences ?? this.allowAlcoholReferences,
        allowDatingFeatures: allowDatingFeatures ?? this.allowDatingFeatures,
        allowGamblingContent: allowGamblingContent ?? this.allowGamblingContent,
      );
}
