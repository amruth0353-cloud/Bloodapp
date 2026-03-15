import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../donor/donor_home.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String _bloodType = 'O+';
  String _gender = 'Male';
  int _age = 25;
  bool _obscure = true;
  int _step = 0;

  static const bloodTypes = ['A+','A-','B+','B-','AB+','AB-','O+','O-'];

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    _passCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    final provider = context.read<AppProvider>();
    final success = await provider.registerDonor(
      email: _emailCtrl.text.trim(), password: _passCtrl.text,
      name: _nameCtrl.text.trim(), phone: _phoneCtrl.text.trim(),
      bloodType: _bloodType, age: _age, gender: _gender,
    );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Welcome! Thank you for joining BloodConnect!')));
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const DonorHome()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Scaffold(
      appBar: BloodConnectAppBar(title: 'Become a Donor'),
      body: LoadingOverlay(
        isLoading: provider.isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _StepIndicator(currentStep: _step),
              const SizedBox(height: 24),
              if (_step == 0) _buildPersonalInfo(),
              if (_step == 1) _buildMedicalInfo(),
              if (_step == 2) _buildAccountInfo(),
              if (provider.error != null)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                  child: Text(provider.error!, style: const TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 24),
              Row(children: [
                if (_step > 0) ...[
                  Expanded(child: OutlinedButton(onPressed: () => setState(() => _step--), child: const Text('Back'))),
                  const SizedBox(width: 12),
                ],
                Expanded(child: ElevatedButton(
                  onPressed: _step < 2 ? () => setState(() => _step++) : _register,
                  child: Text(_step < 2 ? 'Continue' : 'Create Account'),
                )),
              ]),
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Personal Information', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 16),
      TextFormField(
        controller: _nameCtrl,
        decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
        validator: (v) => v!.isNotEmpty ? null : 'Required',
        textCapitalization: TextCapitalization.words,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _phoneCtrl,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
        validator: (v) => v!.length >= 8 ? null : 'Enter valid phone number',
      ),
      const SizedBox(height: 16),
      Text('Age: $_age years', style: Theme.of(context).textTheme.bodyMedium),
      Slider(value: _age.toDouble(), min: 17, max: 65, divisions: 48, activeColor: AppTheme.primaryRed, label: '$_age', onChanged: (v) => setState(() => _age = v.toInt())),
      const SizedBox(height: 8),
      Text('Gender', style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: ['Male','Female','Other'].map((g) {
        final selected = _gender == g;
        return ChoiceChip(
          label: Text(g), selected: selected,
          onSelected: (_) => setState(() => _gender = g),
          selectedColor: AppTheme.primaryRed,
          labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87, fontWeight: FontWeight.w500),
        );
      }).toList()),
    ]).animate().fadeIn().slideX(begin: 0.1);
  }

  Widget _buildMedicalInfo() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Medical Information', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 16),
      const Text('Your blood type is crucial for matching donors with recipients.', style: TextStyle(color: Colors.grey)),
      const SizedBox(height: 16),
      Text('Blood Type', style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 8),
      GridView.count(
        crossAxisCount: 4, shrinkWrap: true, crossAxisSpacing: 8, mainAxisSpacing: 8,
        childAspectRatio: 1.4, physics: const NeverScrollableScrollPhysics(),
        children: bloodTypes.map((bt) {
          final selected = _bloodType == bt;
          return InkWell(
            onTap: () => setState(() => _bloodType = bt),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: selected ? AppTheme.primaryRed : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected ? AppTheme.primaryRed : Colors.grey.shade300),
              ),
              child: Center(child: Text(bt, style: TextStyle(color: selected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16))),
            ),
          );
        }).toList(),
      ),
    ]).animate().fadeIn().slideX(begin: 0.1);
  }

  Widget _buildAccountInfo() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Account Details', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 16),
      TextFormField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
        validator: (v) => v!.contains('@') ? null : 'Enter valid email',
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
      const SizedBox(height: 16),
      TextFormField(
        controller: _confirmCtrl,
        obscureText: _obscure,
        decoration: const InputDecoration(labelText: 'Confirm Password', prefixIcon: Icon(Icons.lock_outline)),
        validator: (v) => v == _passCtrl.text ? null : 'Passwords do not match',
      ),
    ]).animate().fadeIn().slideX(begin: 0.1);
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final steps = ['Personal', 'Medical', 'Account'];
    return Row(children: steps.asMap().entries.map((e) {
      final i = e.key; final label = e.value;
      final active = i == currentStep; final done = i < currentStep;
      return Expanded(child: Row(children: [
        if (i > 0) Expanded(child: Container(height: 2, color: done ? AppTheme.primaryRed : Colors.grey.shade200)),
        Column(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 32, height: 32,
            decoration: BoxDecoration(shape: BoxShape.circle, color: active || done ? AppTheme.primaryRed : Colors.grey.shade200),
            child: Center(child: done
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text('${i + 1}', style: TextStyle(color: active ? Colors.white : Colors.grey.shade500, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: active ? AppTheme.primaryRed : Colors.grey, fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
        ]),
      ]));
    }).toList());
  }
}
