class Participant {
  final String id;
  bool hasReceivedGift;

  Participant({
    required this.id,
    this.hasReceivedGift = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'hasReceivedGift': hasReceivedGift,
  };

  factory Participant.fromJson(Map<String, dynamic> json) => Participant(
    id: json['id'] as String,
    hasReceivedGift: json['hasReceivedGift'] as bool? ?? false,
  );
} 