import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import '../models/event.dart';
import '../models/participant.dart';
import '../utils/csv_parser.dart';

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
  String search = '';
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    participants = [...widget.event.participants];
    textToPrintController = TextEditingController(text: widget.event.textToPrint);
    amountController = TextEditingController(text: widget.event.amount.toString());
  }

  @override
  void dispose() {
    textToPrintController.dispose();
    amountController.dispose();
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

        // Update local state
        setState(() {
          participants.addAll(
            newParticipants.map((id) => Participant(
              id: id,
              maxTokens: widget.event.amount,
              textToPrint: widget.event.textToPrint,
            )),
          );
        });

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

  @override
  Widget build(BuildContext context) {
    final filtered = participants.where((p) => p.id.contains(search)).toList();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.eventTitle),
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: textToPrintController,
                          decoration: InputDecoration(
                            labelText: 'Text to Print',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          maxLines: 3,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: amountController,
                          decoration: InputDecoration(
                            labelText: 'Amount',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          keyboardType: TextInputType.number,
                        ),
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
              TextField(
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
                        child: Row(
                          children: [
                            // ID and Text to Print
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
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
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      '${participant.usedTokens}/${participant.maxTokens}',
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(Icons.remove_circle_outline, size: 24),
                                    color: theme.colorScheme.primary,
                                    padding: EdgeInsets.all(4),
                                    constraints: BoxConstraints(),
                                    onPressed: participant.usedTokens > 0
                                        ? () => _updateParticipantTokens(
                                            participant,
                                            participant.usedTokens - 1)
                                        : null,
                                  ),
                                  SizedBox(width: 4),
                                  IconButton(
                                    icon: Icon(Icons.add_circle_outline, size: 24),
                                    color: theme.colorScheme.primary,
                                    padding: EdgeInsets.all(4),
                                    constraints: BoxConstraints(),
                                    onPressed: participant.usedTokens < participant.maxTokens
                                        ? () => _updateParticipantTokens(
                                            participant,
                                            participant.usedTokens + 1)
                                        : null,
                                  ),
                                  SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline, size: 24),
                                    color: Colors.red[400],
                                    padding: EdgeInsets.all(4),
                                    constraints: BoxConstraints(),
                                    onPressed: () => _removeParticipant(participant),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
