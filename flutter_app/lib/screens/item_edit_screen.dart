import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ItemEditScreen extends StatefulWidget {
  final Map<String, int> initialItems;
  final String title;
  final String? eventId; // Add eventId parameter
  final bool isDefaultItems; // Add flag to indicate if editing default items
  final String? groupId; // Add groupId parameter for group items

  const ItemEditScreen({
    Key? key, 
    required this.initialItems, 
    required this.title,
    this.eventId,
    this.isDefaultItems = false,
    this.groupId,
  }) : super(key: key);

  @override
  State<ItemEditScreen> createState() => _ItemEditScreenState();
}

class _ItemEditScreenState extends State<ItemEditScreen> {
  late Map<String, int> items;
  final nameController = TextEditingController();
  final tokensController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    items = Map<String, int>.from(widget.initialItems);
    _loadItemsFromFirebase();
  }

  Future<void> _loadItemsFromFirebase() async {
    if (widget.eventId == null) return;

    try {
      if (widget.isDefaultItems) {
        // Load default items
        final eventRef = FirebaseDatabase.instance.ref().child('EventsV3/${widget.eventId}/defaultItems');
        final snapshot = await eventRef.get();
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>?;
          if (data != null) {
            setState(() {
              items = data.map((k, v) => MapEntry(k.toString(), v as int));
            });
          }
        }
      } else if (widget.groupId != null) {
        // Load group items
        final groupRef = FirebaseDatabase.instance.ref().child('EventsV3/${widget.eventId}/groups/${widget.groupId}/items');
        final snapshot = await groupRef.get();
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>?;
          if (data != null) {
            final loadedItems = <String, int>{};
            data.forEach((key, value) {
              final itemData = value as Map<dynamic, dynamic>;
              loadedItems[key.toString()] = itemData['maxTokens'] ?? 0;
            });
            setState(() {
              items = loadedItems;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading items from Firebase: $e');
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    tokensController.dispose();
    super.dispose();
  }

  Future<void> _saveItems() async {
    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.eventId != null) {
        if (widget.isDefaultItems) {
          // Save default items to the event
          final eventRef = FirebaseDatabase.instance.ref().child('EventsV3/${widget.eventId}/defaultItems');
          await eventRef.set(items);

          // Also save to LiveEventsV3 if the event is live
          final liveEventRef = FirebaseDatabase.instance.ref().child('LiveEventsV3/${widget.eventId}/defaultItems');
          await liveEventRef.set(items);

          // Don't update participants for default items

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Default items updated successfully')),
            );
          }
        } else if (widget.groupId != null) {
          // Save group items to the specific group
          final groupRef = FirebaseDatabase.instance.ref().child('EventsV3/${widget.eventId}/groups/${widget.groupId}/items');
          
          // Convert items to the format expected by Firebase (Map<String, Map<String, int>>)
          final itemsForFirebase = items.map((key, value) => MapEntry(key, {
            'maxTokens': value,
            'usedTokens': 0,
          }));
          
          await groupRef.set(itemsForFirebase);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Group items updated successfully')),
            );
          }
        } else {
          // For group items without groupId, return items to calling screen
          Navigator.pop(context, items);
          return;
        }
      }

      if (mounted) {
        Navigator.pop(context, items);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving items: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _saveItemToFirebase(String itemName, int maxTokens) async {
    if (widget.eventId == null) return;

    try {
      if (widget.isDefaultItems) {
        // Save to default items in the event
        final eventRef = FirebaseDatabase.instance.ref().child('EventsV3/${widget.eventId}/defaultItems');
        await eventRef.child(itemName).set(maxTokens);
        
        // Also save to LiveEventsV3 if the event is live
        final liveEventRef = FirebaseDatabase.instance.ref().child('LiveEventsV3/${widget.eventId}/defaultItems');
        await liveEventRef.child(itemName).set(maxTokens);
        
        // Don't update participants for default items
      } else if (widget.groupId != null) {
        // Save to group items
        final groupRef = FirebaseDatabase.instance.ref().child('EventsV3/${widget.eventId}/groups/${widget.groupId}/items');
        await groupRef.child(itemName).set({
          'maxTokens': maxTokens,
          'usedTokens': 0,
        });
        
        // Update all participants in this group with the new item
        await _updateParticipantsForGroup();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving item: $e')),
        );
      }
    }
  }

  Future<void> _removeItemFromFirebase(String itemName) async {
    if (widget.eventId == null) return;

    try {
      if (widget.isDefaultItems) {
        // Remove from default items in the event
        final eventRef = FirebaseDatabase.instance.ref().child('EventsV3/${widget.eventId}/defaultItems');
        await eventRef.child(itemName).remove();
        
        // Also remove from LiveEventsV3 if the event is live
        final liveEventRef = FirebaseDatabase.instance.ref().child('LiveEventsV3/${widget.eventId}/defaultItems');
        await liveEventRef.child(itemName).remove();
        
        // Don't update participants for default items
      } else if (widget.groupId != null) {
        // Remove from group items
        final groupRef = FirebaseDatabase.instance.ref().child('EventsV3/${widget.eventId}/groups/${widget.groupId}/items');
        await groupRef.child(itemName).remove();
        
        // Update all participants in this group to remove the item
        await _updateParticipantsForGroup();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing item: $e')),
        );
      }
    }
  }

  Future<void> _updateAllParticipantsItems() async {
    if (widget.eventId == null) return;

    final participantsRef = FirebaseDatabase.instance.ref().child('EventsV3/${widget.eventId}/Participants');
    
    try {
      // Get all participants
      final participantsSnapshot = await participantsRef.get();
      if (!participantsSnapshot.exists) return;

      final participantsData = participantsSnapshot.value as Map<dynamic, dynamic>;
      final batch = <String, Map<String, dynamic>>{};

      for (final participantEntry in participantsData.entries) {
        final participantId = participantEntry.key.toString();
        final participantData = participantEntry.value as Map<dynamic, dynamic>;
        final currentItems = participantData['items'] as Map<dynamic, dynamic>? ?? {};

        // Start with existing items (preserve usedTokens)
        final updatedItems = <String, Map<String, int>>{};
        
        // Add existing items (preserve usedTokens)
        currentItems.forEach((itemName, itemData) {
          final itemMap = itemData as Map<dynamic, dynamic>;
          updatedItems[itemName.toString()] = {
            'maxTokens': itemMap['maxTokens'] ?? 0,
            'usedTokens': itemMap['usedTokens'] ?? 0,
          };
        });

        // Add or update default items (add to existing, don't override)
        for (final defaultItem in items.entries) {
          final itemName = defaultItem.key;
          final maxTokens = defaultItem.value;
          
          if (updatedItems.containsKey(itemName)) {
            // If item already exists, add to maxTokens and preserve usedTokens
            final currentMaxTokens = updatedItems[itemName]!['maxTokens'] ?? 0;
            final currentUsedTokens = updatedItems[itemName]!['usedTokens'] ?? 0;
            updatedItems[itemName] = {
              'maxTokens': currentMaxTokens + maxTokens,
              'usedTokens': currentUsedTokens,
            };
          } else {
            // Add new default item
            updatedItems[itemName] = {
              'maxTokens': maxTokens,
              'usedTokens': 0,
            };
          }
        }

        batch[participantId] = {
          'ID': participantId,
          'items': updatedItems,
        };
      }

      // Update all participants in a single batch operation
      if (batch.isNotEmpty) {
        await participantsRef.update(batch);
      }
    } catch (e) {
      print('Error updating participants: $e');
      rethrow;
    }
  }

  Future<void> _updateParticipantsForGroup() async {
    if (widget.eventId == null || widget.groupId == null) return;

    final participantsRef = FirebaseDatabase.instance.ref().child('EventsV3/${widget.eventId}/Participants');
    final groupsRef = FirebaseDatabase.instance.ref().child('EventsV3/${widget.eventId}/groups');
    
    try {
      // Get the current group to find its participants
      final groupSnapshot = await groupsRef.child(widget.groupId!).get();
      if (!groupSnapshot.exists) return;
      
      final groupData = groupSnapshot.value as Map<dynamic, dynamic>;
      final participantIds = List<String>.from(groupData['participantIds'] ?? []);
      
      // Get all groups to calculate total items for each participant
      final allGroupsSnapshot = await groupsRef.get();
      if (!allGroupsSnapshot.exists) return;
      
      final allGroupsData = allGroupsSnapshot.value as Map<dynamic, dynamic>;
      final batch = <String, Map<String, dynamic>>{};
      
      for (final participantId in participantIds) {
        // Calculate items from all groups this participant is in
        final items = <String, Map<String, int>>{};
        
        for (final groupEntry in allGroupsData.entries) {
          final groupId = groupEntry.key.toString();
          final groupData = groupEntry.value as Map<dynamic, dynamic>;
          final groupParticipantIds = List<String>.from(groupData['participantIds'] ?? []);
          
          if (groupParticipantIds.contains(participantId)) {
            final groupItems = groupData['items'] as Map<dynamic, dynamic>? ?? {};
            groupItems.forEach((itemName, itemData) {
              final itemMap = itemData as Map<dynamic, dynamic>;
              final maxTokens = itemMap['maxTokens'] ?? 0;
              if (maxTokens > 0) {
                items[itemName.toString()] = {
                  'maxTokens': ((items[itemName]?['maxTokens'] ?? 0) + maxTokens).toInt(),
                  'usedTokens': items[itemName]?['usedTokens'] ?? 0,
                };
              }
            });
          }
        }
        
        // Get current participant data to preserve usedTokens
        final participantSnapshot = await participantsRef.child(participantId).get();
        if (participantSnapshot.exists) {
          final participantData = participantSnapshot.value as Map<dynamic, dynamic>;
          final currentItems = participantData['items'] as Map<dynamic, dynamic>? ?? {};
          
          // Preserve usedTokens for existing items
          items.forEach((itemName, itemData) {
            final currentUsedTokens = currentItems[itemName]?['usedTokens'] ?? 0;
            items[itemName] = {
              'maxTokens': itemData['maxTokens'] ?? 0,
              'usedTokens': currentUsedTokens > (itemData['maxTokens'] ?? 0) ? (itemData['maxTokens'] ?? 0) : currentUsedTokens,
            };
          });
        }
        
        batch[participantId] = {
          'ID': participantId,
          'items': items,
        };
      }
      
      // Update all participants in a single batch operation
      if (batch.isNotEmpty) {
        await participantsRef.update(batch);
      }
    } catch (e) {
      print('Error updating participants for group: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveItems,
              child: Text('Save', style: TextStyle(color: theme.colorScheme.onPrimary)),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text('No items yet. Add your first item below!', style: theme.textTheme.bodyLarge),
                ),
              Expanded(
                child: ListView(
                  children: items.entries.map((entry) => Card(
                    color: theme.colorScheme.surfaceVariant ?? Colors.grey[100],
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: Icon(Icons.label, color: theme.colorScheme.primary),
                      title: Text(entry.key, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      subtitle: Text('Max Tokens: ${entry.value}', style: theme.textTheme.bodyMedium),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: theme.colorScheme.error),
                        onPressed: () async {
                          final itemName = entry.key;
                          setState(() {
                            items.remove(entry.key);
                          });
                          await _removeItemFromFirebase(itemName);
                        },
                      ),
                      onTap: () {
                        nameController.text = entry.key;
                        tokensController.text = entry.value.toString();
                      },
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                child: Column(
                  children: [
                    Card(
                      color: theme.colorScheme.surfaceVariant ?? Colors.grey[100],
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: nameController,
                                decoration: InputDecoration(
                                  labelText: 'Item Name',
                                  prefixIcon: Icon(Icons.label_outline),
                                  hintText: 'e.g. Free Pizza',
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: tokensController,
                                decoration: InputDecoration(
                                  labelText: 'Max Tokens',
                                  prefixIcon: Icon(Icons.confirmation_num_outlined),
                                  hintText: 'e.g. 2',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          final tokens = int.tryParse(tokensController.text.trim()) ?? 0;
                          if (name.isNotEmpty && tokens > 0) {
                            setState(() {
                              items[name] = tokens;
                              nameController.clear();
                              tokensController.clear();
                            });
                            await _saveItemToFirebase(name, tokens);
                          }
                        },
                        icon: Icon(Icons.add),
                        label: Text('Add/Update Item'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: theme.textTheme.titleMedium,
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 