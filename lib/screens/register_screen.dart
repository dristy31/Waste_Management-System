import 'package:flutter/material.dart';

import '../services/supabase_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool isPasswordVisible = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Registration with Supabase
  Future<void> register() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await SupabaseService.client.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text,
        data: {
          'full_name': nameController.text.trim(),
          'phone': phoneController.text.trim(),
        },
      );

      if (!mounted) return;

      final message = response.session != null
          ? 'Account created successfully! You can now login.'
          : 'Account created! Please verify your email before login.';

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Registration Successful'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK', style: TextStyle(color: Colors.green)),
            ),
          ],
        ),
      );

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F4),

      appBar: AppBar(
        title: const Text(
          'Create Account',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),

            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),

              child: Card(
                color: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),

                child: Padding(
                  padding: const EdgeInsets.all(22),

                  child: Form(
                    key: formKey,

                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.eco, size: 55, color: Colors.green),

                        const SizedBox(height: 8),

                        const Text(
                          'Join EcoTrack',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),

                        const SizedBox(height: 5),

                        const Text(
                          'Create your account',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),

                        const SizedBox(height: 25),

                        // Full Name
                        TextFormField(
                          controller: nameController,

                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: const Icon(
                              Icons.person_outline,
                              size: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            isDense: true,
                          ),

                          validator: (value) {
                            if (value == null ||
                                !RegExp(r'^[a-zA-Z ]{3,}$')
                                    .hasMatch(value.trim())) {
                              return 'Enter a valid name';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 15),

                        // Email
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,

                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              size: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            isDense: true,
                          ),

                          validator: (value) {
                            if (value == null ||
                                !RegExp(r'^[\w.-]+@[\w.-]+\.\w+$')
                                    .hasMatch(value.trim())) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 15),

                        // Phone Number
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,

                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: const Icon(
                              Icons.phone_outlined,
                              size: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            isDense: true,
                          ),

                          validator: (value) {
                            if (value == null ||
                                !RegExp(r'^(?:\+8801|01)[3-9]\d{8}$')
                                    .hasMatch(value.trim())) {
                              return 'Enter a valid phone number';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 15),

                        // Password
                        TextFormField(
                          controller: passwordController,
                          obscureText: !isPasswordVisible,

                          decoration: InputDecoration(
                            labelText: 'Password',

                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              size: 20,
                            ),

                            suffixIcon: IconButton(
                              icon: Icon(
                                isPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  isPasswordVisible = !isPasswordVisible;
                                });
                              },
                            ),

                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),

                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),

                            isDense: true,
                          ),

                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 25),

                        // Register Button
                        SizedBox(
                          width: double.infinity,
                          height: 45,

                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),

                            onPressed: isLoading ? null : register,

                            child: isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Create Account',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  Navigator.pop(context);
                                },

                          child: const Text(
                            'Already have an account? Login',
                            style: TextStyle(color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
