import 'package:firebase_database/firebase_database.dart';

class Group {
  final String groupId;
  final String groupName;
  final List<String> participantIds;
  final Map<String, Map<String, int>> items;

  Group({
    required this.groupId,
    required this.groupName,
    this.participantIds = const [],
    this.items = const {},
  });

  factory Group.fromSnapshot(DataSnapshot snapshot) {
    final data = snapshot.value as Map<dynamic, dynamic>;
    return Group(
      groupId: snapshot.key!,
      groupName: data['groupName'] ?? '',
      participantIds: List<String>.from(data['participantIds'] ?? []),
      items: data['items'] != null
        ? (data['items'] as Map).map((k, v) => MapEntry(k.toString(), Map<String, int>.from(v as Map)))
        : {},
    );
  }

  factory Group.fromJson(Map<dynamic, dynamic> json) {
    return Group(
      groupId: json['groupId'] ?? '',
      groupName: json['groupName'] ?? '',
      participantIds: json['participantIds'] != null
          ? List<String>.from(json['participantIds'])
          : [],
      items: json['items'] != null
        ? (json['items'] as Map).map((k, v) => MapEntry(k.toString(), Map<String, int>.from(v as Map)))
        : {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'groupName': groupName,
      'participantIds': participantIds,
      'items': items,
    };
  }
} 