import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/network/network_service.dart';
import '../auth/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/primary_button.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameOrEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameOrEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Authentication bypassed — any input logs in directly
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Small delay for UX (shows loading spinner briefly)
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      // Store the entered name in AuthProvider so it shows across the app
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.loginDemo(_usernameOrEmailController.text);
      // Navigation is handled automatically by Consumer<AuthProvider> in main.dart
    }
  }

  @override
  Widget build(BuildContext context) {
    final network = Provider.of<NetworkService>(context);

    return Scaffold(
      backgroundColor: AppTheme.bgSlate,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Network Connectivity Status Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: network.isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: network.isOnline ? const Color(0xFF86EFAC) : const Color(0xFFFCD34D),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: network.isOnline ? AppTheme.successGreen : AppTheme.warningAmber,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            network.isOnline ? 'Online • Server Connected' : 'Offline • Check Connection',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: network.isOnline ? AppTheme.successGreen : AppTheme.warningAmber,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),

                    // App Logo / Seal
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryTeal,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryTeal.withValues(alpha: 0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.assignment_turned_in,
                          size: 38,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    const Text(
                      'Onion AI',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.darkSlate,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Quality Assessment & Procurement System',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Error Message Banner
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.errorRed,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Input Form Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderGray),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Username / Email Field
                          const Text(
                            'Username / Email',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _usernameOrEmailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              hintText: 'Enter username or email',
                              prefixIcon: const Icon(Icons.person_outline, size: 20),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            validator: (v) => null, // No validation required
                          ),
                          const SizedBox(height: 16),

                          // Password Field
                          const Text(
                            'Password',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleLogin(),
                            decoration: InputDecoration(
                              hintText: 'Enter password',
                              prefixIcon: const Icon(Icons.lock_outline, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            validator: (v) => null, // No validation required
                          ),
                          const SizedBox(height: 24),

                          // Login Button
                          PrimaryButton(
                            label: 'LOGIN',
                            icon: Icons.login_rounded,
                            isLoading: _isLoading,
                            onPressed: _isLoading ? null : _handleLogin,
                            height: 50,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Demo notice footer
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFA5B4FC)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info_outline, size: 14, color: Color(0xFF6366F1)),
                            SizedBox(width: 6),
                            Text(
                              'Demo Mode — Enter anything to login',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
