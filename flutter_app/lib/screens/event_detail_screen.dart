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
  String search = '';
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    participants = [...widget.event.participants];
    textToPrintController = TextEditingController(text: widget.event.textToPrint);
  }

  @override
  void dispose() {
    textToPrintController.dispose();
    super.dispose();
  }

  Future<void> _addParticipantManually() async {
    if (widget.isLive) {
      return;
    }

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
                    .child('events')
                    .child(widget.event.eventId)
                    .child('participants')
                    .child(id)
                    .get();

                if (participantSnapshot.exists) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Participant ID already exists')),
                  );
                } else {
                  final participant = Participant(id: id);
                  setState(() {
                    participants.add(participant);
                  });
                  // Save to Firebase
                  await _dbRef
                      .child('events')
                      .child(widget.event.eventId)
                      .child('participants')
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
    if (widget.isLive) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result != null) {
      final csvContent = utf8.decode(result.files.first.bytes!);
      final ids = parseUserIDsFromCSV(csvContent);
      
      // Check for existing participants
      final existingParticipants = await _dbRef
          .child('events')
          .child(widget.event.eventId)
          .child('participants')
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
      for (final id in newParticipants) {
        final participant = Participant(id: id);
        setState(() {
          participants.add(participant);
        });
        await _dbRef
            .child('events')
            .child(widget.event.eventId)
            .child('participants')
            .child(id)
            .set(participant.toJson());
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added ${newParticipants.length} new participants')),
      );
    }
  }

  Future<void> _toggleGiftStatus(Participant participant) async {
    if (!widget.isLive) return;

    setState(() {
      participant.hasReceivedGift = !participant.hasReceivedGift;
    });

    try {
      await _dbRef
          .child('liveEvent')
          .child('participants')
          .child(participant.id)
          .set(participant.toJson());
    } catch (e) {
      print('Error updating gift status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating gift status')),
      );
    }
  }

  Future<void> _startEvent() async {
    try {
      // Remove any existing live event
      await _dbRef.child('liveEvent').remove();
      
      // Create new live event data
      final Map<String, dynamic> liveEventData = {
        'eventId': widget.event.eventId,
        'title': widget.event.title,
        'textToPrint': textToPrintController.text.trim(),
        'isLive': true,
      };

      // Save event data first
      await _dbRef.child('liveEvent').update(liveEventData);

      // Save participants individually using their IDs as keys
      final participantsRef = _dbRef.child('liveEvent').child('participants');
      for (final participant in participants) {
        await participantsRef.child(participant.id).set(participant.toJson());
      }

      // Update the original event's isLive status
      await _dbRef.child('events').child(widget.event.eventId).update({
        'isLive': true,
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Event Started')),
      );
      
      // Create the event object for navigation
      final liveEvent = Event(
        eventId: widget.event.eventId,
        title: widget.event.title,
        textToPrint: textToPrintController.text.trim(),
        participants: participants,
        isLive: true,
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
    if (widget.isLive) return;

    try {
      // Save participants individually using their IDs as keys
      final participantsRef = _dbRef
          .child('events')
          .child(widget.event.eventId)
          .child('participants');
      
      for (final participant in participants) {
        await participantsRef.child(participant.id).set(participant.toJson());
      }

      // Save other event data
      await _dbRef.child('events').child(widget.event.eventId).update({
        'title': widget.event.title,
        'textToPrint': textToPrintController.text.trim(),
        'isLive': false,
      });

      final updatedEvent = Event(
        eventId: widget.event.eventId,
        title: widget.event.title,
        textToPrint: textToPrintController.text.trim(),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.title),
        elevation: 0,
        backgroundColor: widget.isLive ? Colors.green : Theme.of(context).colorScheme.primary,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            if (!widget.isLive)
              TextField(
                controller: textToPrintController,
                decoration: InputDecoration(
                  labelText: 'Text to Print',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                enabled: !widget.isLive,
              ),
            SizedBox(height: 16),
            if (!widget.isLive)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _uploadCSV,
                      icon: Icon(Icons.upload_file),
                      label: Text('Upload CSV'),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _addParticipantManually,
                      icon: Icon(Icons.person_add),
                      label: Text('Add Participant'),
                    ),
                  ),
                ],
              ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Search by ID',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
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
                    elevation: 1,
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(participant.id),
                      trailing: widget.isLive
                          ? Switch(
                              value: participant.hasReceivedGift,
                              onChanged: (_) => _toggleGiftStatus(participant),
                              activeColor: Colors.green,
                            )
                          : IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                setState(() {
                                  participants.remove(participant);
                                });
                              },
                            ),
                    ),
                  );
                },
              ),
            ),
            if (!widget.isLive)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saveEvent,
                      icon: Icon(Icons.save),
                      label: Text('Save'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
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
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
