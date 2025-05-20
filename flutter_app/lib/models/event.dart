import 'participant.dart';

class Event {
  String eventId;
  String eventTitle;
  String textToPrint;
  int amount;
  List<Participant> participants;

  Event({
    required this.eventId, 
    required this.eventTitle, 
    this.textToPrint = '', 
    this.amount = 0,
    List<Participant>? participants,
  }) : participants = participants ?? [];

  Map<String, dynamic> toJson() => {
    'ID': eventId,
    'amount': amount,
    'textToPrint': textToPrint,
    'eventTitle': eventTitle,
    'Participants': participants.fold<Map<String, dynamic>>({}, (map, participant) {
      map[participant.id] = participant.toJson();
      return map;
    }),
  };

  factory Event.fromJson(Map<String, dynamic> json) {
    print('Parsing event JSON: $json'); // Debug print
    final participants = json['Participants'] as Map<String, dynamic>?;
    final event = Event(
      eventId: json['ID'] as String,
      eventTitle: json['eventTitle'] as String,
      textToPrint: json['textToPrint'] as String? ?? '',
      amount: json['amount'] as int? ?? 0,
      participants: participants?.entries.map((e) => 
        Participant.fromJson(Map<String, dynamic>.from(e.value as Map))
      ).toList() ?? [],
    );
    print('Created event: ${event.eventTitle} with ${event.participants.length} participants'); // Debug print
    return event;
  }
}
