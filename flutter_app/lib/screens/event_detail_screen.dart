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
import 'item_edit_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late DatabaseReference _eventRef;
  late StreamSubscription _participantsSubscription;
  late StreamSubscription _defaultItemsSubscription;
  Map<String, Participant> _participants = {};
  bool _isLoading = true;
  String _error = '';
  late TextEditingController _searchController;
  bool _isEditing = false;
  bool _isLiveEvent = false;
  // Remove textToPrint field and editing logic
  // Add default items button and dialog
  Map<String, int> _defaultItems = {};
  bool _showDefaultItems = true;

  @override
  void initState() {
    super.initState();
    _eventRef = FirebaseDatabase.instance.ref().child('EventsV3/${widget.event.eventId}');
    _searchController = TextEditingController();
    _setupParticipantsListener();
    _setupDefaultItemsListener();
    _checkLiveStatus();
  }

  void _setupParticipantsListener() {
    _participantsSubscription = _eventRef.child('Participants').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final participants = <String, Participant>{};
        data.forEach((key, value) {
          final participantData = value as Map<dynamic, dynamic>;
          participants[key.toString()] = Participant.fromJson({
            'ID': key.toString(),
            'items': participantData['items'] ?? {},
          });
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

  void _setupDefaultItemsListener() {
    _defaultItemsSubscription = _eventRef.child('defaultItems').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map?;
        if (data != null) {
          setState(() {
            _defaultItems = data.map((k, v) => MapEntry(k.toString(), v as int));
          });
        }
      } else {
        setState(() {
          _defaultItems = {};
        });
      }
    }, onError: (error) {
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    });
  }

  Future<void> _editDefaultItemsScreen() async {
    final result = await Navigator.push<Map<String, int>>(
      context,
      MaterialPageRoute(
        builder: (context) => ItemEditScreen(
          initialItems: _defaultItems,
          title: 'Edit Default Items',
          eventId: widget.event.eventId,
          isDefaultItems: true,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _defaultItems = result;
      });
      // Update LiveEventV3 if this event is currently live
      await _updateLiveEventDefaultItems();
    }
  }

  Future<void> _makeLiveEvent() async {
    try {
      // Update only the id field
      await FirebaseDatabase.instance.ref().child('LiveEventV3/id').set(widget.event.eventId);
      
      // Update defaultItems only if they exist, otherwise remove the entry
      if (_showDefaultItems && _defaultItems.isNotEmpty) {
        await FirebaseDatabase.instance.ref().child('LiveEventV3/defaultItems').set(_defaultItems);
      } else {
        // Remove defaultItems entry if it exists
        await FirebaseDatabase.instance.ref().child('LiveEventV3/defaultItems').remove();
      }
      
        setState(() => _isLiveEvent = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event is now live')),
          );
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
      final liveEventSnapshot = await FirebaseDatabase.instance.ref().child('LiveEventV3').get();
      if (liveEventSnapshot.exists) {
        final data = liveEventSnapshot.value as Map<dynamic, dynamic>?;
        final liveEventId = data != null && data['id'] != null ? data['id'].toString() : null;
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

  Future<void> _updateLiveEventDefaultItems() async {
    if (!_isLiveEvent) return;
    
    try {
      await FirebaseDatabase.instance.ref().child('LiveEventV3/defaultItems').set(
        _showDefaultItems ? _defaultItems : {},
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating live event default items: $e')),
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
    _defaultItemsSubscription.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _updateParticipantItemTokens(Participant participant, String itemName, int newUsedTokens) async {
    final items = Map<String, Map<String, int>>.from(participant.items);
    final maxTokens = items[itemName]?['maxTokens'] ?? 0;
    if (newUsedTokens < 0 || newUsedTokens > maxTokens) return;
    items[itemName] = {
      'maxTokens': maxTokens,
      'usedTokens': newUsedTokens,
    };
    try {
      await _eventRef.child('Participants/${participant.id}').update({
        'ID': participant.id,
        'items': items,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating tokens: $e')),
        );
      }
    }
  }

  int getActiveUsers() {
    return _participants.values.where((p) => p.items.values.any((item) => (item['usedTokens'] ?? 0) > 0)).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.eventTitle),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            color: Colors.white,
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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
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
                                                ? [Colors.green.shade600, Colors.green.shade800]
                                                : [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)],
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: (_isLiveEvent ? Colors.green : theme.colorScheme.primary).withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: FilledButton.icon(
                                            onPressed: _isLiveEvent ? null : _makeLiveEvent,
                                            icon: Icon(
                                              Icons.live_tv,
                                              size: isWideScreen ? 32 : 28,
                                            ),
                                            label: Text(
                                              _isLiveEvent ? 'Event is Live' : 'Make Live Event',
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
                                              disabledForegroundColor: Colors.white.withOpacity(0.7),
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
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Icon(Icons.people, color: theme.colorScheme.primary, size: 28),
                              SizedBox(height: 4),
                              Text('${_participants.length}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              SizedBox(height: 2),
                              Text('Total Users', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
                            ],
                          ),
                          SizedBox(width: 16),
                          Column(
                            children: [
                              Icon(Icons.person, color: theme.colorScheme.secondary, size: 28),
                              SizedBox(height: 4),
                              Text('${getActiveUsers()}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              SizedBox(height: 2),
                              Text('Active Users', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
                            ],
                          ),
                          if (_participants.isNotEmpty) ...[
                            SizedBox(width: 16),
                            Column(
                              children: [
                                Icon(Icons.percent, color: theme.colorScheme.tertiary, size: 28),
                                SizedBox(height: 4),
                                Text('(${(getActiveUsers() / _participants.length * 100).toStringAsFixed(1)}%)', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)),
                                SizedBox(height: 2),
                                Text('Active %', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Switch(
                                value: _showDefaultItems,
                                onChanged: (val) async {
                                  setState(() {
                                    _showDefaultItems = val;
                                  });
                                  
                                  if (!val) {
                                    // Delete defaultItems from event
                                    try {
                                      await _eventRef.child('defaultItems').remove();
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error removing default items from event: $e')),
                                        );
                                      }
                                    }
                                    
                                    // Delete defaultItems from LiveEventV3 if this event is live
                                    if (_isLiveEvent) {
                                      try {
                                        await FirebaseDatabase.instance.ref().child('LiveEventV3/defaultItems').remove();
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error removing default items from live event: $e')),
                                          );
                                        }
                                      }
                                    }
                                  } else {
                                    // Re-enable: update LiveEventV3 if this event is live
                                    _updateLiveEventDefaultItems();
                                  }
                                },
                                activeColor: theme.colorScheme.primary,
                              ),
                              Text('Add default items', style: theme.textTheme.titleMedium),
                            ],
                          ),
                          if (_showDefaultItems) ...[
                            Row(
                              children: [
                                Text(
                                  'Default Items',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  color: theme.colorScheme.primary,
                                  onPressed: _editDefaultItemsScreen,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_defaultItems.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                children: _defaultItems.entries.map((e) => Chip(label: Text('${e.key}: ${e.value}'))).toList(),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
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
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ..._participants.values
                              .where((p) {
                                final searchText = _searchController.text.toLowerCase();
                                return searchText.isEmpty || p.id.toLowerCase().contains(searchText);
                              })
                              .take(10)
                              .map((participant) {
                                 return Container(
                                   margin: const EdgeInsets.only(bottom: 16),
                                   decoration: BoxDecoration(
                                     color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                     border: Border.all(
                                       color: Colors.grey[300]!,
                                       width: 1,
                                     ),
                                     boxShadow: [
                                       BoxShadow(
                                         color: Colors.black.withOpacity(0.05),
                                         blurRadius: 4,
                                         offset: const Offset(0, 2),
                                       ),
                                     ],
                                   ),
                                   child: Column(
                                     crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                       // Participant ID header
                                       Padding(
                                         padding: const EdgeInsets.all(12),
                                         child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary.withOpacity(0.1),
                                             borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Text(
                                            participant.id,
                                            style: TextStyle(
                                              color: theme.colorScheme.primary,
                                               fontWeight: FontWeight.w600,
                                               fontSize: 14,
                                            ),
                                          ),
                                        ),
                                ),
                                   // Participant items
                                   ...participant.items.entries.map((entry) {
                                  final itemName = entry.key;
                                  final maxTokens = entry.value['maxTokens'] ?? 0;
                                  final usedTokens = entry.value['usedTokens'] ?? 0;
                                  final usagePercentage = maxTokens > 0 ? (usedTokens / maxTokens) * 100 : 0.0;
                                     return Padding(
                                       padding: const EdgeInsets.symmetric(vertical: 12),
                                       child: Column(
                                         children: [
                                           Padding(
                                             padding: const EdgeInsets.symmetric(horizontal: 12),
                                             child: Column(
                                               crossAxisAlignment: CrossAxisAlignment.start,
                                               children: [
                                                 Text(
                                                   itemName,
                                                   style: theme.textTheme.bodyMedium?.copyWith(
                                                     fontWeight: FontWeight.w500,
                                                     color: Colors.grey[800],
                                                   ),
                                                 ),
                                                 const SizedBox(height: 8),
                                                 Row(
                                                   children: [
                                                     Expanded(
                                                       child: LinearProgressIndicator(
                                                         value: usagePercentage / 100,
                                                         backgroundColor: Colors.grey[200],
                                                         valueColor: AlwaysStoppedAnimation<Color>(
                                                           usagePercentage > 80
                                                               ? Colors.red[400]!
                                                               : usagePercentage > 50
                                                                   ? Colors.orange[400]!
                                                                   : Colors.green[400]!,
                                                         ),
                                                         minHeight: 6,
                                                       ),
                                                     ),
                                                     const SizedBox(width: 12),
                                                     Row(
                                                       mainAxisSize: MainAxisSize.min,
                                                       children: [
                                                         Container(
                                                           width: 40,
                                                           height: 40,
                                                           decoration: BoxDecoration(
                                                             color: usedTokens > 0 ? Colors.red[50] : Colors.grey[100],
                                                             borderRadius: BorderRadius.circular(8),
                                                             border: Border.all(
                                                               color: usedTokens > 0 ? Colors.red[200]! : Colors.grey[300]!,
                                                               width: 1,
                                                             ),
                                                           ),
                                                           child: Material(
                                                             color: Colors.transparent,
                                                             child: InkWell(
                                                               borderRadius: BorderRadius.circular(8),
                                                               onTap: usedTokens > 0
                                                                   ? () => _updateParticipantItemTokens(participant, itemName, usedTokens - 1)
                                                                   : null,
                                                               child: Center(
                                                                 child: Text(
                                                                   '-',
                                                                   style: TextStyle(
                                                                     fontSize: 20,
                                                                     fontWeight: FontWeight.bold,
                                                                     color: usedTokens > 0 ? Colors.red[600] : Colors.grey[400],
                                                                   ),
                                                                 ),
                                                               ),
                                                             ),
                                                           ),
                                                         ),
                                                         const SizedBox(width: 8),
                                                         Container(
                                                           width: 40,
                                                           height: 40,
                                                           decoration: BoxDecoration(
                                                             color: usedTokens < maxTokens ? Colors.green[50] : Colors.grey[100],
                                                             borderRadius: BorderRadius.circular(8),
                                                             border: Border.all(
                                                               color: usedTokens < maxTokens ? Colors.green[200]! : Colors.grey[300]!,
                                                               width: 1,
                                                             ),
                                                           ),
                                                           child: Material(
                                                             color: Colors.transparent,
                                                             child: InkWell(
                                                               borderRadius: BorderRadius.circular(8),
                                                               onTap: usedTokens < maxTokens
                                                                   ? () => _updateParticipantItemTokens(participant, itemName, usedTokens + 1)
                                                                   : null,
                                                               child: Center(
                                                                 child: Text(
                                                                   '+',
                                                                   style: TextStyle(
                                                                     fontSize: 20,
                                                                     fontWeight: FontWeight.bold,
                                                                     color: usedTokens < maxTokens ? Colors.green[600] : Colors.grey[400],
                                                                   ),
                                                                 ),
                                                               ),
                                                             ),
                                                           ),
                                                         ),
                                                       ],
                                                     ),
                                                   ],
                                                 ),
                                                 const SizedBox(height: 4),
                                                 Text(
                                                   '$usedTokens/$maxTokens',
                                                   style: theme.textTheme.bodySmall?.copyWith(
                                                     color: Colors.grey[600],
                                                     fontSize: 12,
                                                   ),
                                                 ),
                                               ],
                                             ),
                                           ),
                                           const SizedBox(height: 8),
                                           Container(
                                             margin: const EdgeInsets.symmetric(horizontal: 10),
                                             height: 1,
                                             color: Colors.grey[300],
                                           ),
                                         ],
                                       ),
                                     );
                                }).toList(),
                                 ],
                              ),
                            );
                          }).toList(),
                          if (_participants.length > 10)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'There are more than 10 participants. Use search to find more participants',
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
        ),
      ),
    );
  }
}
