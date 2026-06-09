import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LocaleFontService {
  static TextStyle getFontStyle(BuildContext context, {TextStyle? baseStyle}) {
    final languageCode = Localizations.localeOf(context).languageCode;

    final TextStyle style = baseStyle ?? const TextStyle();

    switch (languageCode) {
      case 'hi':
      case 'mr':
      case 'ne':
        return GoogleFonts.notoSansDevanagari(textStyle: style);
      case 'ar':
      case 'ur':
      case 'fa':
        return GoogleFonts.notoSansArabic(textStyle: style, height: 1.3);
      case 'bn':
        return GoogleFonts.notoSansBengali(textStyle: style);
      case 'zh':
        // Assuming simplified for generic zh
        return GoogleFonts.notoSansSc(textStyle: style);
      case 'ja':
        return GoogleFonts.notoSansJp(textStyle: style);
      case 'ko':
        return GoogleFonts.notoSansKr(textStyle: style);
      case 'th':
        return GoogleFonts.notoSansThai(textStyle: style);
      case 'ta':
        return GoogleFonts.notoSansTamil(textStyle: style);
      case 'te':
        return GoogleFonts.notoSansTelugu(textStyle: style);
      case 'kn':
        return GoogleFonts.notoSansKannada(textStyle: style);
      case 'ml':
        return GoogleFonts.notoSansMalayalam(textStyle: style);
      case 'pa':
        return GoogleFonts.notoSansGurmukhi(textStyle: style);
      case 'gu':
        return GoogleFonts.notoSansGujarati(textStyle: style);
      case 'si':
        return GoogleFonts.notoSansSinhala(textStyle: style);
      case 'he':
        return GoogleFonts.notoSansHebrew(textStyle: style);
      default:
        // Use default Material font (Roboto on Android, San Francisco on iOS)
        // or a default latin Google Font if you prefer:
        return style;
    }
  }
}

class LocaleAwareText extends StatelessWidget {
  const LocaleAwareText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  });
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: LocaleFontService.getFontStyle(context, baseStyle: style),
        textAlign: textAlign,
        overflow: overflow,
        maxLines: maxLines,
      );
}
