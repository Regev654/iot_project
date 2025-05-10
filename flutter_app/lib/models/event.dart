import 'participant.dart';

class Event {
  String eventId;
  String title;
  String textToPrint;
  List<Participant> participants;
  bool isLive;

  Event({
    required this.eventId, 
    required this.title, 
    this.textToPrint = '', 
    List<Participant>? participants,
    this.isLive = false,
  }) : participants = participants ?? [];

  Map<String, dynamic> toJson() => {
    'eventId': eventId,
    'title': title,
    'textToPrint': textToPrint,
    'isLive': isLive,
  };

  factory Event.fromJson(Map<String, dynamic> json) {
    final participants = json['participants'] as List<dynamic>?;
    return Event(
      eventId: json['eventId'] as String,
      title: json['title'] as String,
      textToPrint: json['textToPrint'] as String? ?? '',
      participants: participants?.map((p) => Participant.fromJson(p as Map<String, dynamic>)).toList() ?? [],
      isLive: json['isLive'] as bool? ?? false,
    );
  }
}
