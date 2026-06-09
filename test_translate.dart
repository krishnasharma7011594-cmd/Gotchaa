import 'package:google_mlkit_translation/google_mlkit_translation.dart';
void main() {
  for (final x in TranslateLanguage.values) {
    print('Name is ${x.name} AND bcp is ${x.bcpCode}');
  }
}
