import 'package:flutter/material.dart';

import '../services/supabase_service.dart';
import 'login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<Map<String, dynamic>> reports = [];

  bool isLoading = true;
  bool isUpdating = false;

  String selectedFilter = 'All';

  final List<String> statuses = [
    'Pending',
    'Approved',
    'Completed',
    'Rejected',
  ];

  final List<String> filters = [
    'All',
    'Pending',
    'Approved',
    'Completed',
    'Rejected',
  ];

  bool get isAdmin {
    return SupabaseService.client.auth.currentUser?.appMetadata['role'] ==
        'admin';
  }

  @override
  void initState() {
    super.initState();

    if (isAdmin) {
      loadReports();
    } else {
      isLoading = false;
    }
  }

  Future<void> loadReports() async {
    try {
      final result = await SupabaseService.client
          .from('waste_reports')
          .select()
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        reports = List<Map<String, dynamic>>.from(result);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);
      showMessage('Failed to load reports: $e');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String getStatus(Map<String, dynamic> report) {
    return (report['status'] ?? 'Pending').toString();
  }

  List<Map<String, dynamic>> get filteredReports {
    if (selectedFilter == 'All') {
      return reports;
    }

    return reports.where((report) {
      return getStatus(report).toLowerCase() == selectedFilter.toLowerCase();
    }).toList();
  }

  int countStatus(String status) {
    return reports.where((report) {
      return getStatus(report).toLowerCase() == status.toLowerCase();
    }).length;
  }

  Future<void> updateStatus(
    Map<String, dynamic> report,
    String newStatus,
  ) async {
    if (!isAdmin || isUpdating) return;

    setState(() => isUpdating = true);

    try {
      await SupabaseService.client
          .from('waste_reports')
          .update({'status': newStatus})
          .eq('id', report['id']);

      await loadReports();

      if (!mounted) return;

      showMessage('Report status updated successfully!');
    } catch (e) {
      showMessage('Update failed: $e');
    } finally {
      if (mounted) {
        setState(() => isUpdating = false);
      }
    }
  }

  Future<void> showStatusDialog(Map<String, dynamic> report) async {
    String selectedStatus = getStatus(report);

    final options = [...statuses];

    if (!options.contains(selectedStatus)) {
      options.add(selectedStatus);
    }

    final newStatus = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Update Report Status'),
              content: DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Select Status',
                  border: OutlineInputBorder(),
                ),
                items: options.map((status) {
                  return DropdownMenuItem(value: status, child: Text(status));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() {
                      selectedStatus = value;
                    });
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, selectedStatus),
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );

    if (newStatus != null && newStatus != getStatus(report)) {
      await updateStatus(report, newStatus);
    }
  }

  Future<void> logout() async {
    try {
      await SupabaseService.client.auth.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      showMessage('Logout failed: $e');
    }
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget statisticCard(String title, int count, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 27),
              const SizedBox(height: 8),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget reportCard(Map<String, dynamic> report) {
    final title = report['title'] ?? report['waste_type'] ?? 'Waste Report';

    final status = getStatus(report);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toString(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const Divider(height: 22),

            _detail('User', report['user_email']),
            _detail('Waste Type', report['waste_type']),
            _detail('Quantity', report['quantity']),
            _detail('Location', report['location']),
            _detail('Description', report['description']),

            const SizedBox(height: 12),

            Row(
              children: [
                const Text(
                  'Status: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Chip(
                  label: Text(
                    status,
                    style: TextStyle(
                      color: statusColor(status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: statusColor(status).withValues(alpha: 0.12),
                  side: BorderSide.none,
                ),
              ],
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isUpdating ? null : () => showStatusDialog(report),
                icon: const Icon(Icons.edit),
                label: const Text('Update Status'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text.rich(
        TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value.toString()),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(child: Text('Admin permission required.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F2),

      appBar: AppBar(
        title: const Text(
          'EcoTrack Admin',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: isLoading ? null : loadReports,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(onPressed: logout, icon: const Icon(Icons.logout)),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : RefreshIndicator(
              onRefresh: loadReports,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.green.shade800,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.admin_panel_settings,
                          size: 40,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Welcome, Admin!',
                          style: TextStyle(
                            fontSize: 23,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Manage all waste reports from here.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Reports Overview',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      statisticCard(
                        'Total',
                        reports.length,
                        Icons.description,
                        Colors.blue,
                      ),
                      statisticCard(
                        'Pending',
                        countStatus('Pending'),
                        Icons.access_time,
                        Colors.orange,
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      statisticCard(
                        'Approved',
                        countStatus('Approved'),
                        Icons.thumb_up,
                        Colors.blue,
                      ),
                      statisticCard(
                        'Completed',
                        countStatus('Completed'),
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      statisticCard(
                        'Rejected',
                        countStatus('Rejected'),
                        Icons.cancel,
                        Colors.red,
                      ),
                      const Spacer(),
                    ],
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Filter Reports',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: filters.map((filter) {
                        final selected = selectedFilter == filter;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(filter),
                            selected: selected,
                            selectedColor: Colors.green.shade200,
                            onSelected: (_) {
                              setState(() {
                                selectedFilter = filter;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    '$selectedFilter Reports (${filteredReports.length})',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (filteredReports.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(30),
                      child: Center(
                        child: Text(
                          'No reports found in this category.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    )
                  else
                    ...filteredReports.map(reportCard),
                ],
              ),
            ),
    );
  }
}
