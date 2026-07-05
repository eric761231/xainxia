class SCharacterList {
  const SCharacterList({required this.characters});

  final List<Map<String, dynamic>> characters;

  factory SCharacterList.fromData(Map<String, dynamic> data) {
    final raw = data['characters'] as List<dynamic>? ?? [];
    return SCharacterList(
      characters: raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
    );
  }
}
