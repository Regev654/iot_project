import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/event.dart';
import '../models/participant.dart';
import 'event_detail_screen.dart';

class EventListScreen extends StatefulWidget {
  @override
  _EventListScreenState createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  List<Event> events = [];
  Event? liveEvent;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    // Listen for real-time updates
    _dbRef.child('events').onValue.listen((event) {
      _loadEvents();
    });
    _dbRef.child('liveEvent').onValue.listen((event) {
      _loadEvents();
    });
  }

  Future<void> _loadEvents() async {
    try {
      final eventsSnapshot = await _dbRef.child('events').get();
      final liveEventSnapshot = await _dbRef.child('liveEvent').get();

      if (mounted) {
        setState(() {
          events = [];
          if (eventsSnapshot.exists) {
            final data = eventsSnapshot.value as Map<dynamic, dynamic>;
            data.forEach((key, value) {
              if (value != null) {
                final Map<String, dynamic> eventData = {};
                (value as Map<dynamic, dynamic>).forEach((k, v) {
                  if (k is String && k != 'participants') {
                    eventData[k] = v;
                  }
                });
                eventData['eventId'] = key.toString();

                if (value['participants'] != null) {
                  final participantsMap = value['participants'] as Map<dynamic, dynamic>;
                  final participantsList = <Map<String, dynamic>>[];
                  participantsMap.forEach((id, data) {
                    if (data != null) {
                      final participantData = Map<String, dynamic>.from(data as Map);
                      participantData['id'] = id.toString();
                      participantsList.add(participantData);
                    }
                  });
                  eventData['participants'] = participantsList;
                } else {
                  eventData['participants'] = [];
                }

                events.add(Event.fromJson(eventData));
              }
            });
          }

          if (liveEventSnapshot.exists && liveEventSnapshot.value != null) {
            final Map<String, dynamic> liveEventData = {};
            final liveEventValue = liveEventSnapshot.value as Map<dynamic, dynamic>;
            
            liveEventValue.forEach((k, v) {
              if (k is String && k != 'participants') {
                liveEventData[k] = v;
              }
            });
            liveEventData['eventId'] = liveEventSnapshot.key;

            if (liveEventValue['participants'] != null) {
              final participantsMap = liveEventValue['participants'] as Map<dynamic, dynamic>;
              final participantsList = <Map<String, dynamic>>[];
              participantsMap.forEach((id, data) {
                if (data != null) {
                  final participantData = Map<String, dynamic>.from(data as Map);
                  participantData['id'] = id.toString();
                  participantsList.add(participantData);
                }
              });
              liveEventData['participants'] = participantsList;
            } else {
              liveEventData['participants'] = [];
            }

            liveEvent = Event.fromJson(liveEventData);
          } else {
            liveEvent = null;
          }
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading events: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading events')),
        );
      }
    }
  }

  void _createEvent() {
    TextEditingController titleController = TextEditingController();
    TextEditingController textToPrintController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Create Event'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Event Title',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: textToPrintController,
              decoration: InputDecoration(
                labelText: 'Text to Print',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (titleController.text.trim().isNotEmpty) {
                final newEvent = Event(
                  eventId: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: titleController.text.trim(),
                  textToPrint: textToPrintController.text.trim(),
                );
                try {
                  await _dbRef.child('events').child(newEvent.eventId).set(newEvent.toJson());
                  Navigator.pop(context);
                } catch (e) {
                  print('Error creating event: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error creating event')),
                  );
                }
              }
            },
            child: Text('Create'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Event Manager'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading events...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                if (liveEvent != null)
                  Container(
                    padding: EdgeInsets.all(16),
                    color: Colors.green.withOpacity(0.1),
                    child: Row(
                      children: [
                        Icon(Icons.live_tv, color: Colors.green),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Live Event',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                liveEvent!.title,
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: events.isEmpty
                      ? Center(
                          child: Text(
                            'No events yet. Create one!',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: events.length,
                          itemBuilder: (_, index) {
                            final event = events[index];
                            return Card(
                              elevation: 2,
                              margin: EdgeInsets.only(bottom: 16),
                              child: ListTile(
                                contentPadding: EdgeInsets.all(16),
                                title: Text(
                                  event.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                subtitle: event.textToPrint.isNotEmpty
                                    ? Padding(
                                        padding: EdgeInsets.only(top: 8),
                                        child: Text(
                                          event.textToPrint,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )
                                    : null,
                                trailing: Icon(Icons.chevron_right),
                                onTap: () async {
                                  final updatedEvent = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EventDetailScreen(
                                        event: event,
                                        isLive: liveEvent?.eventId == event.eventId,
                                      ),
                                    ),
                                  );
                                  if (updatedEvent != null) {
                                    _loadEvents();
                                  }
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createEvent,
        icon: Icon(Icons.add),
        label: Text('New Event'),
      ),
    );
  }
}
