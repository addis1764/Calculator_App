import 'pin_service.dart';

class SecretCodeDetector {
  final PinService pinService;

  SecretCodeDetector({required this.pinService});

  /// Inspects candidate string (for example when '=' is pressed)
  /// Returns true if the candidate matches the stored PIN
  Future<bool> checkCandidate(String candidate) async {
    // Clean string from whitespace or trailing '='
    final cleaned = candidate.trim().replaceAll('=', '');
    if (cleaned.isEmpty) return false;

    // Check if cleaned string matches PIN
    final isMatch = await pinService.verifyPin(cleaned);
    return isMatch;
  }
}
