/// Pure mapping of authoritative native samples. No extrapolated Dart position.
class NativeEvidence {
  int? _lastPosition;
  bool observe(Map<String, dynamic> sample, {required bool intended}) {
    final position = sample['position'] as int;
    final running =
        intended &&
        sample['ready'] == true &&
        sample['state'] == 3 &&
        sample['nativePlaying'] == true &&
        (sample['suppression'] ?? 0) == 0 &&
        sample['playWhenReady'] == true;
    final previous = _lastPosition;
    _lastPosition = running ? position : null;
    return running &&
        previous != null &&
        position > previous &&
        position - previous < 1500;
  }

  void reset() => _lastPosition = null;
}
