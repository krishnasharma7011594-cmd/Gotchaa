import 'dart:math';

class InviteCodeService {
  static const String _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  static final Random _rnd = Random();

  /// Generates a unique-looking invite code (e.g., GOTCHAA-XXXX)
  static String generateCode() {
    final suffix = String.fromCharCodes(Iterable.generate(
        6, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
    return 'GOTCHAA-$suffix';
  }
}
