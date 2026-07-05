class SCharacterAmount {
  const SCharacterAmount({
    required this.count,
    required this.maxSlots,
  });

  final int count;
  final int maxSlots;

  factory SCharacterAmount.fromData(Map<String, dynamic> data) {
    return SCharacterAmount(
      count: data['count'] as int? ?? 0,
      maxSlots: data['maxSlots'] as int? ?? 2,
    );
  }
}
