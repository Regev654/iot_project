class Event {
  String eventId;
  String title;
  List<String> participants;

  Event({required this.eventId, required this.title, List<String>? participants})
      : participants = participants ?? [];
}
