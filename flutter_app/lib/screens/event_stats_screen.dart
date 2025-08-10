import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import '../models/event.dart';
import '../models/participant.dart';

class EventStatsScreen extends StatefulWidget {
  final Event event;

  EventStatsScreen({required this.event});

  @override
  _EventStatsScreenState createState() => _EventStatsScreenState();
}

class _EventStatsScreenState extends State<EventStatsScreen> {
  late List<Participant> participants;
  Map<String, List<String>> groups = {}; // groupId -> list of participant IDs
  Map<String, String> groupNames = {}; // groupId -> groupName
  StreamSubscription? _participantsSubscription;
  StreamSubscription? _groupsSubscription;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // Consistent rounding function for all percentages
  double _roundPercentage(double percentage) {
    return (percentage * 10).round() / 10; // Round to 1 decimal place
  }

  @override
  void initState() {
    super.initState();
    participants = widget.event.participants.values.toList();
    // Delay the listeners to prevent screen from getting stuck
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupParticipantsListener();
      _setupGroupsListener();
    });
  }

  void _setupParticipantsListener() {
    final participantsRef = _dbRef
        .child('EventsV3')
        .child(widget.event.eventId)
        .child('Participants');

    _participantsSubscription = participantsRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          participants = data.entries.map((entry) {
            final participantData = entry.value as Map<dynamic, dynamic>;
            return Participant.fromJson({
              'ID': entry.key.toString(),
              'items': participantData['items'] ?? [],
            });
          }).toList();
        });
      }
    });
  }

  void _setupGroupsListener() {
    final groupsRef = _dbRef
        .child('EventsV3')
        .child(widget.event.eventId)
        .child('groups');

    _groupsSubscription = groupsRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          groups = data.map((key, value) {
            final groupData = value as Map<dynamic, dynamic>;
            // Use participantIds instead of participants
            final participantsList = groupData['participantIds'] as List<dynamic>? ?? [];
            // Store group name
            groupNames[key.toString()] = groupData['groupName']?.toString() ?? key.toString();
            return MapEntry(
              key.toString(),
              participantsList.map((p) => p.toString()).toList(),
            );
          });
        });
      } else {
        setState(() {
          groups = {};
          groupNames = {};
        });
      }
    });
  }

  @override
  void dispose() {
    _participantsSubscription?.cancel();
    _groupsSubscription?.cancel();
    super.dispose();
  }

  // Helper method to calculate user stats for a list of participants
  Map<String, dynamic> _calculateUserStats(List<Participant> participantList) {
    final totalUsers = participantList.length;
    final activeUsers = participantList.where((p) => 
      p.items.values.any((item) => (item['usedTokens'] ?? 0) > 0)
    ).length;
    final rawActivePercentage = totalUsers > 0 ? (activeUsers / totalUsers * 100) : 0.0;
    final activePct = _roundPercentage(rawActivePercentage);
    
    // Calculate token statistics for the group
    int totalTokens = 0;
    int usedTokens = 0;
    for (final participant in participantList) {
      for (final item in participant.items.values) {
        totalTokens += (item['maxTokens'] ?? 0);
        usedTokens += (item['usedTokens'] ?? 0);
      }
    }
    final remainingTokens = totalTokens - usedTokens;
    final rawTokenUsagePct = totalTokens > 0 ? (usedTokens / totalTokens * 100) : 0.0;
    final tokenUsagePct = _roundPercentage(rawTokenUsagePct);
    
    return {
      'totalUsers': totalUsers,
      'activeUsers': activeUsers,
      'activePct': activePct,
      'totalTokens': totalTokens,
      'usedTokens': usedTokens,
      'remainingTokens': remainingTokens,
      'tokenUsagePct': tokenUsagePct,
    };
  }

  // Helper method to get participants by group
  List<Participant> _getParticipantsByGroup(String groupName) {
    final participantIds = groups[groupName] ?? [];
    return participants.where((p) => participantIds.contains(p.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Calculate overall user stats
    final overallUserStats = _calculateUserStats(participants);
    
    // Calculate group user stats
    final Map<String, Map<String, dynamic>> groupUserStats = {};
    for (final groupName in groups.keys) {
      final groupParticipants = _getParticipantsByGroup(groupName);
      groupUserStats[groupName] = _calculateUserStats(groupParticipants);
    }
    
    // Gather all item names across all participants
    final Set<String> allItemNames = {};
    for (final p in participants) {
      allItemNames.addAll(p.items.keys);
    }
    // Per-item statistics
    final Map<String, Map<String, dynamic>> itemStats = {};
    for (final itemName in allItemNames) {
      int total = 0;
      int used = 0;
      for (final p in participants) {
        final maxT = p.items[itemName]?['maxTokens'] ?? 0;
        final usedT = p.items[itemName]?['usedTokens'] ?? 0;
        total += maxT;
        used += usedT;
      }
      final rawPercentage = total > 0 ? (used / total) * 100 : 0.0;
      itemStats[itemName] = {
        'total': total,
        'used': used,
        'remaining': total - used,
        'usagePct': _roundPercentage(rawPercentage),
      };
    }
    // Combined totals
    int combinedTotal = 0;
    int combinedUsed = 0;
    for (final stats in itemStats.values) {
      combinedTotal += (stats['total'] ?? 0) as int;
      combinedUsed += (stats['used'] ?? 0) as int;
    }
    final combinedRemaining = combinedTotal - combinedUsed;
    final rawCombinedPercentage = combinedTotal > 0 ? (combinedUsed / combinedTotal * 100) : 0.0;
    final combinedUsagePct = _roundPercentage(rawCombinedPercentage);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Event Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  child: Column(
                    children: [
                      // Overall statistics row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _userStatTile(
                            icon: Icons.people,
                            label: 'Total Users',
                            value: overallUserStats['totalUsers'] as int,
                            color: theme.colorScheme.primary,
                          ),
                          _userStatTile(
                            icon: Icons.person,
                            label: 'Active Users',
                            value: overallUserStats['activeUsers'] as int,
                            color: theme.colorScheme.secondary,
                          ),
                          _userStatTile(
                            icon: Icons.percent,
                            label: 'Active %',
                            value: overallUserStats['activePct'] as double,
                            color: theme.colorScheme.tertiary,
                            isPercent: true,
                          ),
                        ],
                      ),
                      // Group statistics
                      if (groups.isNotEmpty) ...[
                        Divider(height: 24, thickness: 1),
                        ...groupUserStats.entries.map((entry) {
                          final groupId = entry.key;
                          final groupName = groupNames[groupId] ?? groupId;
                          final stats = entry.value;
                          return Container(
                            margin: EdgeInsets.only(bottom: 4),
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.grey[200]!,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    groupName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      _inlineStatTile(
                                        icon: Icons.people,
                                        label: 'Total',
                                        value: stats['totalUsers'] as int,
                                        color: theme.colorScheme.primary,
                                      ),
                                      SizedBox(width: 16),
                                      _inlineStatTile(
                                        icon: Icons.person,
                                        label: 'Active',
                                        value: stats['activeUsers'] as int,
                                        color: theme.colorScheme.secondary,
                                      ),
                                      SizedBox(width: 16),
                                      _inlineStatTile(
                                        icon: Icons.percent,
                                        label: 'Active %',
                                        value: stats['activePct'] as double,
                                        color: theme.colorScheme.tertiary,
                                        isPercent: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              // Combined summary
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All Items Combined',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _statTile('Total Tokens', combinedTotal, theme)),
                          Expanded(child: _statTile('Used Tokens', combinedUsed, theme)),
                          Expanded(child: _statTile('Remaining', combinedRemaining, theme)),
                        ],
                      ),
                      SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: combinedUsagePct / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          combinedUsagePct > 80 ? Colors.red : Colors.green,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${combinedUsagePct.toStringAsFixed(1)}% Tokens Used',
                        style: TextStyle(
                          color: combinedUsagePct > 80 ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
               
              // Per-item stats
              ...itemStats.entries.map((entry) {
                final name = entry.key;
                final stats = entry.value;
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        SizedBox(height: 8),
                                                 Row(
                           children: [
                             Expanded(child: _statTile('Total', (stats['total'] ?? 0) as int, theme)),
                             Expanded(child: _statTile('Used', (stats['used'] ?? 0) as int, theme)),
                             Expanded(child: _statTile('Remaining', (stats['remaining'] ?? 0) as int, theme)),
                           ],
                         ),
                        SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: ((stats['usagePct'] ?? 0.0) as double) / 100,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            ((stats['usagePct'] ?? 0.0) as double) > 80 ? Colors.red : Colors.green,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${((stats['usagePct'] ?? 0.0) as double).toStringAsFixed(1)}% Used',
                          style: TextStyle(
                            color: ((stats['usagePct'] ?? 0.0) as double) > 80 ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    ),
  ),
    );
  }

  Widget _statTile(String label, int value, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _userStatTile({required IconData icon, required String label, required num value, required Color color, bool isPercent = false}) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        SizedBox(height: 8),
        Text(
          isPercent ? '${value.toStringAsFixed(1)}%' : value.toString(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _compactUserStatTile({required IconData icon, required String label, required num value, required Color color, bool isPercent = false}) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 4),
        Text(
          isPercent ? '${value.toStringAsFixed(1)}%' : value.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _inlineStatTile({required IconData icon, required String label, required num value, required Color color, bool isPercent = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        SizedBox(width: 4),
        Text(
          isPercent ? '${value.toStringAsFixed(1)}%' : value.toString(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
} 