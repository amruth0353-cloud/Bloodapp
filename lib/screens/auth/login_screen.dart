import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../donor/donor_home.dart';
import '../admin/admin_home.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool isAdmin;
  const LoginScreen({super.key, this.isAdmin = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AppProvider>();
    final success = widget.isAdmin
        ? await provider.loginAdmin(_emailCtrl.text.trim(), _passCtrl.text)
        : await provider.loginDonor(_emailCtrl.text.trim(), _passCtrl.text);
    if (success && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => widget.isAdmin ? const AdminHome() : const DonorHome(),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Scaffold(
      body: LoadingOverlay(
        isLoading: provider.isLoading,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.deepRed, AppTheme.primaryRed, Color(0xFFE53E3E)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                const SizedBox(height: 40),
                Column(children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                    child: const Icon(Icons.water_drop, color: Colors.white, size: 64),
                  ),
                  const SizedBox(height: 16),
                  Text('BloodConnect', style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Every drop counts. Every life matters.', style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.85), fontSize: 14)),
                ]).animate().fadeIn(duration: 600.ms).scale(),
                const SizedBox(height: 40),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Form(
                      key: _formKey,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(widget.isAdmin ? 'Admin Login' : 'Donor Login',
                            style: Theme.of(context).textTheme.displayMedium),
                        const SizedBox(height: 4),
                        Text(widget.isAdmin ? 'Blood bank administrator portal' : 'Sign in to save lives',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600)),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
                          validator: (v) => v!.contains('@') ? null : 'Enter a valid email',
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) => v!.length >= 6 ? null : 'Min 6 characters',
                        ),
                        if (provider.error != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                            child: Row(children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(provider.error!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                            ]),
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _login, child: const Text('Sign In'))),
                        if (!widget.isAdmin) ...[
                          const SizedBox(height: 16),
                          Center(child: TextButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                            child: Text.rich(TextSpan(children: [
                              const TextSpan(text: 'New donor? '),
                              TextSpan(text: 'Register here', style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.w600)),
                            ])),
                          )),
                        ],
                      ]),
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.15),
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen(isAdmin: !widget.isAdmin))),
                  icon: Icon(widget.isAdmin ? Icons.favorite_outline : Icons.admin_panel_settings_outlined, color: Colors.white70),
                  label: Text(widget.isAdmin ? 'Login as Donor' : 'Admin Portal', style: const TextStyle(color: Colors.white70)),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
