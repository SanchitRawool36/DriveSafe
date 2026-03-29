import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';
import '../utils/ui_feedback.dart';
import '../widgets/app_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool loading = false;

  Future<void> register() async {
    if (LocalStorageService.isAdminIdentifier(emailController.text)) {
      showAppSnackBar(context, 'Admin email is reserved. Use the admin login flow.', isError: true);
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      showAppSnackBar(context, 'Passwords do not match.', isError: true);
      return;
    }

    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      showAppSnackBar(context, 'Please complete all fields.', isError: true);
      return;
    }

    setState(() => loading = true);
    try {
      await AuthService.registerUser(
        name: nameController.text,
        email: emailController.text,
        phone: phoneController.text,
        password: passwordController.text,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (error) {
      showErrorSnackBar(context, error);
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text("Register")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  const AppSectionTitle(
                    title: 'Create Account',
                    subtitle: 'Create your Firebase account for complaint reporting and tracking.',
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Full Name",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Password",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Confirm Password",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (loading)
                    const CircularProgressIndicator()
                  else
                    const SizedBox.shrink(),

                  if (!loading)
                    AppPrimaryButton(
                      label: 'Register',
                      icon: Icons.person_add,
                      onPressed: register,
                    ),

                  const SizedBox(height: 10),

                  AppSecondaryButton(
                    label: 'Back To Login',
                    onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}