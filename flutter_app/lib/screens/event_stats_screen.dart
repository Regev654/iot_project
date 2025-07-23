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
  StreamSubscription? _participantsSubscription;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    participants = widget.event.participants.values.toList();
    _setupParticipantsListener();
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

  @override
  void dispose() {
    _participantsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Gather all item names across all participants
    final Set<String> allItemNames = {};
    for (final p in participants) {
      allItemNames.addAll(p.items.keys);
    }
    // Per-item statistics
    final Map<String, Map<String, int>> itemStats = {};
    for (final itemName in allItemNames) {
      int total = 0;
      int used = 0;
      for (final p in participants) {
        final maxT = p.items[itemName]?['maxTokens'] ?? 0;
        final usedT = p.items[itemName]?['usedTokens'] ?? 0;
        total += maxT;
        used += usedT;
      }
      itemStats[itemName] = {
        'total': total,
        'used': used,
        'remaining': total - used,
        'usagePct': total > 0 ? ((used / total) * 100).round() : 0,
      };
    }
    // Combined totals
    int combinedTotal = 0;
    int combinedUsed = 0;
    for (final stats in itemStats.values) {
      combinedTotal += stats['total'] ?? 0;
      combinedUsed += stats['used'] ?? 0;
    }
    final combinedRemaining = combinedTotal - combinedUsed;
    final combinedUsagePct = combinedTotal > 0 ? (combinedUsed / combinedTotal * 100) : 0;
    return Scaffold(
      appBar: AppBar(
        title: Text('Event Dashboard'),
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
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
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              SizedBox(height: 16),
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
                            Expanded(child: _statTile('Total', stats['total'] ?? 0, theme)),
                            Expanded(child: _statTile('Used', stats['used'] ?? 0, theme)),
                            Expanded(child: _statTile('Remaining', stats['remaining'] ?? 0, theme)),
                          ],
                        ),
                        SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: (stats['usagePct'] ?? 0) / 100,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            (stats['usagePct'] ?? 0) > 80 ? Colors.red : Colors.green,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${stats['usagePct'] ?? 0}% Used',
                          style: TextStyle(
                            color: (stats['usagePct'] ?? 0) > 80 ? Colors.red : Colors.green,
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
} 