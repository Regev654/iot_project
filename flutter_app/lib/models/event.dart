class Event {
  String title;
  List<String> participants;

  Event({required this.title, List<String>? participants})
      : participants = participants ?? [];
}
