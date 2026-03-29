import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';
import '../utils/ui_feedback.dart';
import '../widgets/app_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool loading = false;

  Future<void> signIn() async {
    setState(() => loading = true);
    try {
      final identifier = emailController.text.trim();
      final password = passwordController.text.trim();

      if (LocalStorageService.isAdminIdentifier(identifier)) {
        await AuthService.loginAdmin(email: identifier, password: password);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/admin');
        return;
      }

      await AuthService.loginUser(
        identifier: identifier,
        password: password,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      showErrorSnackBar(context, e);
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(elevation: 0, toolbarHeight: 140, centerTitle: true, title: Column(children: [
        const SizedBox(height: 12),
        const Icon(Icons.shield, size: 48, color: Colors.white),
        const SizedBox(height: 8),
        const Text('DriveSafe', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Safe Driving for Everyone', style: TextStyle(fontSize: 12, color: Colors.white70)),
      ])),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppSectionTitle(
                    title: 'Login',
                    subtitle: 'Sign in with your email and password to access DriveSafe.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person),
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.lock),
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  loading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(children: [
                          AppPrimaryButton(
                            label: 'Login',
                            icon: Icons.login,
                            onPressed: signIn,
                          ),
                          const SizedBox(height: 8),
                          AppSecondaryButton(
                            label: 'Register',
                            icon: Icons.person_add,
                            onPressed: () => Navigator.pushNamed(context, '/register'),
                          ),
                        ])
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 8,
            spacing: 12,
            children: [
              TextButton.icon(
                onPressed: () {
                  showAppSnackBar(context, 'You are already on the login screen.');
                },
                icon: const Icon(Icons.home),
                label: const Text('Home'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  showAppSnackBar(context, 'Please sign in first to report an incident.');
                },
                icon: const Icon(Icons.report),
                label: const Text('Report Incident'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF6B400)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
