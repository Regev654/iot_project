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

  @override
  void initState() {
    super.initState();
    _groupsRef = FirebaseDatabase.instance.ref().child('Events/${widget.event.eventId}/groups');
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
            groups[key.toString()] = Group.fromJson(value as Map<dynamic, dynamic>);
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
    super.dispose();
  }

  Future<void> _addGroup() async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
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
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Token Amount',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a token amount';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
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
          amount: int.parse(amountController.text),
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
        if (result.isEmpty) {
          print('Manual add: empty participant ID, skipping.');
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
        final participantsRef = FirebaseDatabase.instance.ref().child('Events/${widget.event.eventId}/Participants');
        // Calculate new maxTokens as sum of all group amounts for this participant
        int totalTokens = 0;
        for (final g in _groups.values) {
          if (g.participantIds.contains(result)) {
            totalTokens += g.amount;
          }
        }
        // Also add the current group if not yet in _groups (for new group)
        if (!(_groups[groupId]?.participantIds.contains(result) ?? false)) {
          totalTokens += group.amount;
        }
        await participantsRef.child(result).set({
          'maxTokens': totalTokens,
          'usedTokens': 0,
          'textToPrint': widget.event.textToPrint,
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
        final participantsRef = FirebaseDatabase.instance.ref().child('Events/${widget.event.eventId}/Participants');
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
              totalTokens += g.amount;
            }
          }
          // Also add the current group if not yet in _groups (for new group)
          if (!(_groups[groupId]?.participantIds.contains(participantId) ?? false)) {
            totalTokens += group.amount;
          }
          batch[participantId] = {
            'maxTokens': totalTokens,
            'usedTokens': 0,
            'textToPrint': widget.event.textToPrint,
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
    try {
      await _groupsRef.child(groupId).remove();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group deleted')),
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
                                        Icons.token,
                                        '${group.amount} Tokens',
                                        theme.colorScheme.secondary,
                                      ),
                                      const SizedBox(width: 12),
                                      _buildStatChip(
                                        theme,
                                        Icons.people,
                                        '${group.participantIds.length} Participants',
                                        theme.colorScheme.tertiary,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      ...group.participantIds.map((participantId) => Chip(
                                            label: Text(participantId),
                                            deleteIcon: const Icon(Icons.close),
                                            onDeleted: () => _removeParticipant(group.groupId, participantId),
                                          )),
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