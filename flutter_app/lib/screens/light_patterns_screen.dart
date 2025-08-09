import 'package:flutter/material.dart';
import 'package:gif/gif.dart';

class LightPatternsScreen extends StatelessWidget {
  const LightPatternsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<Map<String, String>> patterns = [
      {
        'name': 'Unauthorized',
        'file': 'light-patterns-unauth.gif',
        'description': 'User is not authorized to recieve tokens, and no default tokens are set.'
      },
      {
        'name': 'Ready',
        'file': 'light-patterns-ready.gif',
        'description': 'Device is ready and idle.'
      },
      {
        'name': 'Connecting to Wi‑Fi',
        'file': 'light-patterns-connect-to-wifi.gif',
        'description': 'Attempting to connect to the configured Wi‑Fi network.'
      },
      {
        'name': 'Wi‑Fi Config Mode',
        'file': 'light-patterns-wifi-config.gif',
        'description': 'Device is in Wi‑Fi configuration mode.'
      },
      {
        'name': 'Connecting to Server',
        'file': 'light-patterns-connect-to-server.gif',
        'description': 'Establishing connection to the backend server.'
      },
      {
        'name': 'Checking User',
        'file': 'light-patterns-check-user.gif',
        'description': 'Verifying user or ticket.'
      },
      {
        'name': 'Success',
        'file': 'light-patterns-success.gif',
        'description': 'Operation succeeded.'
      },
      {
        'name': 'Run Out',
        'file': 'light-patterns-runout.gif',
        'description': 'Out of tokens or resources.'
      },
      {
        'name': 'Error',
        'file': 'light-patterns-error.gif',
        'description': 'An error occurred, check the device or configuration.'
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Light Patterns'),
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
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: patterns.length,
          itemBuilder: (context, index) {
            final item = patterns[index];
            final name = item['name']!;
            final description = item['description']!;
            final file = item['file']!;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.08),
                          theme.colorScheme.surface,
                        ],
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 140,
                            height: 100,
                            child: Gif(
                              image: AssetImage('assets/gifs/$file'),
                              autostart: Autostart.loop,
                              placeholder: (context) => const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                description,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}