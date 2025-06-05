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
  late TextEditingController _searchController;
  bool _isEditing = false;
  bool _isLiveEvent = false;

  @override
  void initState() {
    super.initState();
    _eventRef = FirebaseDatabase.instance.ref().child('EventsV1/${widget.event.eventId}');
    _textToPrintController = TextEditingController(text: widget.event.textToPrint);
    _searchController = TextEditingController();
    _setupParticipantsListener();
    _checkLiveStatus();
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

  Future<void> _updateParticipantTokens(Participant participant, int newUsedTokens) async {
    if (newUsedTokens < 0 || newUsedTokens > participant.maxTokens) return;

    try {
      await _eventRef.child('Participants/${participant.id}').update({
        'usedTokens': newUsedTokens,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating tokens: $e')),
        );
      }
    }
  }

  Future<void> _handleTokenAdjustment(Participant participant, bool increment) async {
    final newValue = increment 
        ? participant.usedTokens + 1 
        : participant.usedTokens - 1;
    await _updateParticipantTokens(participant, newValue);
  }

  Future<void> _handleTokenHold(Participant participant, bool increment) async {
    final newValue = increment ? participant.maxTokens : 0;
    await _updateParticipantTokens(participant, newValue);
  }

  Future<void> _makeLiveEvent() async {
    try {
      if (_isLiveEvent) {
        // Stop live event
        await FirebaseDatabase.instance.ref().child('LiveEventV1').remove();
        setState(() => _isLiveEvent = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event is no longer live')),
          );
        }
      } else {
        // Start live event
        await FirebaseDatabase.instance.ref().child('LiveEventV1').set(widget.event.eventId);
        setState(() => _isLiveEvent = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event is now live')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error setting live event: $e')),
        );
      }
    }
  }

  Future<void> _checkLiveStatus() async {
    try {
      final liveEventSnapshot = await FirebaseDatabase.instance.ref().child('LiveEventV1').get();
      if (liveEventSnapshot.exists) {
        final liveEventId = liveEventSnapshot.value.toString();
        setState(() => _isLiveEvent = liveEventId == widget.event.eventId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking live status: $e')),
        );
      }
    }
  }

  Future<void> _deleteEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text(
          'Are you sure you want to delete "${widget.event.eventTitle}"? This action cannot be undone and will remove all associated groups and participants.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _eventRef.remove();
      if (mounted) {
        Navigator.pop(context); // Return to event list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting event: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _participantsSubscription.cancel();
    _textToPrintController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.eventTitle),
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            color: theme.colorScheme.error,
            onPressed: _deleteEvent,
          ),
        ],
      ),
      body: Container(
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWideScreen = constraints.maxWidth > 600;
                          final buttonWidth = isWideScreen ? 250.0 : constraints.maxWidth * 0.85;
                          final buttonHeight = isWideScreen ? 65.0 : 60.0;
                          
                          return Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: isWideScreen ? 900.0 : constraints.maxWidth,
                              ),
                              child: Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                alignment: WrapAlignment.center,
                                children: [
                                  SizedBox(
                                    width: buttonWidth,
                                    height: buttonHeight,
                                    child: FilledButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => GroupsScreen(event: widget.event),
                                          ),
                                        );
                                      },
                                      icon: Icon(
                                        Icons.group,
                                        size: isWideScreen ? 32 : 28,
                                      ),
                                      label: Text(
                                        'Manage Groups',
                                        style: TextStyle(
                                          fontSize: isWideScreen ? 18 : 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: theme.colorScheme.primary,
                                        foregroundColor: theme.colorScheme.onPrimary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: buttonWidth,
                                    height: buttonHeight,
                                    child: FilledButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => EventStatsScreen(event: widget.event),
                                          ),
                                        );
                                      },
                                      icon: Icon(
                                        Icons.analytics,
                                        size: isWideScreen ? 32 : 28,
                                      ),
                                      label: Text(
                                        'View Stats',
                                        style: TextStyle(
                                          fontSize: isWideScreen ? 18 : 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: theme.colorScheme.secondary,
                                        foregroundColor: theme.colorScheme.onSecondary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: buttonWidth,
                                    height: buttonHeight,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: _isLiveEvent 
                                            ? [Colors.red.shade700, Colors.red.shade900]
                                            : [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (_isLiveEvent ? Colors.red : theme.colorScheme.primary).withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: FilledButton.icon(
                                        onPressed: _makeLiveEvent,
                                        icon: Icon(
                                          _isLiveEvent ? Icons.live_tv : Icons.live_tv,
                                          size: isWideScreen ? 32 : 28,
                                        ),
                                        label: Text(
                                          _isLiveEvent ? 'Stop Live Event' : 'Make Live Event',
                                          style: TextStyle(
                                            fontSize: isWideScreen ? 18 : 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          padding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 2,
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
                          Text(
                            'Text to Print',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
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
                            contentPadding: const EdgeInsets.all(12),
                          ),
                          maxLines: 2,
                          style: theme.textTheme.bodyLarge,
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            widget.event.textToPrint,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 2,
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
                          Text(
                            'Participants',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${_participants.length} Total',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (_participants.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '${_participants.values.where((p) => p.usedTokens > 0).length} Active (${((_participants.values.where((p) => p.usedTokens > 0).length / _participants.length) * 100).toStringAsFixed(1)}%)',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.secondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search participants...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 16),
                      ..._participants.values
                          .where((p) {
                            final searchText = _searchController.text.toLowerCase();
                            return searchText.isEmpty || p.id.toLowerCase().contains(searchText);
                          })
                          .take(10)
                          .map((participant) {
                            final usagePercentage = participant.maxTokens > 0
                                ? (participant.usedTokens / participant.maxTokens) * 100
                                : 0.0;
                            
                            return Card(
                              elevation: 1,
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
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
                                        Row(
                                          children: [
                                            GestureDetector(
                                              onTapDown: (_) => _handleTokenAdjustment(participant, false),
                                              onLongPress: () => _handleTokenHold(participant, false),
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme.error.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  Icons.remove,
                                                  color: theme.colorScheme.error,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${participant.usedTokens}/${participant.maxTokens}',
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                color: theme.colorScheme.primary,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            GestureDetector(
                                              onTapDown: (_) => _handleTokenAdjustment(participant, true),
                                              onLongPress: () => _handleTokenHold(participant, true),
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme.primary.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  Icons.add,
                                                  color: theme.colorScheme.primary,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                          ],
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
                          }).toList(),
                      if (_participants.length > 10)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Use search to find more participants',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
