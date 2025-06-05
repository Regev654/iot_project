import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import '../models/event.dart';
import '../models/participant.dart';
import '../utils/csv_parser.dart';
import 'event_stats_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;
  final bool isLive;

  EventDetailScreen({
    required this.event,
    this.isLive = false,
  });

  @override
  _EventDetailScreenState createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late List<Participant> participants;
  late TextEditingController textToPrintController;
  late TextEditingController amountController;
  late TextEditingController searchController;
  String search = '';
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  StreamSubscription? _participantsSubscription;

  @override
  void initState() {
    super.initState();
    try {
      participants = widget.event.participants.map((p) => Participant(
        id: p.id,
        maxTokens: p.maxTokens,
        usedTokens: p.usedTokens,
        textToPrint: p.textToPrint,
      )).toList();
      textToPrintController = TextEditingController(text: widget.event.textToPrint);
      amountController = TextEditingController(text: widget.event.amount.toString());
      searchController = TextEditingController();
      _setupParticipantsListener();
    } catch (e) {
      print('Error in initState: $e');
      participants = [];
      textToPrintController = TextEditingController();
      amountController = TextEditingController();
      searchController = TextEditingController();
    }
  }

  void _setupParticipantsListener() {
    final participantsRef = _dbRef
        .child('Events')
        .child(widget.event.eventId)
        .child('Participants');

    _participantsSubscription = participantsRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        try {
          final Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
          setState(() {
            participants = data.entries.map((entry) {
              if (entry.value == null) {
                print('Warning: Null value for participant ${entry.key}');
                return Participant(
                  id: entry.key.toString(),
                  maxTokens: widget.event.amount,
                  usedTokens: 0,
                  textToPrint: widget.event.textToPrint,
                );
              }
              
              final participantData = entry.value as Map<dynamic, dynamic>;
              return Participant(
                id: entry.key.toString(),
                maxTokens: participantData['maxTokens'] ?? widget.event.amount,
                usedTokens: participantData['usedTokens'] ?? 0,
                textToPrint: participantData['textToPrint'] ?? widget.event.textToPrint,
              );
            }).toList();
          });
        } catch (e) {
          print('Error processing participants data: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading participants data'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        print('No participants data found');
        setState(() {
          participants = [];
        });
      }
    }, onError: (error) {
      print('Error in participants listener: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error connecting to database'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  @override
  void dispose() {
    _participantsSubscription?.cancel();
    textToPrintController.dispose();
    amountController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _addParticipantManually() async {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add Participant'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'User ID (digits only)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final id = controller.text.trim();
              if (RegExp(r'^\d+$').hasMatch(id)) {
                // Check if participant already exists
                final participantSnapshot = await _dbRef
                    .child('Events')
                    .child(widget.event.eventId)
                    .child('Participants')
                    .child(id)
                    .get();

                if (participantSnapshot.exists) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Participant ID already exists')),
                  );
                } else {
                  final participant = Participant(
                    id: id,
                    maxTokens: widget.event.amount,
                    textToPrint: widget.event.textToPrint,
                  );
                  setState(() {
                    participants.add(participant);
                  });
                  // Save to Firebase
                  await _dbRef
                      .child('Events')
                      .child(widget.event.eventId)
                      .child('Participants')
                      .child(id)
                      .set(participant.toJson());
                }
              }
              Navigator.pop(context);
            },
            child: Text('Add'),
          )
        ],
      ),
    );
  }

  Future<void> _uploadCSV() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result != null) {
      try {
        final csvContent = utf8.decode(result.files.first.bytes!);
        final ids = parseUserIDsFromCSV(csvContent);
        
        // Check for existing participants
        final existingParticipants = await _dbRef
            .child('Events')
            .child(widget.event.eventId)
            .child('Participants')
            .get();

        final existingIds = existingParticipants.exists
            ? (existingParticipants.value as Map<dynamic, dynamic>).keys.map((k) => k.toString()).toSet()
            : <String>{};

        final newParticipants = ids.where((id) => !existingIds.contains(id)).toList();
        
        if (newParticipants.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No new participants to add')),
          );
          return;
        }

        // Add new participants
        final batch = <String, Map<String, dynamic>>{};
        for (final id in newParticipants) {
          final participant = Participant(
            id: id,
            maxTokens: widget.event.amount,
            textToPrint: widget.event.textToPrint,
          );
          batch[id] = participant.toJson();
        }

        // Update database in a single operation
        await _dbRef
            .child('Events')
            .child(widget.event.eventId)
            .child('Participants')
            .update(batch);

        // The local state will be updated automatically by the _setupParticipantsListener
        // No need to manually update the local state here

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${newParticipants.length} new participants')),
        );
      } catch (e) {
        print('Error uploading CSV: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading CSV file')),
        );
      }
    }
  }

  Future<void> _updateParticipantTokens(Participant participant, int newUsedTokens) async {
    setState(() {
      participant.usedTokens = newUsedTokens;
    });

    try {
      await _dbRef
          .child('Events')
          .child(widget.event.eventId)
          .child('Participants')
          .child(participant.id)
          .update({'usedTokens': newUsedTokens});
    } catch (e) {
      print('Error updating tokens: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating tokens')),
      );
    }
  }

  Future<void> _removeParticipant(Participant participant) async {
    try {
      // Remove from database immediately
      await _dbRef
          .child('Events')
          .child(widget.event.eventId)
          .child('Participants')
          .child(participant.id)
          .remove();
      
      // Update local state
      setState(() {
        participants.remove(participant);
      });
    } catch (e) {
      print('Error removing participant: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing participant')),
      );
    }
  }

  Future<void> _startEvent() async {
    try {
      // Remove any existing live event
      await _dbRef.child('LiveEvent').remove();
      
      // Create new live event with just the event ID as a string value
      await _dbRef.child('LiveEvent').set(widget.event.eventId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Event Started')),
      );
      
      // Create the event object for navigation
      final liveEvent = Event(
        eventId: widget.event.eventId,
        eventTitle: widget.event.eventTitle,
        textToPrint: textToPrintController.text.trim(),
        amount: int.tryParse(amountController.text) ?? 0,
        participants: participants,
      );
      
      Navigator.pop(context, liveEvent);
    } catch (e) {
      print('Error starting event: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting event')),
      );
    }
  }

  Future<void> _saveEvent() async {
    try {
      final newTextToPrint = textToPrintController.text.trim();
      final newAmount = int.tryParse(amountController.text) ?? 0;

      // Update participants with new textToPrint and maxTokens
      final participantsRef = _dbRef
          .child('Events')
          .child(widget.event.eventId)
          .child('Participants');
      
      for (final participant in participants) {
        participant.textToPrint = newTextToPrint;
        participant.maxTokens = newAmount;
        await participantsRef.child(participant.id).set(participant.toJson());
      }

      // Save other event data
      await _dbRef.child('Events').child(widget.event.eventId).update({
        'eventTitle': widget.event.eventTitle,
        'textToPrint': newTextToPrint,
        'amount': newAmount,
      });

      final updatedEvent = Event(
        eventId: widget.event.eventId,
        eventTitle: widget.event.eventTitle,
        textToPrint: newTextToPrint,
        amount: newAmount,
        participants: participants,
      );

      Navigator.pop(context, updatedEvent);
    } catch (e) {
      print('Error saving event: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving event')),
      );
    }
  }

  Future<void> _resetTokens() async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Reset Tokens'),
          content: Text('Are you sure you want to reset all used tokens to 0?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Reset'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Update all participants in the database
      final participantsRef = _dbRef
          .child('Events')
          .child(widget.event.eventId)
          .child('Participants');
      
      for (final participant in participants) {
        participant.usedTokens = 0;
        await participantsRef.child(participant.id).update({
          'usedTokens': 0,
        });
      }

      setState(() {}); // Refresh the UI

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All tokens have been reset')),
      );
    } catch (e) {
      print('Error resetting tokens: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error resetting tokens')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = participants.where((p) => p.id.contains(search)).toList();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.eventTitle),
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        actions: [
          IconButton(
            icon: Icon(Icons.bar_chart),
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
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: textToPrintController,
                        decoration: InputDecoration(
                          labelText: 'Text to Print',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 1,
                        style: TextStyle(fontSize: 14),
                        textAlignVertical: TextAlignVertical.center,
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: amountController,
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        keyboardType: TextInputType.number,
                        style: TextStyle(fontSize: 14),
                        textAlignVertical: TextAlignVertical.center,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _uploadCSV,
                      icon: Icon(Icons.upload_file),
                      label: Text('Upload CSV'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _addParticipantManually,
                      icon: Icon(Icons.person_add),
                      label: Text('Add Participant'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        labelText: 'Search by ID',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) => setState(() => search = value),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      final cardDataController = TextEditingController();
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Read Card'),
                          content: TextField(
                            controller: cardDataController,
                            decoration: InputDecoration(
                              labelText: 'Enter card data',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                final value = cardDataController.text;
                                
                                // Extract the ID using regex
                                final regex = RegExp(r'@%\s*(\d+)\d+\?;\1\?\+');
                                final match = regex.firstMatch(value);
                                if (match != null && match.groupCount >= 1) {
                                  final id = match.group(1)!;
                                  searchController.text = id;
                                  setState(() => search = id);
                                  Navigator.pop(context);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Invalid card format')),
                                  );
                                }
                              },
                              child: Text('Submit'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: Icon(Icons.credit_card),
                    label: Text('Read Card'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _resetTokens,
                    icon: Icon(Icons.refresh),
                    label: Text('Reset'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, index) {
                    final participant = filtered[index];
                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isSmallScreen = constraints.maxWidth < 400;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // ID and Text to Print
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              participant.id,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                          if (participant.textToPrint.isNotEmpty)
                                            Padding(
                                              padding: EdgeInsets.only(top: 4),
                                              child: Text(
                                                participant.textToPrint,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Colors.grey[700],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    // Tokens and Controls
                                    if (!isSmallScreen)
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 4),
                                            child: Text(
                                              '${participant.usedTokens}/${participant.maxTokens}',
                                              style: TextStyle(
                                                color: theme.colorScheme.primary,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.remove_circle_outline, size: 20),
                                            color: theme.colorScheme.primary,
                                            padding: EdgeInsets.all(4),
                                            constraints: BoxConstraints(),
                                            onPressed: participant.usedTokens > 0
                                                ? () => _updateParticipantTokens(
                                                    participant,
                                                    participant.usedTokens - 1)
                                                : null,
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.add_circle_outline, size: 20),
                                            color: theme.colorScheme.primary,
                                            padding: EdgeInsets.all(4),
                                            constraints: BoxConstraints(),
                                            onPressed: participant.usedTokens < participant.maxTokens
                                                ? () => _updateParticipantTokens(
                                                    participant,
                                                    participant.usedTokens + 1)
                                                : null,
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete_outline, size: 20),
                                            color: Colors.red[400],
                                            padding: EdgeInsets.all(4),
                                            constraints: BoxConstraints(),
                                            onPressed: () => _removeParticipant(participant),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                if (isSmallScreen) ...[
                                  SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${participant.usedTokens}/${participant.maxTokens}',
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.remove_circle_outline, size: 20),
                                            color: theme.colorScheme.primary,
                                            padding: EdgeInsets.all(4),
                                            constraints: BoxConstraints(),
                                            onPressed: participant.usedTokens > 0
                                                ? () => _updateParticipantTokens(
                                                    participant,
                                                    participant.usedTokens - 1)
                                                : null,
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.add_circle_outline, size: 20),
                                            color: theme.colorScheme.primary,
                                            padding: EdgeInsets.all(4),
                                            constraints: BoxConstraints(),
                                            onPressed: participant.usedTokens < participant.maxTokens
                                                ? () => _updateParticipantTokens(
                                                    participant,
                                                    participant.usedTokens + 1)
                                                : null,
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete_outline, size: 20),
                                            color: Colors.red[400],
                                            padding: EdgeInsets.all(4),
                                            constraints: BoxConstraints(),
                                            onPressed: () => _removeParticipant(participant),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saveEvent,
                      icon: Icon(Icons.save),
                      label: Text('Save'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _startEvent,
                      icon: Icon(Icons.play_arrow),
                      label: Text('Start Event'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
