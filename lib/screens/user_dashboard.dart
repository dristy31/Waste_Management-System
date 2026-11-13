import 'package:flutter/material.dart';

import '../services/supabase_service.dart';
import 'login_screen.dart';
import 'submit_report_screen.dart';
import 'my_reports_screen.dart';
import 'collection_history_screen.dart';
import 'profile_screen.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  bool isLoading = false;
  bool reportsLoading = true;

  int totalReports = 0;
  int pendingReports = 0;
  int approvedReports = 0;
  int rejectedReports = 0;
  int completedReports = 0;

  @override
  void initState() {
    super.initState();
    loadReports();
  }

  Future<void> loadReports() async {
    try {
      final user = SupabaseService.client.auth.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() => reportsLoading = false);
        }
        return;
      }

      final data = await SupabaseService.client
          .from('waste_reports')
          .select('status')
          .eq('user_id', user.id);

      if (!mounted) return;

      int countStatus(String status) {
        return data.where((report) {
          return (report['status'] ?? 'pending')
                  .toString()
                  .trim()
                  .toLowerCase() ==
              status.toLowerCase();
        }).length;
      }

      setState(() {
        totalReports = data.length;
        pendingReports = countStatus('Pending');
        approvedReports = countStatus('Approved');
        rejectedReports = countStatus('Rejected');
        completedReports = countStatus('Completed');
        reportsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => reportsLoading = false);
      showMessage('Could not load reports: $e');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> openMyReports() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MyReportsScreen()),
    );
    if (mounted) loadReports();
  }

  Future<void> openSubmitReport() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SubmitReportScreen()),
    );
    if (mounted) loadReports();
  }

  Future<void> openCollectionHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CollectionHistoryScreen()),
    );
  }

  Future<void> openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  Future<void> logout() async {
    setState(() => isLoading = true);

    try {
      await SupabaseService.client.auth.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      showMessage('Logout failed: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F4),
      appBar: AppBar(
        title: const Text(
          'EcoTrack',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: isLoading ? null : logout,
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadReports,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome to EcoTrack!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Keep your environment clean and green.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 25),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.eco, size: 38, color: Colors.green),
                    SizedBox(height: 10),
                    Text(
                      'Make Your City Cleaner!',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text('Report waste and help protect nature.'),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'Your Overview',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              if (reportsLoading)
                const Center(
                  child: CircularProgressIndicator(color: Colors.green),
                )
              else
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: overviewCard(
                            'Total Reports',
                            totalReports.toString(),
                            Icons.description_outlined,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: overviewCard(
                            'Pending',
                            pendingReports.toString(),
                            Icons.access_time,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: overviewCard(
                            'Approved',
                            approvedReports.toString(),
                            Icons.check_circle_outline,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: overviewCard(
                            'Rejected',
                            rejectedReports.toString(),
                            Icons.cancel_outlined,
                            Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: overviewCard(
                            'Completed',
                            completedReports.toString(),
                            Icons.task_alt,
                            Colors.teal,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: overviewCard(
                            'My Activity',
                            totalReports.toString(),
                            Icons.recycling,
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

              const SizedBox(height: 25),

              const Text(
                'Dashboard Menu',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              dashboardCard(
                'Submit Waste Report',
                Icons.add_circle_outline,
                Colors.green,
                openSubmitReport,
              ),
              dashboardCard(
                'My Reports',
                Icons.assignment_outlined,
                Colors.blue,
                openMyReports,
              ),
              dashboardCard(
                'Collection History',
                Icons.history,
                Colors.orange,
                openCollectionHistory,
              ),
              dashboardCard(
                'My Profile',
                Icons.person_outline,
                Colors.purple,
                openProfile,
              ),

              const SizedBox(height: 15),
              const Center(
                child: Text(
                  'Together for a Cleaner Environment',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget overviewCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 27),
          const SizedBox(height: 12),
          Text(
            count,
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget dashboardCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color, size: 28),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 15),
      ),
    );
  }
}
