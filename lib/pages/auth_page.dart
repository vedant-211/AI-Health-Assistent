import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_styles.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final AuthService _auth = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  void _handleAuth() async {
    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Please fill all fields"),
        backgroundColor: Color(0xFFDC2626),
      ));
      setState(() => _isLoading = false);
      return;
    }

    final result = _isLogin 
      ? await _auth.signIn(email, password)
      : await _auth.signUp(email, password);

    if (mounted) {
      if (result.error != null) {
        // Display precise error from AuthService
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(result.error!, style: const TextStyle(fontWeight: FontWeight.w600))),
            ],
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ));
      } else {
        // Success - redirect to home
        Navigator.of(context).pushReplacementNamed('/home');
      }
      setState(() => _isLoading = false);
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.bgDark,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("SwasthMitra", style: TextStyle(color: AppStyles.primaryBlue, fontWeight: FontWeight.w900, fontSize: 32, letterSpacing: -1)),
            const SizedBox(height: 8),
            Text(_isLogin ? "Welcome back to your companion." : "Start your lifelong health journey.", style: const TextStyle(color: AppStyles.textSecondary, fontSize: 16)),
            const SizedBox(height: 60),
            _buildTextField(_emailController, "Email Address", Icons.email_outlined),
            const SizedBox(height: 20),
            _buildTextField(_passwordController, "Password", Icons.lock_outline, isPassword: true),
            const SizedBox(height: 48),
            _buildAuthButton(),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(_isLogin ? "Don't have an account? Sign Up" : "Already have an account? Login", style: const TextStyle(color: AppStyles.primaryBlue, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isPassword = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(color: AppStyles.bgSurface, borderRadius: BorderRadius.circular(24), border: AppStyles.glassBorder),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: AppStyles.textMain),
        decoration: InputDecoration(icon: Icon(icon, color: AppStyles.textSecondary, size: 20), hintText: hint, hintStyle: const TextStyle(color: AppStyles.textSecondary, fontSize: 14), border: InputBorder.none),
      ),
    );
  }

  Widget _buildAuthButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleAuth,
      child: Container(
        width: double.infinity, height: 64,
        decoration: BoxDecoration(color: AppStyles.primaryBlue, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: AppStyles.primaryBlue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))]),
        alignment: Alignment.center,
        child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(_isLogin ? "Login" : "Sign Up", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
      ),
    );
  }
}
