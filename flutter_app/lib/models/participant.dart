class Participant {
  final String id;
  int usedTokens;
  int maxTokens;
  String textToPrint;

  Participant({
    required this.id,
    this.usedTokens = 0,
    this.maxTokens = 0,
    this.textToPrint = '',
  });

  Map<String, dynamic> toJson() => {
    'ID': id,
    'usedTokens': usedTokens,
    'maxTokens': maxTokens,
    'textToPrint': textToPrint,
  };

  factory Participant.fromJson(Map<String, dynamic> json) => Participant(
    id: json['ID'] as String,
    usedTokens: json['usedTokens'] as int? ?? 0,
    maxTokens: json['maxTokens'] as int? ?? 0,
    textToPrint: json['textToPrint'] as String? ?? '',
  );
} 