
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class CollectionHistoryScreen extends StatefulWidget {
  const CollectionHistoryScreen({super.key});

  @override
  State<CollectionHistoryScreen> createState() =>
      _CollectionHistoryScreenState();
}

class _CollectionHistoryScreenState
    extends State<CollectionHistoryScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> reports = [];

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      final user = SupabaseService.client.auth.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() => isLoading = false);
        }
        return;
      }

      final data = await SupabaseService.client
          .from('waste_reports')
          .select('description, status, created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        reports = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load history: $e')),
      );
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.thumb_up;
      case 'completed':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
        return Icons.pending_actions;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F4),
      appBar: AppBar(
        title: const Text(
          'Collection History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.green),
            )
          : RefreshIndicator(
              onRefresh: loadHistory,
              child: reports.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Icon(Icons.history,
                            size: 65, color: Colors.grey),
                        SizedBox(height: 15),
                        Center(
                          child: Text(
                            'No reports available yet.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.history,
                                size: 40,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 15),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total Reports',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    reports.length.toString(),
                                    style: const TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25),
                        const Text(
                          'All Collection Records',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),

                        ...reports.map((report) {
                          final description =
                              report['description']?.toString() ??
                                  'Waste Report';

                          final status =
                              report['status']?.toString() ??
                                  'Unknown';

                          final date =
                              report['created_at'] == null
                                  ? 'Date unavailable'
                                  : report['created_at']
                                      .toString()
                                      .split('T')
                                      .first;

                          final color = getStatusColor(status);

                          return Card(
                            color: Colors.white,
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding:
                                  const EdgeInsets.all(12),
                              leading: CircleAvatar(
                                backgroundColor: color.withAlpha(30),
                                child: Icon(
                                  getStatusIcon(status),
                                  color: color,
                                ),
                              ),
                              title: Text(
                                description,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Padding(
                                padding:
                                    const EdgeInsets.only(top: 8),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('Date: $date'),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.withAlpha(30),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: Icon(
                                getStatusIcon(status),
                                color: color,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
            ),
    );
  }
}
