import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import '../models/event.dart';
import '../models/group.dart';

class GroupsScreen extends StatefulWidget {
  final Event event;

  const GroupsScreen({super.key, required this.event});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  late DatabaseReference _groupsRef;
  late StreamSubscription<DatabaseEvent> _groupsSubscription;
  Map<String, Group> _groups = {};
  bool _isLoading = true;
  String _error = '';
  final Map<String, TextEditingController> _searchControllers = {};
  final Map<String, bool> _showAllParticipants = {};
  final Map<String, bool> _isLoadingParticipants = {};

  @override
  void initState() {
    super.initState();
    _groupsRef = FirebaseDatabase.instance.ref().child('EventsV3/${widget.event.eventId}/groups');
    _setupGroupsListener();
  }

  void _setupGroupsListener() {
    _groupsSubscription = _groupsRef.onValue.listen((event) {
      if (!mounted) return;

      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final groups = <String, Group>{};
        
        data.forEach((key, value) {
          if (value != null) {
            final groupData = value as Map<dynamic, dynamic>;
            final rawItems = groupData['items'] as Map?;
            final items = <String, Map<String, int>>{};
            if (rawItems != null) {
              rawItems.forEach((k, v) {
                items[k.toString()] = Map<String, int>.from(v as Map);
              });
            }
            groups[key.toString()] = Group(
              groupId: key.toString(),
              groupName: groupData['groupName'] ?? '',
              participantIds: List<String>.from(groupData['participantIds'] ?? []),
              items: items,
            );
          }
        });

        setState(() {
          _groups = groups;
          _isLoading = false;
        });
      } else {
        setState(() {
          _groups = {};
          _isLoading = false;
        });
      }
    }, onError: (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _groupsSubscription.cancel();
    for (final controller in _searchControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _addGroup() async {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Group'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a group name';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final newGroupRef = _groupsRef.push();
        final newGroup = Group(
          groupId: newGroupRef.key!,
          groupName: nameController.text,
          participantIds: [],
          items: {},
        );

        await newGroupRef.set(newGroup.toMap());
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding group: $e')),
          );
        }
      }
    }
  }

  // Add a helper to validate Firebase keys
  bool isValidFirebaseKey(String key) {
    if (key.isEmpty) return false;
    return !key.contains(RegExp(r'[.#$\[\]/]'));
  }

  // Fix participant creation logic to only set items with valid keys
  Future<void> _addParticipant(String groupId) async {
    if (groupId.isEmpty) {
      print('Error: Tried to add participant with empty groupId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Invalid group.')),
        );
      }
      return;
    }
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Participant'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Participant ID',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter participant ID';
              }
              if (!isValidFirebaseKey(value)) {
                return 'Invalid ID: cannot contain . # \$ [ ] / or be empty';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, controller.text);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        if (result.isEmpty || !isValidFirebaseKey(result)) {
          print('Manual add: empty or invalid participant ID, skipping.');
          return;
        }
        print('Manual add: groupId=$groupId, eventId=${widget.event.eventId}, participantId=$result');
        final groupRef = _groupsRef.child(groupId);
        final groupSnapshot = await groupRef.get();
        if (!groupSnapshot.exists) {
          throw Exception('Group not found');
        }

        final group = Group.fromJson(groupSnapshot.value as Map<dynamic, dynamic>);
        if (group.participantIds.contains(result)) {
          throw Exception('Participant already exists in this group');
        }

        final updatedParticipants = <String>{
          ...group.participantIds.map((e) => e.toString()),
          result.toString(),
        }.toList();

        print('Manual add: updatedParticipants = ${updatedParticipants.join(", ")}');
        await groupRef.update({
          'participantIds': updatedParticipants,
        });

        // Add to event's Participants node
        final participantsRef = FirebaseDatabase.instance.ref().child('EventsV3/${widget.event.eventId}/Participants');
        // Build items from all groups this participant is in
        final allGroups = _groups.values.where((g) => g.participantIds.contains(result) || g.groupId == groupId);
        final items = <String, Map<String, int>>{};
        for (final g in allGroups) {
          g.items.forEach((itemName, itemData) {
            if (isValidFirebaseKey(itemName)) {
              items[itemName] = {
                'maxTokens': (items[itemName]?['maxTokens'] ?? 0) + (itemData['maxTokens'] ?? 0),
                'usedTokens': 0,
              };
            }
          });
        }
        await participantsRef.child(result).set({
          'ID': result,
          'items': items,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Participant added')),
          );
        }
      } catch (e) {
        if (mounted) {
          print('Error adding participant: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding participant: $e')),
          );
        }
      }
    }
  }

  Future<void> _uploadCSV(String groupId) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        final file = result.files.first;
        final bytes = file.bytes;
        if (bytes == null) {
          throw Exception('Failed to read file');
        }

        final csvString = String.fromCharCodes(bytes);
        final lines = csvString.split('\n');
        final participants = <String>[];
        final invalidParticipants = <String>[];
        final invalidPattern = RegExp(r'[.#$\[\]]');

        // Skip header if present
        int startIdx = 0;
        if (lines.isNotEmpty && lines[0].trim().toLowerCase() == 'testid') {
          startIdx = 1;
        }

        for (var i = startIdx; i < lines.length; i++) {
          var line = lines[i].trim();
          if (line.isNotEmpty && !invalidPattern.hasMatch(line)) {
            participants.add(line);
          } else if (line.isNotEmpty) {
            invalidParticipants.add(line);
          }
        }

        // Remove any empty strings just in case
        participants.removeWhere((id) => id.isEmpty);
        invalidParticipants.removeWhere((id) => id.isEmpty);

        print('CSV upload: groupId=$groupId, eventId=${widget.event.eventId}');
        print('CSV upload: participants = ${participants.join(", ")}\ninvalid = ${invalidParticipants.join(", ")}');

        if (participants.isEmpty) {
          throw Exception('No valid participants found in CSV');
        }

        final groupRef = _groupsRef.child(groupId);
        final groupSnapshot = await groupRef.get();
        if (!groupSnapshot.exists) {
          throw Exception('Group not found');
        }

        final group = Group.fromJson(groupSnapshot.value as Map<dynamic, dynamic>);
        final updatedParticipants = <String>{
          ...group.participantIds.map((e) => e.toString()),
          ...participants.map((e) => e.toString()),
        }.toList();

        print('CSV upload: updatedParticipants = ${updatedParticipants.join(", ")}');
        await groupRef.update({
          'participantIds': updatedParticipants,
        });

        // Add to event's Participants node
        final participantsRef = FirebaseDatabase.instance.ref().child('EventsV3/${widget.event.eventId}/Participants');
        final batch = <String, Map<String, dynamic>>{};
        for (final participantId in participants) {
          if (participantId.isEmpty) {
            print('CSV upload: Skipping empty participantId');
            continue;
          }
          // Calculate new maxTokens as sum of all group amounts for this participant
          int totalTokens = 0;
          for (final g in _groups.values) {
            if (g.participantIds.contains(participantId)) {
              totalTokens += g.items.values.fold(0, (sum, item) => sum + (item['maxTokens'] ?? 0));
            }
          }
          // Also add the current group if not yet in _groups (for new group)
          if (!(_groups[groupId]?.participantIds.contains(participantId) ?? false)) {
            totalTokens += group.items.values.fold(0, (sum, item) => sum + (item['maxTokens'] ?? 0));
          }
          batch[participantId] = {
            'ID': participantId,
            'items': [
              {widget.event.textToPrint: {'maxTokens': totalTokens, 'usedTokens': 0}}
            ],
          };
        }
        print('Batch keys: ${batch.keys.toList()}');
        if (batch.keys.any((k) => k.isEmpty)) {
          throw Exception('Batch contains empty participant ID');
        }
        if (batch.isNotEmpty) {
          await participantsRef.update(batch);
        }

        if (mounted) {
          String msg = 'Added ${participants.length} participants';
          if (invalidParticipants.isNotEmpty) {
            msg += '\nIgnored invalid IDs: ${invalidParticipants.join(", ")}';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        print('Error uploading CSV: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading CSV: $e')),
        );
      }
    }
  }

  Future<void> _removeParticipant(String groupId, String participantId) async {
    try {
      final groupRef = _groupsRef.child(groupId);
      final groupSnapshot = await groupRef.get();
      if (!groupSnapshot.exists) {
        throw Exception('Group not found');
      }

      final group = Group.fromJson(groupSnapshot.value as Map<dynamic, dynamic>);
      final updatedParticipants = List<String>.from(group.participantIds)
        ..remove(participantId);

      await groupRef.update({
        'participantIds': updatedParticipants,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Participant removed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing participant: $e')),
        );
      }
    }
  }

  Future<void> _deleteGroup(String groupId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text(
          'Are you sure you want to delete the group "${_groups[groupId]?.groupName}"? This action cannot be undone.',
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
      // Get the group before deleting it
      final groupToDelete = _groups[groupId];
      if (groupToDelete == null) {
        throw Exception('Group not found');
      }

      // Get all participants in this group
      final participantsToUpdate = groupToDelete.participantIds;

      // Delete the group first
      await _groupsRef.child(groupId).remove();

      // Update maxTokens for all participants in the deleted group
      final participantsRef = FirebaseDatabase.instance.ref().child('EventsV3/${widget.event.eventId}/Participants');
      final batch = <String, Map<String, dynamic>>{};

      for (final participantId in participantsToUpdate) {
        // Calculate new maxTokens by summing amounts from remaining groups
        int totalTokens = 0;
        for (final group in _groups.values) {
          if (group.groupId != groupId && group.participantIds.contains(participantId)) {
            totalTokens += group.items.values.fold(0, (sum, item) => sum + (item['maxTokens'] ?? 0));
          }
        }

        // Get current participant data
        final participantSnapshot = await participantsRef.child(participantId).get();
        if (participantSnapshot.exists) {
          final participantData = participantSnapshot.value as Map<dynamic, dynamic>;
          final items = participantData['items'] as List<dynamic>? ?? [];
          // Find the item for this event's textToPrint
          int usedTokens = 0;
          int idx = items.indexWhere((i) => i.containsKey(widget.event.textToPrint));
          if (idx != -1) {
            usedTokens = items[idx][widget.event.textToPrint]['usedTokens'] ?? 0;
            // Update the item
            items[idx][widget.event.textToPrint] = {
              'maxTokens': totalTokens,
              'usedTokens': usedTokens > totalTokens ? totalTokens : usedTokens,
            };
          } else {
            items.add({widget.event.textToPrint: {'maxTokens': totalTokens, 'usedTokens': 0}});
          }
          batch[participantId] = {
            'ID': participantId,
            'items': items,
          };
        }
      }

      // Apply all updates in a single batch
      if (batch.isNotEmpty) {
        await participantsRef.update(batch);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group deleted and participant tokens updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting group: $e')),
        );
      }
    }
  }

  void _showParticipantDetails(String groupId, String participantId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Participant Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: $participantId'),
            const SizedBox(height: 8),
            Text('Group: ${_groups[groupId]?.groupName ?? "Unknown"}'),
            const SizedBox(height: 8),
            Text('Token Amount: ${_groups[groupId]?.items.values.fold(0, (sum, item) => sum + (item['maxTokens'] ?? 0)) ?? 0}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              _removeParticipant(groupId, participantId);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  // Add this helper function to update all participants' items after group items change
  Future<void> _updateAllParticipantsForEvent() async {
    final participantsRef = FirebaseDatabase.instance.ref().child('EventsV3/${widget.event.eventId}/Participants');
    // Gather all group items and participantIds
    final Map<String, Map<String, int>> participantItems = {};
    for (final group in _groups.values) {
      for (final pid in group.participantIds) {
        participantItems.putIfAbsent(pid, () => {});
        for (final entry in group.items.entries) {
          final itemName = entry.key;
          final maxTokens = entry.value['maxTokens'] ?? 0;
          participantItems[pid]![itemName] = (participantItems[pid]![itemName] ?? 0) + maxTokens;
        }
      }
    }
    // Update each participant's items
    for (final pid in participantItems.keys) {
      final itemsMap = <String, Map<String, int>>{};
      participantItems[pid]!.forEach((itemName, maxTokens) {
        itemsMap[itemName] = {'maxTokens': maxTokens, 'usedTokens': 0};
      });
      await participantsRef.child(pid).update({'ID': pid, 'items': itemsMap});
    }
  }

  // Add this dialog for adding/editing items for a group
  Future<void> _editGroupItemsDialog(Group group) async {
    final items = Map<String, Map<String, int>>.from(group.items);
    final nameController = TextEditingController();
    final tokensController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit Items for ${group.groupName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...items.entries.map((entry) => ListTile(
                    title: Text(entry.key),
                    subtitle: Text('Max Tokens: ${entry.value['maxTokens'] ?? 0}'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          items.remove(entry.key);
                        });
                      },
                    ),
                    onTap: () {
                      nameController.text = entry.key;
                      tokensController.text = (entry.value['maxTokens'] ?? 0).toString();
                    },
                  )),
              Divider(),
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Item Name'),
              ),
              TextField(
                controller: tokensController,
                decoration: InputDecoration(labelText: 'Max Tokens'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final tokens = int.tryParse(tokensController.text.trim()) ?? 0;
                  if (name.isNotEmpty && tokens > 0) {
                    setState(() {
                      items[name] = {'maxTokens': tokens, 'usedTokens': 0};
                      nameController.clear();
                      tokensController.clear();
                    });
                  }
                },
                child: Text('Add/Update Item'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                // Save items to group
                await _groupsRef.child(group.groupId).update({'items': items});
                Navigator.pop(context);
                // After saving, update all participants
                await _updateAllParticipantsForEvent();
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.event.eventTitle} Groups'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : _groups.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.group_off,
                                size: 64,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No Groups Yet',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Add your first group to get started',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _groups.length,
                        itemBuilder: (context, index) {
                          final group = _groups.values.elementAt(index);
                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    theme.colorScheme.primary.withOpacity(0.1),
                                    theme.colorScheme.surface,
                                  ],
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.group,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          group.groupName,
                                          style: theme.textTheme.titleLarge?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.add),
                                        tooltip: 'Add Item',
                                        onPressed: () => _editGroupItemsDialog(group),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.edit),
                                        tooltip: 'Edit Items',
                                        onPressed: () => _editGroupItemsDialog(group),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        color: theme.colorScheme.error,
                                        onPressed: () => _deleteGroup(group.groupId),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      _buildStatChip(
                                        theme,
                                        Icons.people,
                                        '${group.participantIds.length} Participants',
                                        theme.colorScheme.tertiary,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: _searchControllers.putIfAbsent(
                                      group.groupId,
                                      () => TextEditingController(),
                                    ),
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
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      if (_isLoadingParticipants[group.groupId] == true)
                                        const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        )
                                      else
                                        ...group.participantIds
                                            .where((id) {
                                              final searchText = _searchControllers[group.groupId]?.text.toLowerCase() ?? '';
                                              return searchText.isEmpty || id.toLowerCase().contains(searchText);
                                            })
                                            .take(_showAllParticipants[group.groupId] == true ? 999999 : 10)
                                            .map((participantId) => FilterChip(
                                                  label: Text(participantId),
                                                  deleteIcon: const Icon(Icons.close),
                                                  onDeleted: () => _removeParticipant(group.groupId, participantId),
                                                  onSelected: (_) => _showParticipantDetails(group.groupId, participantId),
                                                  selected: false,
                                                )),
                                      if (group.participantIds.length > 10 && !(_showAllParticipants[group.groupId] ?? false))
                                        TextButton.icon(
                                          onPressed: () async {
                                            setState(() {
                                              _isLoadingParticipants[group.groupId] = true;
                                            });
                                            // Simulate loading delay to prevent UI freeze
                                            await Future.delayed(const Duration(milliseconds: 100));
                                            setState(() {
                                              _showAllParticipants[group.groupId] = true;
                                              _isLoadingParticipants[group.groupId] = false;
                                            });
                                          },
                                          icon: const Icon(Icons.expand_more),
                                          label: const Text('Load All'),
                                        ),
                                      ActionChip(
                                        avatar: const Icon(Icons.add),
                                        label: const Text('Add Participant'),
                                        onPressed: () => _addParticipant(group.groupId),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: FilledButton.icon(
                                          onPressed: () => _uploadCSV(group.groupId),
                                          icon: const Icon(Icons.upload_file),
                                          label: const Text('Upload CSV'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addGroup,
        icon: const Icon(Icons.add),
        label: const Text('Add Group'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildStatChip(
    ThemeData theme,
    IconData icon,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
} 