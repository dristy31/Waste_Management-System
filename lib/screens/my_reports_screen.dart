import 'package:flutter/material.dart';

import '../services/supabase_service.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  List<Map<String, dynamic>> reports = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadReports();
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> loadReports() async {
    if (mounted) {
      setState(() => isLoading = true);
    }

    try {
      final user = SupabaseService.client.auth.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() => isLoading = false);
        }
        return;
      }

      final result = await SupabaseService.client
          .from('waste_reports')
          .select()
          .eq('user_id', user.id)
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

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // View Report Details
  void viewReport(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Waste Type: ${report['waste_type']}'),
            const SizedBox(height: 10),
            Text('Quantity: ${report['quantity']} kg'),
            const SizedBox(height: 10),
            Text('Location: ${report['location']}'),
            const SizedBox(height: 10),
            Text('Description: ${report['description']}'),
            const SizedBox(height: 10),
            Text('Status: ${report['status'] ?? 'Pending'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Edit Report
  Future<void> editReport(Map<String, dynamic> report) async {
    final typeController = TextEditingController(
      text: report['waste_type']?.toString() ?? '',
    );

    final quantityController = TextEditingController(
      text: report['quantity']?.toString() ?? '',
    );

    final locationController = TextEditingController(
      text: report['location']?.toString() ?? '',
    );

    final descriptionController = TextEditingController(
      text: report['description']?.toString() ?? '',
    );

    final formKey = GlobalKey<FormState>();

    try {
      final updated = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Edit Report'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: typeController,
                    decoration: const InputDecoration(
                      labelText: 'Waste Type',
                      prefixIcon: Icon(Icons.recycling),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter waste type'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: quantityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Quantity (kg)',
                      prefixIcon: Icon(Icons.scale),
                    ),
                    validator: (value) {
                      final quantity = double.tryParse(value?.trim() ?? '');
                      if (quantity == null || quantity <= 0) {
                        return 'Enter a valid quantity';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter location'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                    validator: (value) =>
                        value == null || value.trim().length < 5
                        ? 'Write at least 5 characters'
                        : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      );

      if (updated != true || !mounted) return;

      final user = SupabaseService.client.auth.currentUser;
      if (user == null) return;

      await SupabaseService.client
          .from('waste_reports')
          .update({
            'waste_type': typeController.text.trim(),
            'quantity': double.parse(quantityController.text.trim()),
            'location': locationController.text.trim(),
            'description': descriptionController.text.trim(),
          })
          .eq('id', report['id'])
          .eq('user_id', user.id);

      showMessage('Report updated successfully!');
      await loadReports();
    } catch (e) {
      showMessage('Update failed: $e');
    } finally {
      typeController.dispose();
      quantityController.dispose();
      locationController.dispose();
      descriptionController.dispose();
    }
  }

  // Delete Report
  Future<void> deleteReport(dynamic reportId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Report'),
        content: const Text('Are you sure you want to delete this report?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) return;

      await SupabaseService.client
          .from('waste_reports')
          .delete()
          .eq('id', reportId)
          .eq('user_id', user.id);

      showMessage('Report deleted successfully!');
      await loadReports();
    } catch (e) {
      showMessage('Delete failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F4),
      appBar: AppBar(
        title: const Text(
          'My Reports',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: loadReports,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : reports.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 65,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No Reports Found',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text('Submit your first waste report.'),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: loadReports,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index];
                  final status = report['status']?.toString() ?? 'Pending';

                  return Card(
                    color: Colors.white,
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 14),
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
                              const Icon(
                                Icons.recycling,
                                color: Colors.green,
                                size: 27,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  report['waste_type']?.toString() ?? 'Waste',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor(status).withAlpha(25),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: statusColor(status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text('Quantity: ${report['quantity']} kg'),
                          const SizedBox(height: 6),
                          Text('Location: ${report['location']}'),
                          const SizedBox(height: 6),
                          Text('Description: ${report['description']}'),
                          const SizedBox(height: 15),
                          const Divider(),
                          Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 5,
                            children: [
                              TextButton.icon(
                                onPressed: () => viewReport(report),
                                icon: const Icon(
                                  Icons.visibility_outlined,
                                  size: 18,
                                ),
                                label: const Text('View'),
                              ),
                              TextButton.icon(
                                onPressed: () => editReport(report),
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                label: const Text('Edit'),
                              ),
                              TextButton.icon(
                                onPressed: () => deleteReport(report['id']),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                label: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
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
    );
  }
}
