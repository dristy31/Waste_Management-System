import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubmitReportScreen extends StatefulWidget {
  const SubmitReportScreen({super.key});

  @override
  State<SubmitReportScreen> createState() => _SubmitReportScreenState();
}

class _SubmitReportScreenState extends State<SubmitReportScreen> {
  final _formKey = GlobalKey<FormState>();

  final quantityController = TextEditingController();
  final locationController = TextEditingController();
  final descriptionController = TextEditingController();

  String? selectedWasteType;
  bool isLoading = false;

  final wasteTypes = [
    'Plastic',
    'Paper',
    'Food Waste',
    'Glass',
    'Metal',
    'Other',
  ];

  Future<void> submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please login first')));
      return;
    }

    setState(() => isLoading = true);

    try {
      await Supabase.instance.client.from('waste_reports').insert({
        'user_id': user.id,
        'waste_type': selectedWasteType,
        'quantity': double.parse(quantityController.text.trim()),
        'location': locationController.text.trim(),
        'description': descriptionController.text.trim(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Waste report submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      quantityController.clear();
      locationController.clear();
      descriptionController.clear();

      setState(() => selectedWasteType = null);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    quantityController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Waste Report'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Report Waste Problem',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Help us keep the environment clean.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 25),

              const Text('Waste Type'),
              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                initialValue: selectedWasteType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select waste type',
                ),
                items: wasteTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() => selectedWasteType = value);
                },
                validator: (value) =>
                    value == null ? 'Please select waste type' : null,
              ),

              const SizedBox(height: 18),

              const Text('Quantity (kg)'),
              const SizedBox(height: 8),

              TextFormField(
                controller: quantityController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter quantity',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Quantity is required';
                  }
                  if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(value.trim())) {
                    return 'Enter a valid quantity';
                  }
                  if (double.parse(value.trim()) <= 0) {
                    return 'Quantity must be greater than zero';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 18),

              const Text('Location'),
              const SizedBox(height: 8),

              TextFormField(
                controller: locationController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter waste location',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Location is required';
                  }
                  if (!RegExp(r'^[a-zA-Z0-9\s,.-]{3,100}$')
                      .hasMatch(value.trim())) {
                    return 'Enter a valid location';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 18),

              const Text('Description'),
              const SizedBox(height: 8),

              TextFormField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Write details about waste...',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  if (value.trim().length < 5) {
                    return 'Write at least 5 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Submit Report',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

