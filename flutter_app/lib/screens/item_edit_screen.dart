import 'package:flutter/material.dart';

class ItemEditScreen extends StatefulWidget {
  final Map<String, int> initialItems;
  final String title;

  const ItemEditScreen({Key? key, required this.initialItems, required this.title}) : super(key: key);

  @override
  State<ItemEditScreen> createState() => _ItemEditScreenState();
}

class _ItemEditScreenState extends State<ItemEditScreen> {
  late Map<String, int> items;
  final nameController = TextEditingController();
  final tokensController = TextEditingController();

  @override
  void initState() {
    super.initState();
    items = Map<String, int>.from(widget.initialItems);
  }

  @override
  void dispose() {
    nameController.dispose();
    tokensController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, items);
            },
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
                        onPressed: () {
                          setState(() {
                            items.remove(entry.key);
                          });
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
                        onPressed: () {
                          final name = nameController.text.trim();
                          final tokens = int.tryParse(tokensController.text.trim()) ?? 0;
                          if (name.isNotEmpty && tokens > 0) {
                            setState(() {
                              items[name] = tokens;
                              nameController.clear();
                              tokensController.clear();
                            });
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