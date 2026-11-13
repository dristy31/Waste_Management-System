import 'package:flutter/material.dart';

import '../services/supabase_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.client.auth.currentUser;
    final metadata = user?.userMetadata ?? {};

    final name = metadata['full_name'] ?? metadata['name'] ?? 'EcoTrack User';

    final email = user?.email ?? 'No email available';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F4),
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: user == null
          ? const Center(child: Text('Please login to view your profile.'))
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 48,
                      backgroundColor: Color(0xFFDDF2DF),
                      child: Icon(Icons.person, size: 55, color: Colors.green),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      name.toString(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'EcoTrack User',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 30),

                    Card(
                      color: Colors.white,
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(
                              Icons.person_outline,
                              color: Colors.green,
                            ),
                            title: const Text('Name'),
                            subtitle: Text(name.toString()),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(
                              Icons.email_outlined,
                              color: Colors.green,
                            ),
                            title: const Text('Email'),
                            subtitle: Text(email),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(
                              Icons.verified_user_outlined,
                              color: Colors.green,
                            ),
                            title: const Text('Account'),
                            subtitle: const Text('Registered User'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Together for a Cleaner Environment 🌿',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
