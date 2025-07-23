class Participant {
  final String id;
  Map<String, Map<String, int>> items;

  Participant({
    required this.id,
    required this.items,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    final itemsMap = <String, Map<String, int>>{};
    if (json['items'] != null) {
      (json['items'] as Map).forEach((key, value) {
        itemsMap[key.toString()] = Map<String, int>.from(value as Map);
      });
    }
    return Participant(
      id: json['ID'].toString(),
      items: itemsMap,
    );
  }

  Map<String, dynamic> toJson() => {
    'ID': id,
    'items': items,
  };

  // Helper to get all item names
  List<String> get itemNames => items.keys.toList();

  // Helper to get maxTokens for an item
  int getMaxTokens(String itemName) => items[itemName]?['maxTokens'] ?? 0;

  // Helper to get usedTokens for an item
  int getUsedTokens(String itemName) => items[itemName]?['usedTokens'] ?? 0;

  // Helper to update tokens for an item
  void setTokens(String itemName, int maxTokens, int usedTokens) {
    items[itemName] = {'maxTokens': maxTokens, 'usedTokens': usedTokens};
  }
} 