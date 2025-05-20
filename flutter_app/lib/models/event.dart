import 'package:firebase_database/firebase_database.dart';
import 'group.dart';
import 'participant.dart';

class Event {
  final String eventId;
  final String eventTitle;
  final String textToPrint;
  final Map<String, Group> groups;
  final Map<String, Participant> participants;

  Event({
    required this.eventId,
    required this.eventTitle,
    required this.textToPrint,
    Map<String, Group>? groups,
    Map<String, Participant>? participants,
  }) : groups = groups ?? {},
       participants = participants ?? {};

  factory Event.fromJson(Map<String, dynamic> json) {
    final participants = json['Participants'] as Map<String, dynamic>?;
    final participantsMap = <String, Participant>{};
    
    if (participants != null) {
      participants.forEach((key, value) {
        final participantData = value as Map<String, dynamic>;
        participantsMap[key] = Participant(
          id: key,
          maxTokens: participantData['maxTokens'] ?? 0,
          usedTokens: participantData['usedTokens'] ?? 0,
          textToPrint: participantData['textToPrint'] ?? '',
        );
      });
    }

    final groups = json['Groups'] as Map<String, dynamic>?;
    final groupsMap = <String, Group>{};
    
    if (groups != null) {
      groups.forEach((key, value) {
        final groupData = value as Map<String, dynamic>;
        groupsMap[key] = Group(
          groupId: key,
          groupName: groupData['groupName'] ?? '',
          amount: groupData['amount'] ?? 0,
          participantIds: List<String>.from(groupData['ParticipantIDs'] ?? []),
        );
      });
    }

    return Event(
      eventId: json['ID'] as String,
      eventTitle: json['eventTitle'] as String,
      textToPrint: json['textToPrint'] as String? ?? '',
      groups: groupsMap,
      participants: participantsMap,
    );
  }

  factory Event.fromSnapshot(DataSnapshot snapshot) {
    final data = snapshot.value as Map<dynamic, dynamic>;
    final groups = <String, Group>{};
    
    if (data['Groups'] != null) {
      final groupsData = data['Groups'] as Map<dynamic, dynamic>;
      groupsData.forEach((key, value) {
        final groupData = value as Map<dynamic, dynamic>;
        groups[key.toString()] = Group(
          groupId: key.toString(),
          groupName: groupData['groupName'] ?? '',
          amount: groupData['amount'] ?? 0,
          participantIds: List<String>.from(groupData['ParticipantIDs'] ?? []),
        );
      });
    }

    return Event(
      eventId: snapshot.key!,
      eventTitle: data['eventTitle'] ?? '',
      textToPrint: data['textToPrint'] ?? '',
      groups: groups,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventTitle': eventTitle,
      'textToPrint': textToPrint,
      'Groups': Map.fromEntries(
        groups.entries.map((e) => MapEntry(e.key, e.value.toMap())),
      ),
      'Participants': Map.fromEntries(
        participants.entries.map(
          (e) => MapEntry(e.key, {
            'maxTokens': e.value.maxTokens,
            'usedTokens': e.value.usedTokens,
            'textToPrint': e.value.textToPrint,
          }),
        ),
      ),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': eventId,
      'eventTitle': eventTitle,
      'textToPrint': textToPrint,
      'Groups': Map.fromEntries(
        groups.entries.map((e) => MapEntry(e.key, e.value.toMap())),
      ),
      'Participants': Map.fromEntries(
        participants.entries.map(
          (e) => MapEntry(e.key, {
            'ID': e.key,
            'maxTokens': e.value.maxTokens,
            'usedTokens': e.value.usedTokens,
            'textToPrint': e.value.textToPrint,
          }),
        ),
      ),
    };
  }
}
