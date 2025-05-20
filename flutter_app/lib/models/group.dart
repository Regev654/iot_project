import 'package:firebase_database/firebase_database.dart';

class Group {
  final String groupId;
  final String groupName;
  final int amount;
  final List<String> participantIds;

  Group({
    required this.groupId,
    required this.groupName,
    required this.amount,
    this.participantIds = const [],
  });

  factory Group.fromSnapshot(DataSnapshot snapshot) {
    final data = snapshot.value as Map<dynamic, dynamic>;
    return Group(
      groupId: snapshot.key!,
      groupName: data['groupName'] ?? '',
      amount: data['amount'] ?? 0,
      participantIds: List<String>.from(data['ParticipantIDs'] ?? []),
    );
  }

  factory Group.fromJson(Map<dynamic, dynamic> json) {
    return Group(
      groupId: json['groupId'] ?? '',
      groupName: json['groupName'] ?? '',
      amount: json['amount'] ?? 0,
      participantIds: json['participantIds'] != null
          ? List<String>.from(json['participantIds'])
          : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'groupName': groupName,
      'amount': amount,
      'participantIds': participantIds,
    };
  }
} 