import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import '../models/event.dart';
import '../models/participant.dart';
import '../utils/csv_parser.dart';
import 'event_stats_screen.dart';
import 'groups_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late DatabaseReference _eventRef;
  late StreamSubscription _participantsSubscription;
  Map<String, Participant> _participants = {};
  bool _isLoading = true;
  String _error = '';
  late TextEditingController _textToPrintController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _eventRef = FirebaseDatabase.instance.ref().child('Events/${widget.event.eventId}');
    _textToPrintController = TextEditingController(text: widget.event.textToPrint);
    _setupParticipantsListener();
  }

  void _setupParticipantsListener() {
    _participantsSubscription = _eventRef.child('Participants').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final participants = <String, Participant>{};
        
        data.forEach((key, value) {
          final participantData = value as Map<dynamic, dynamic>;
          participants[key.toString()] = Participant(
            id: key.toString(),
            maxTokens: participantData['maxTokens'] ?? 0,
            usedTokens: participantData['usedTokens'] ?? 0,
            textToPrint: participantData['textToPrint'] ?? '',
          );
        });

        setState(() {
          _participants = participants;
          _isLoading = false;
        });
      } else {
        setState(() {
          _participants = {};
          _isLoading = false;
        });
      }
    }, onError: (error) {
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    });
  }

  Future<void> _updateTextToPrint() async {
    if (_textToPrintController.text.isEmpty) return;

    try {
      // Update event's textToPrint
      await _eventRef.update({'textToPrint': _textToPrintController.text});

      // Update all participants' textToPrint
      final batch = <String, Map<String, dynamic>>{};
      for (final participant in _participants.values) {
        batch[participant.id] = {
          'textToPrint': _textToPrintController.text,
          'maxTokens': participant.maxTokens,
          'usedTokens': participant.usedTokens,
        };
      }
      await _eventRef.child('Participants').update(batch);

      setState(() => _isEditing = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating text: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _participantsSubscription.cancel();
    _textToPrintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.eventTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventStatsScreen(event: widget.event),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text('Error: $_error'))
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.colorScheme.primary.withOpacity(0.1),
                        theme.colorScheme.surface,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Text to Print:',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: Icon(
                                    _isEditing ? Icons.save : Icons.edit,
                                    color: theme.colorScheme.primary,
                                  ),
                                  onPressed: () {
                                    if (_isEditing) {
                                      _updateTextToPrint();
                                    } else {
                                      setState(() => _isEditing = true);
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_isEditing)
                              TextField(
                                controller: _textToPrintController,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: theme.colorScheme.surface,
                                ),
                                maxLines: 2,
                              )
                            else
                              Text(
                                widget.event.textToPrint,
                                style: theme.textTheme.bodyLarge,
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _participants.length,
                          itemBuilder: (context, index) {
                            final participant = _participants.values.elementAt(index);
                            final usagePercentage = participant.maxTokens > 0
                                ? (participant.usedTokens / participant.maxTokens) * 100
                                : 0.0;
                            
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            participant.id,
                                            style: TextStyle(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${participant.usedTokens}/${participant.maxTokens}',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: usagePercentage / 100,
                                        backgroundColor: Colors.grey[200],
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          usagePercentage > 80
                                              ? Colors.red
                                              : usagePercentage > 50
                                                  ? Colors.orange
                                                  : Colors.green,
                                        ),
                                        minHeight: 8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupsScreen(event: widget.event),
            ),
          );
        },
        icon: const Icon(Icons.group),
        label: const Text('Manage Groups'),
      ),
    );
  }
}
