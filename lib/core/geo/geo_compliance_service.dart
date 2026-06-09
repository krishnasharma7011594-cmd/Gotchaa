enum ContentRegion { global, middleEast, southeastAsia, russia, china }

class GeoComplianceService {
  factory GeoComplianceService() => _instance;
  GeoComplianceService._internal();
  static final GeoComplianceService _instance =
      GeoComplianceService._internal();

  // Hardcoded map of ISO country codes to regions
  final Map<String, ContentRegion> _countryToRegionMap = {
    // Middle East
    'SA': ContentRegion.middleEast,
    'AE': ContentRegion.middleEast,
    'QA': ContentRegion.middleEast,
    'KW': ContentRegion.middleEast,
    'BH': ContentRegion.middleEast,
    'OM': ContentRegion.middleEast,
    'IR': ContentRegion.middleEast,
    'IQ': ContentRegion.middleEast,
    'JO': ContentRegion.middleEast,
    'EG': ContentRegion.middleEast,
    'LY': ContentRegion.middleEast,
    'MA': ContentRegion.middleEast,
    'TN': ContentRegion.middleEast,
    'DZ': ContentRegion.middleEast,
    'YE': ContentRegion.middleEast,
    'SY': ContentRegion.middleEast,

    // Southeast Asia (Restricted parts)
    'ID': ContentRegion.southeastAsia,
    'MY': ContentRegion.southeastAsia,
    'BN': ContentRegion.southeastAsia,

    // Others
    'RU': ContentRegion.russia,
    'CN': ContentRegion.china,
  };

  /// Gets the region for a given country code (ISO 2-letter)
  ContentRegion getRegionForCountry(String countryCode) {
    final upperCode = countryCode.toUpperCase().trim();
    return _countryToRegionMap[upperCode] ?? ContentRegion.global;
  }
}
