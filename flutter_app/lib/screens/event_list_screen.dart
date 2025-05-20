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
    _dbRef.child('Events').onValue.listen((event) {
      _loadEvents();
    });
    _dbRef.child('LiveEvent').onValue.listen((event) {
      _loadEvents();
    });
  }

  Future<void> _loadEvents() async {
    try {
      print('Loading events from database...'); // Debug print
      final eventsSnapshot = await _dbRef.child('Events').get();
      final liveEventSnapshot = await _dbRef.child('LiveEvent').get();

      if (mounted) {
        setState(() {
          events = [];
          if (eventsSnapshot.exists) {
            print('Events snapshot exists, processing data...'); // Debug print
            final data = eventsSnapshot.value as Map<dynamic, dynamic>;
            print('Raw events data: $data'); // Debug print
            
            data.forEach((key, value) {
              if (value != null) {
                try {
                  final Map<String, dynamic> eventData = Map<String, dynamic>.from(value as Map);
                  eventData['ID'] = key.toString();
                  print('Processing event with ID: $key'); // Debug print
                  print('Event data: $eventData'); // Debug print
                  
                  if (eventData['Participants'] != null) {
                    final participantsMap = eventData['Participants'] as Map<dynamic, dynamic>;
                    eventData['Participants'] = Map<String, dynamic>.from(participantsMap);
                  }
                  
                  events.add(Event.fromJson(eventData));
                } catch (e) {
                  print('Error parsing event $key: $e');
                }
              }
            });
          } else {
            print('No events found in database'); // Debug print
          }

          if (liveEventSnapshot.exists && liveEventSnapshot.value != null) {
            try {
              final liveEventId = liveEventSnapshot.value as String;
              
              // Find the corresponding event from the events list
              final event = events.firstWhere(
                (e) => e.eventId == liveEventId,
                orElse: () => Event(
                  eventId: '',
                  eventTitle: '',
                ),
              );
              
              if (event.eventId.isNotEmpty) {
                liveEvent = event;
              } else {
                liveEvent = null;
              }
            } catch (e) {
              print('Error parsing live event: $e');
              liveEvent = null;
            }
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
    TextEditingController amountController = TextEditingController();

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
              controller: amountController,
              decoration: InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
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
                  eventTitle: titleController.text.trim(),
                  textToPrint: textToPrintController.text.trim(),
                  amount: int.tryParse(amountController.text) ?? 0,
                );
                try {
                  final eventData = newEvent.toJson();
                  print('Creating new event: $eventData'); // Debug print
                  await _dbRef.child('Events').child(newEvent.eventId).set(eventData);
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
                                liveEvent!.eventTitle,
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
                                  event.eventTitle,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (event.textToPrint.isNotEmpty)
                                      Padding(
                                        padding: EdgeInsets.only(top: 8),
                                        child: Text(
                                          event.textToPrint,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    if (event.amount > 0)
                                      Padding(
                                        padding: EdgeInsets.only(top: 4),
                                        child: Text(
                                          'Amount: ${event.amount}',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
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
