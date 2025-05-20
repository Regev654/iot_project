import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/participant.dart';

class EventStatsScreen extends StatelessWidget {
  final Event event;

  EventStatsScreen({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Calculate statistics
    final totalParticipants = event.participants.length;
    final totalUsedTokens = event.participants.fold(0, (sum, p) => sum + p.usedTokens);
    final participantsWithTokens = event.participants.where((p) => p.maxTokens - p.usedTokens > 0).length;
    final averageTokensPerUser = totalParticipants > 0 ? totalUsedTokens / totalParticipants : 0;
    final maxTokensUsed = event.participants.fold(0, (max, p) => p.usedTokens > max ? p.usedTokens : max);
    
    // Find participants with most tokens used
    final topParticipants = List<Participant>.from(event.participants)
      ..sort((a, b) => b.usedTokens.compareTo(a.usedTokens));
    final top3Participants = topParticipants.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Event Statistics'),
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.eventTitle,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Text to Print: ${event.textToPrint}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overview',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildStatRow('Total Participants', totalParticipants.toString()),
                      _buildStatRow('Total Tokens Used', totalUsedTokens.toString()),
                      _buildStatRow('Participants with Unused Tokens', participantsWithTokens.toString()),
                      _buildStatRow('Average Used Tokens per User', averageTokensPerUser.toStringAsFixed(1)),
                      _buildStatRow('Maximum Tokens Used', maxTokensUsed.toString()),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Top Participants',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      ...top3Participants.map((p) => Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              p.id,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${p.usedTokens} tokens',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} 