import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import '../models/event.dart';
import '../utils/csv_parser.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;
  EventDetailScreen({required this.event});

  @override
  _EventDetailScreenState createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late List<String> participants;
  String search = '';

  @override
  void initState() {
    super.initState();
    participants = [...widget.event.participants];
  }

  void _addParticipantManually() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add Participant'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: 'User ID (digits only)'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () {
              final id = controller.text.trim();
              if (RegExp(r'^\d+$').hasMatch(id) && !participants.contains(id)) {
                setState(() {
                  participants.add(id);
                });
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
      final csvContent = utf8.decode(result.files.first.bytes!);
      final ids = parseUserIDsFromCSV(csvContent);
      setState(() {
        participants = {
          ...participants,
          ...ids,
        }.toList(); // remove duplicates
      });
    }
  }

  Future<void> _uploadEventToFirebase(String action) async {
    final dbRef = FirebaseDatabase.instance.ref();
    print('Uploading event to Firebase: ${widget.event.eventId}');
    try {
      await dbRef.child('events').child(widget.event.eventId).set({
        'title': widget.event.title,
        'participants': participants,
        'action': action,
        'timestamp': DateTime.now().toIso8601String(),
      });
      print('Event uploaded successfully');
    } catch (e) {
      print('Error uploading event: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = participants.where((p) => p.contains(search)).toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.event.title)),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: _uploadCSV,
                  child: Text('Upload CSV'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addParticipantManually,
                  child: Text('Add Participant'),
                ),
              ],
            ),
            SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(labelText: 'Search by ID'),
              onChanged: (value) => setState(() => search = value),
            ),
            SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (_, index) {
                  return ListTile(
                    title: Text(filtered[index]),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          participants.remove(filtered[index]);
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _uploadEventToFirebase("saved");
                      Navigator.pop(
                        context,
                        Event(
                          eventId: widget.event.eventId,
                          title: widget.event.title,
                          participants: participants,
                        ),
                      );
                    },
                    child: Text('Save'),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _uploadEventToFirebase("started");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Event Started')),
                      );
                    },
                    child: Text('Start Event'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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
