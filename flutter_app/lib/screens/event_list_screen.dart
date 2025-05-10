import 'package:flutter/material.dart';
import '../models/event.dart';
import 'event_detail_screen.dart';

class EventListScreen extends StatefulWidget {
  @override
  _EventListScreenState createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  List<Event> events = [];

  void _createEvent() {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Create Event'),
        content: TextField(controller: controller, decoration: InputDecoration(labelText: 'Event Title')),
        actions: [
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  events.add(Event(eventId: DateTime.now().millisecondsSinceEpoch.toString(), title: controller.text.trim()));
                });
              }
              Navigator.pop(context);
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
      appBar: AppBar(title: Text('Event Manager')),
      body: ListView.builder(
        itemCount: events.length,
        itemBuilder: (_, index) {
          return ListTile(
            title: Text(events[index].title),
            onTap: () async {
              final updatedEvent = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EventDetailScreen(event: events[index])),
              );
              if (updatedEvent != null) {
                setState(() {
                  events[index] = updatedEvent;
                });
              }
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createEvent,
        child: Icon(Icons.add),
      ),
    );
  }
}
