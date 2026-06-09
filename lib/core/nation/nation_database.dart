// ignore_for_file: constant_identifier_names
import 'nation_data.dart';

/// Static database of all 195 UN-recognised countries.
/// Zero internet, zero API, instant constant-time lookup.
class NationDatabase {
  NationDatabase._();

  // ── Flag emoji generator ──────────────────────────────────────────────────
  static String flagFromCode(String iso2) {
    if (iso2.length != 2) return '🌍';
    final a = iso2.toUpperCase().codeUnitAt(0) - 65 + 0x1F1E6;
    final b = iso2.toUpperCase().codeUnitAt(1) - 65 + 0x1F1E6;
    return String.fromCharCode(a) + String.fromCharCode(b);
  }

  // ── Master country table ──────────────────────────────────────────────────
  // Format: code → [countryName, countryNameLocal, continent, timezone, currencyCode, currencySymbol, primaryLanguage, languageCode]
  static const Map<String, List<String>> _db = {
    'AF': ['Afghanistan','افغانستان','Asia','Asia/Kabul','AFN','؋','Dari','fa'],
    'AL': ['Albania','Shqipëri','Europe','Europe/Tirane','ALL','L','Albanian','sq'],
    'DZ': ['Algeria','الجزائر','Africa','Africa/Algiers','DZD','دج','Arabic','ar'],
    'AD': ['Andorra','Andorra','Europe','Europe/Andorra','EUR','€','Catalan','ca'],
    'AO': ['Angola','Angola','Africa','Africa/Luanda','AOA','Kz','Portuguese','pt'],
    'AG': ['Antigua and Barbuda','Antigua and Barbuda','Americas','America/Antigua','XCD',r'$','English','en'],
    'AR': ['Argentina','Argentina','Americas','America/Argentina/Buenos_Aires','ARS',r'$','Spanish','es'],
    'AM': ['Armenia','Հայաստան','Asia','Asia/Yerevan','AMD','֏','Armenian','hy'],
    'AU': ['Australia','Australia','Oceania','Australia/Sydney','AUD',r'$','English','en'],
    'AT': ['Austria','Österreich','Europe','Europe/Vienna','EUR','€','German','de'],
    'AZ': ['Azerbaijan','Azərbaycan','Asia','Asia/Baku','AZN','₼','Azerbaijani','az'],
    'BS': ['Bahamas','Bahamas','Americas','America/Nassau','BSD',r'$','English','en'],
    'BH': ['Bahrain','البحرين','Asia','Asia/Bahrain','BHD','BD','Arabic','ar'],
    'BD': ['Bangladesh','বাংলাদেশ','Asia','Asia/Dhaka','BDT','৳','Bengali','bn'],
    'BB': ['Barbados','Barbados','Americas','America/Barbados','BBD',r'$','English','en'],
    'BY': ['Belarus','Беларусь','Europe','Europe/Minsk','BYN','Br','Belarusian','be'],
    'BE': ['Belgium','België','Europe','Europe/Brussels','EUR','€','Dutch','nl'],
    'BZ': ['Belize','Belize','Americas','America/Belize','BZD',r'$','English','en'],
    'BJ': ['Benin','Bénin','Africa','Africa/Porto-Novo','XOF','Fr','French','fr'],
    'BT': ['Bhutan','འབྲུག','Asia','Asia/Thimphu','BTN','Nu','Dzongkha','dz'],
    'BO': ['Bolivia','Bolivia','Americas','America/La_Paz','BOB','Bs','Spanish','es'],
    'BA': ['Bosnia and Herzegovina','Bosna i Hercegovina','Europe','Europe/Sarajevo','BAM','KM','Bosnian','bs'],
    'BW': ['Botswana','Botswana','Africa','Africa/Gaborone','BWP','P','Tswana','tn'],
    'BR': ['Brazil','Brasil','Americas','America/Sao_Paulo','BRL',r'R$','Portuguese','pt'],
    'BN': ['Brunei','Brunei','Asia','Asia/Brunei','BND',r'$','Malay','ms'],
    'BG': ['Bulgaria','България','Europe','Europe/Sofia','BGN','лв','Bulgarian','bg'],
    'BF': ['Burkina Faso','Burkina Faso','Africa','Africa/Ouagadougou','XOF','Fr','French','fr'],
    'BI': ['Burundi','Burundi','Africa','Africa/Bujumbura','BIF','Fr','Kirundi','rn'],
    'CV': ['Cape Verde','Cabo Verde','Africa','Atlantic/Cape_Verde','CVE',r'$','Portuguese','pt'],
    'KH': ['Cambodia','កម្ពុជា','Asia','Asia/Phnom_Penh','KHR','៛','Khmer','km'],
    'CM': ['Cameroon','Cameroun','Africa','Africa/Douala','XAF','Fr','French','fr'],
    'CA': ['Canada','Canada','Americas','America/Toronto','CAD',r'$','English','en'],
    'CF': ['Central African Republic','République centrafricaine','Africa','Africa/Bangui','XAF','Fr','French','fr'],
    'TD': ['Chad','Tchad','Africa','Africa/Ndjamena','XAF','Fr','French','fr'],
    'CL': ['Chile','Chile','Americas','America/Santiago','CLP',r'$','Spanish','es'],
    'CN': ['China','中国','Asia','Asia/Shanghai','CNY','¥','Mandarin','zh'],
    'CO': ['Colombia','Colombia','Americas','America/Bogota','COP',r'$','Spanish','es'],
    'KM': ['Comoros','Comores','Africa','Indian/Comoro','KMF','Fr','Comorian','sw'],
    'CG': ['Congo','Congo','Africa','Africa/Brazzaville','XAF','Fr','French','fr'],
    'CD': ['DR Congo','RDC','Africa','Africa/Kinshasa','CDF','Fr','French','fr'],
    'CR': ['Costa Rica','Costa Rica','Americas','America/Costa_Rica','CRC','₡','Spanish','es'],
    'HR': ['Croatia','Hrvatska','Europe','Europe/Zagreb','EUR','€','Croatian','hr'],
    'CU': ['Cuba','Cuba','Americas','America/Havana','CUP',r'$','Spanish','es'],
    'CY': ['Cyprus','Κύπρος','Europe','Asia/Nicosia','EUR','€','Greek','el'],
    'CZ': ['Czech Republic','Česká republika','Europe','Europe/Prague','CZK','Kč','Czech','cs'],
    'DK': ['Denmark','Danmark','Europe','Europe/Copenhagen','DKK','kr','Danish','da'],
    'DJ': ['Djibouti','Djibouti','Africa','Africa/Djibouti','DJF','Fr','French','fr'],
    'DM': ['Dominica','Dominica','Americas','America/Dominica','XCD',r'$','English','en'],
    'DO': ['Dominican Republic','República Dominicana','Americas','America/Santo_Domingo','DOP',r'$','Spanish','es'],
    'EC': ['Ecuador','Ecuador','Americas','America/Guayaquil','USD',r'$','Spanish','es'],
    'EG': ['Egypt','مصر','Africa','Africa/Cairo','EGP','£','Arabic','ar'],
    'SV': ['El Salvador','El Salvador','Americas','America/El_Salvador','USD',r'$','Spanish','es'],
    'GQ': ['Equatorial Guinea','Guinea Ecuatorial','Africa','Africa/Malabo','XAF','Fr','Spanish','es'],
    'ER': ['Eritrea','ኤርትራ','Africa','Africa/Asmara','ERN','Nfk','Tigrinya','ti'],
    'EE': ['Estonia','Eesti','Europe','Europe/Tallinn','EUR','€','Estonian','et'],
    'SZ': ['Eswatini','Eswatini','Africa','Africa/Mbabane','SZL','L','Swati','ss'],
    'ET': ['Ethiopia','ኢትዮጵያ','Africa','Africa/Addis_Ababa','ETB','Br','Amharic','am'],
    'FJ': ['Fiji','Fiji','Oceania','Pacific/Fiji','FJD',r'$','English','en'],
    'FI': ['Finland','Suomi','Europe','Europe/Helsinki','EUR','€','Finnish','fi'],
    'FR': ['France','France','Europe','Europe/Paris','EUR','€','French','fr'],
    'GA': ['Gabon','Gabon','Africa','Africa/Libreville','XAF','Fr','French','fr'],
    'GM': ['Gambia','Gambia','Africa','Africa/Banjul','GMD','D','English','en'],
    'GE': ['Georgia','საქართველო','Asia','Asia/Tbilisi','GEL','₾','Georgian','ka'],
    'DE': ['Germany','Deutschland','Europe','Europe/Berlin','EUR','€','German','de'],
    'GH': ['Ghana','Ghana','Africa','Africa/Accra','GHS','₵','English','en'],
    'GR': ['Greece','Ελλάδα','Europe','Europe/Athens','EUR','€','Greek','el'],
    'GD': ['Grenada','Grenada','Americas','America/Grenada','XCD',r'$','English','en'],
    'GT': ['Guatemala','Guatemala','Americas','America/Guatemala','GTQ','Q','Spanish','es'],
    'GN': ['Guinea','Guinée','Africa','Africa/Conakry','GNF','Fr','French','fr'],
    'GW': ['Guinea-Bissau','Guiné-Bissau','Africa','Africa/Bissau','XOF','Fr','Portuguese','pt'],
    'GY': ['Guyana','Guyana','Americas','America/Guyana','GYD',r'$','English','en'],
    'HT': ['Haiti','Haïti','Americas','America/Port-au-Prince','HTG','G','French','fr'],
    'HN': ['Honduras','Honduras','Americas','America/Tegucigalpa','HNL','L','Spanish','es'],
    'HU': ['Hungary','Magyarország','Europe','Europe/Budapest','HUF','Ft','Hungarian','hu'],
    'IS': ['Iceland','Ísland','Europe','Atlantic/Reykjavik','ISK','kr','Icelandic','is'],
    'IN': ['India','भारत','Asia','Asia/Kolkata','INR','₹','Hindi','hi'],
    'ID': ['Indonesia','Indonesia','Asia','Asia/Jakarta','IDR','Rp','Indonesian','id'],
    'IR': ['Iran','ایران','Asia','Asia/Tehran','IRR','﷼','Persian','fa'],
    'IQ': ['Iraq','العراق','Asia','Asia/Baghdad','IQD','ع.د','Arabic','ar'],
    'IE': ['Ireland','Éire','Europe','Europe/Dublin','EUR','€','English','en'],
    'IL': ['Israel','ישראל','Asia','Asia/Jerusalem','ILS','₪','Hebrew','he'],
    'IT': ['Italy','Italia','Europe','Europe/Rome','EUR','€','Italian','it'],
    'JM': ['Jamaica','Jamaica','Americas','America/Jamaica','JMD',r'$','English','en'],
    'JP': ['Japan','日本','Asia','Asia/Tokyo','JPY','¥','Japanese','ja'],
    'JO': ['Jordan','الأردن','Asia','Asia/Amman','JOD','JD','Arabic','ar'],
    'KZ': ['Kazakhstan','Қазақстан','Asia','Asia/Almaty','KZT','₸','Kazakh','kk'],
    'KE': ['Kenya','Kenya','Africa','Africa/Nairobi','KES','Ksh','Swahili','sw'],
    'KI': ['Kiribati','Kiribati','Oceania','Pacific/Tarawa','AUD',r'$','English','en'],
    'KP': ['North Korea','조선','Asia','Asia/Pyongyang','KPW','₩','Korean','ko'],
    'KR': ['South Korea','한국','Asia','Asia/Seoul','KRW','₩','Korean','ko'],
    'KW': ['Kuwait','الكويت','Asia','Asia/Kuwait','KWD','KD','Arabic','ar'],
    'KG': ['Kyrgyzstan','Кыргызстан','Asia','Asia/Bishkek','KGS','лв','Kyrgyz','ky'],
    'LA': ['Laos','ລາວ','Asia','Asia/Vientiane','LAK','₭','Lao','lo'],
    'LV': ['Latvia','Latvija','Europe','Europe/Riga','EUR','€','Latvian','lv'],
    'LB': ['Lebanon','لبنان','Asia','Asia/Beirut','LBP','£','Arabic','ar'],
    'LS': ['Lesotho','Lesotho','Africa','Africa/Maseru','LSL','L','Sesotho','st'],
    'LR': ['Liberia','Liberia','Africa','Africa/Monrovia','LRD',r'$','English','en'],
    'LY': ['Libya','ليبيا','Africa','Africa/Tripoli','LYD','LD','Arabic','ar'],
    'LI': ['Liechtenstein','Liechtenstein','Europe','Europe/Vaduz','CHF','Fr','German','de'],
    'LT': ['Lithuania','Lietuva','Europe','Europe/Vilnius','EUR','€','Lithuanian','lt'],
    'LU': ['Luxembourg','Lëtzebuerg','Europe','Europe/Luxembourg','EUR','€','Luxembourgish','lb'],
    'MG': ['Madagascar','Madagascar','Africa','Indian/Antananarivo','MGA','Ar','Malagasy','mg'],
    'MW': ['Malawi','Malawi','Africa','Africa/Blantyre','MWK','MK','Chichewa','ny'],
    'MY': ['Malaysia','Malaysia','Asia','Asia/Kuala_Lumpur','MYR','RM','Malay','ms'],
    'MV': ['Maldives','ދިވެހިރާއްޖެ','Asia','Indian/Maldives','MVR','Rf','Dhivehi','dv'],
    'ML': ['Mali','Mali','Africa','Africa/Bamako','XOF','Fr','French','fr'],
    'MT': ['Malta','Malta','Europe','Europe/Malta','EUR','€','Maltese','mt'],
    'MH': ['Marshall Islands','Marshall Islands','Oceania','Pacific/Majuro','USD',r'$','Marshallese','mh'],
    'MR': ['Mauritania','موريتانيا','Africa','Africa/Nouakchott','MRU','UM','Arabic','ar'],
    'MU': ['Mauritius','Maurice','Africa','Indian/Mauritius','MUR','₨','English','en'],
    'MX': ['Mexico','México','Americas','America/Mexico_City','MXN',r'$','Spanish','es'],
    'FM': ['Micronesia','Micronesia','Oceania','Pacific/Pohnpei','USD',r'$','English','en'],
    'MD': ['Moldova','Moldova','Europe','Europe/Chisinau','MDL','L','Romanian','ro'],
    'MC': ['Monaco','Monaco','Europe','Europe/Monaco','EUR','€','French','fr'],
    'MN': ['Mongolia','Монгол','Asia','Asia/Ulaanbaatar','MNT','₮','Mongolian','mn'],
    'ME': ['Montenegro','Crna Gora','Europe','Europe/Podgorica','EUR','€','Montenegrin','cnr'],
    'MA': ['Morocco','المغرب','Africa','Africa/Casablanca','MAD','MAD','Arabic','ar'],
    'MZ': ['Mozambique','Moçambique','Africa','Africa/Maputo','MZN','MT','Portuguese','pt'],
    'MM': ['Myanmar','မြန်မာ','Asia','Asia/Rangoon','MMK','K','Burmese','my'],
    'NA': ['Namibia','Namibia','Africa','Africa/Windhoek','NAD',r'$','English','en'],
    'NR': ['Nauru','Nauru','Oceania','Pacific/Nauru','AUD',r'$','Nauruan','na'],
    'NP': ['Nepal','नेपाल','Asia','Asia/Kathmandu','NPR','₨','Nepali','ne'],
    'NL': ['Netherlands','Nederland','Europe','Europe/Amsterdam','EUR','€','Dutch','nl'],
    'NZ': ['New Zealand','New Zealand','Oceania','Pacific/Auckland','NZD',r'$','English','en'],
    'NI': ['Nicaragua','Nicaragua','Americas','America/Managua','NIO',r'C$','Spanish','es'],
    'NE': ['Niger','Niger','Africa','Africa/Niamey','XOF','Fr','French','fr'],
    'NG': ['Nigeria','Nigeria','Africa','Africa/Lagos','NGN','₦','English','en'],
    'MK': ['North Macedonia','Македонија','Europe','Europe/Skopje','MKD','ден','Macedonian','mk'],
    'NO': ['Norway','Norge','Europe','Europe/Oslo','NOK','kr','Norwegian','no'],
    'OM': ['Oman','عُمان','Asia','Asia/Muscat','OMR','﷼','Arabic','ar'],
    'PK': ['Pakistan','پاکستان','Asia','Asia/Karachi','PKR','₨','Urdu','ur'],
    'PW': ['Palau','Palau','Oceania','Pacific/Palau','USD',r'$','English','en'],
    'PA': ['Panama','Panamá','Americas','America/Panama','PAB','B/.','Spanish','es'],
    'PG': ['Papua New Guinea','Papua New Guinea','Oceania','Pacific/Port_Moresby','PGK','K','English','en'],
    'PY': ['Paraguay','Paraguay','Americas','America/Asuncion','PYG','Gs','Spanish','es'],
    'PE': ['Peru','Perú','Americas','America/Lima','PEN','S/.','Spanish','es'],
    'PH': ['Philippines','Pilipinas','Asia','Asia/Manila','PHP','₱','Filipino','tl'],
    'PL': ['Poland','Polska','Europe','Europe/Warsaw','PLN','zł','Polish','pl'],
    'PT': ['Portugal','Portugal','Europe','Europe/Lisbon','EUR','€','Portuguese','pt'],
    'QA': ['Qatar','قطر','Asia','Asia/Qatar','QAR','﷼','Arabic','ar'],
    'RO': ['Romania','România','Europe','Europe/Bucharest','RON','lei','Romanian','ro'],
    'RU': ['Russia','Россия','Europe','Europe/Moscow','RUB','₽','Russian','ru'],
    'RW': ['Rwanda','Rwanda','Africa','Africa/Kigali','RWF','Fr','Kinyarwanda','rw'],
    'KN': ['Saint Kitts and Nevis','Saint Kitts and Nevis','Americas','America/St_Kitts','XCD',r'$','English','en'],
    'LC': ['Saint Lucia','Saint Lucia','Americas','America/St_Lucia','XCD',r'$','English','en'],
    'VC': ['Saint Vincent and the Grenadines','Saint Vincent','Americas','America/St_Vincent','XCD',r'$','English','en'],
    'WS': ['Samoa','Samoa','Oceania','Pacific/Apia','WST','T','Samoan','sm'],
    'SM': ['San Marino','San Marino','Europe','Europe/San_Marino','EUR','€','Italian','it'],
    'ST': ['São Tomé and Príncipe','São Tomé e Príncipe','Africa','Africa/Sao_Tome','STN','Db','Portuguese','pt'],
    'SA': ['Saudi Arabia','المملكة العربية السعودية','Asia','Asia/Riyadh','SAR','﷼','Arabic','ar'],
    'SN': ['Senegal','Sénégal','Africa','Africa/Dakar','XOF','Fr','French','fr'],
    'RS': ['Serbia','Srbija','Europe','Europe/Belgrade','RSD','din','Serbian','sr'],
    'SC': ['Seychelles','Seychelles','Africa','Indian/Mahe','SCR','₨','English','en'],
    'SL': ['Sierra Leone','Sierra Leone','Africa','Africa/Freetown','SLL','Le','English','en'],
    'SG': ['Singapore','Singapore','Asia','Asia/Singapore','SGD',r'$','English','en'],
    'SK': ['Slovakia','Slovensko','Europe','Europe/Bratislava','EUR','€','Slovak','sk'],
    'SI': ['Slovenia','Slovenija','Europe','Europe/Ljubljana','EUR','€','Slovenian','sl'],
    'SB': ['Solomon Islands','Solomon Islands','Oceania','Pacific/Guadalcanal','SBD',r'$','English','en'],
    'SO': ['Somalia','Soomaaliya','Africa','Africa/Mogadishu','SOS','Sh','Somali','so'],
    'ZA': ['South Africa','South Africa','Africa','Africa/Johannesburg','ZAR','R','Zulu','zu'],
    'SS': ['South Sudan','South Sudan','Africa','Africa/Juba','SSP','£','English','en'],
    'ES': ['Spain','España','Europe','Europe/Madrid','EUR','€','Spanish','es'],
    'LK': ['Sri Lanka','ශ්‍රී ලංකාව','Asia','Asia/Colombo','LKR','₨','Sinhala','si'],
    'SD': ['Sudan','السودان','Africa','Africa/Khartoum','SDG','ج.س.','Arabic','ar'],
    'SR': ['Suriname','Suriname','Americas','America/Paramaribo','SRD',r'$','Dutch','nl'],
    'SE': ['Sweden','Sverige','Europe','Europe/Stockholm','SEK','kr','Swedish','sv'],
    'CH': ['Switzerland','Schweiz','Europe','Europe/Zurich','CHF','Fr','German','de'],
    'SY': ['Syria','سوريا','Asia','Asia/Damascus','SYP','£','Arabic','ar'],
    'TW': ['Taiwan','台灣','Asia','Asia/Taipei','TWD',r'NT$','Mandarin','zh'],
    'TJ': ['Tajikistan','Тоҷикистон','Asia','Asia/Dushanbe','TJS','SM','Tajik','tg'],
    'TZ': ['Tanzania','Tanzania','Africa','Africa/Dar_es_Salaam','TZS','Sh','Swahili','sw'],
    'TH': ['Thailand','ประเทศไทย','Asia','Asia/Bangkok','THB','฿','Thai','th'],
    'TL': ['Timor-Leste','Timor-Leste','Asia','Asia/Dili','USD',r'$','Tetum','tet'],
    'TG': ['Togo','Togo','Africa','Africa/Lome','XOF','Fr','French','fr'],
    'TO': ['Tonga','Tonga','Oceania','Pacific/Tongatapu','TOP',r'T$','Tongan','to'],
    'TT': ['Trinidad and Tobago','Trinidad and Tobago','Americas','America/Port_of_Spain','TTD',r'$','English','en'],
    'TN': ['Tunisia','تونس','Africa','Africa/Tunis','TND','DT','Arabic','ar'],
    'TR': ['Turkey','Türkiye','Asia','Europe/Istanbul','TRY','₺','Turkish','tr'],
    'TM': ['Turkmenistan','Türkmenistan','Asia','Asia/Ashgabat','TMT','T','Turkmen','tk'],
    'TV': ['Tuvalu','Tuvalu','Oceania','Pacific/Funafuti','AUD',r'$','Tuvaluan','tvl'],
    'UG': ['Uganda','Uganda','Africa','Africa/Kampala','UGX','Sh','English','en'],
    'UA': ['Ukraine','Україна','Europe','Europe/Kiev','UAH','₴','Ukrainian','uk'],
    'AE': ['United Arab Emirates','الإمارات','Asia','Asia/Dubai','AED','د.إ','Arabic','ar'],
    'GB': ['United Kingdom','United Kingdom','Europe','Europe/London','GBP','£','English','en'],
    'US': ['United States','United States','Americas','America/New_York','USD',r'$','English','en'],
    'UY': ['Uruguay','Uruguay','Americas','America/Montevideo','UYU',r'$U','Spanish','es'],
    'UZ': ['Uzbekistan','Oʻzbekiston','Asia','Asia/Tashkent','UZS','лв','Uzbek','uz'],
    'VU': ['Vanuatu','Vanuatu','Oceania','Pacific/Efate','VUV','Vt','Bislama','bi'],
    'VE': ['Venezuela','Venezuela','Americas','America/Caracas','VES','Bs.S','Spanish','es'],
    'VN': ['Vietnam','Việt Nam','Asia','Asia/Ho_Chi_Minh','VND','₫','Vietnamese','vi'],
    'YE': ['Yemen','اليمن','Asia','Asia/Aden','YER','﷼','Arabic','ar'],
    'ZM': ['Zambia','Zambia','Africa','Africa/Lusaka','ZMW','ZK','English','en'],
    'ZW': ['Zimbabwe','Zimbabwe','Africa','Africa/Harare','ZWL',r'$','English','en'],
  };

  // ── Public API ────────────────────────────────────────────────────────────

  /// Lookup by ISO-3166-1 alpha-2 code (e.g. "IN", "US").
  /// Returns null if not found.
  static NationData? fromCode(String? code) {
    if (code == null || code.isEmpty) return null;
    final key = code.trim().toUpperCase();
    final row = _db[key];
    if (row == null) return null;
    return NationData(
      countryCode: key,
      countryName: row[0],
      countryNameLocal: row[1],
      flag: flagFromCode(key),
      continent: row[2],
      timezone: row[3],
      currencyCode: row[4],
      currencySymbol: row[5],
      primaryLanguage: row[6],
      languageCode: row[7],
      detectedVia: 'DATABASE',
      confidence: 'HIGH',
      detectedAt: DateTime.now(),
    );
  }

  /// Parse device locale string like "en_IN", "pt_BR", "zh_CN"
  /// and return the NationData for the country part.
  static NationData? fromLocale(String locale) {
    // Handles: en_IN, en-IN, en_IN.UTF-8
    final parts = locale.replaceAll('-', '_').split('_');
    if (parts.length < 2) return null;
    // Country code is always the 2nd segment (uppercase)
    final countryCode = parts[1].toUpperCase();
    if (countryCode.length != 2) return null;
    return fromCode(countryCode);
  }

  /// Fuzzy search across country name and local name.
  /// Returns up to [limit] results sorted alphabetically.
  static List<NationData> search(String query, {int limit = 20}) {
    if (query.trim().isEmpty) return all();
    final q = query.trim().toLowerCase();
    final results = <NationData>[];
    for (final entry in _db.entries) {
      final row = entry.value;
      if (row[0].toLowerCase().contains(q) ||
          row[1].toLowerCase().contains(q) ||
          entry.key.toLowerCase().contains(q)) {
        results.add(fromCode(entry.key)!);
      }
      if (results.length >= limit) break;
    }
    results.sort((a, b) => a.countryName.compareTo(b.countryName));
    return results;
  }

  /// Returns all countries sorted alphabetically.
  static List<NationData> all() {
    final list = _db.keys.map((k) => fromCode(k)!).toList();
    list.sort((a, b) => a.countryName.compareTo(b.countryName));
    return list;
  }
}
