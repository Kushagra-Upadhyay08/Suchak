import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  final String role;
  const RegisterScreen({super.key, required this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _employeeIdController = TextEditingController(); // For engineers & admins
  bool _isLoading = false;

  void _register() async {
    if ((widget.role == 'engineer' || widget.role == 'admin') && _employeeIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter your Employee ID")));
      return;
    }

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final success = await auth.register(
        _nameController.text,
        _passwordController.text,
        widget.role,
        employeeId: (widget.role == 'engineer' || widget.role == 'admin') ? _employeeIdController.text : null,
      );
      if (success) {
        Navigator.pop(context); // Go back to Login
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Registration Successful! Please Login.")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Register as ${widget.role.toUpperCase()}")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Full Name")),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
            if (widget.role == 'engineer' || widget.role == 'admin')
               TextField(controller: _employeeIdController, decoration: InputDecoration(labelText: widget.role == 'engineer' ? "Employee ID (Engineer ID)" : "Employee ID (Admin ID)")),
            const SizedBox(height: 20),
            _isLoading 
              ? const CircularProgressIndicator()
              : ElevatedButton(onPressed: _register, child: const Text("Register")),
          ],
        ),
      ),
    );
  }
}
