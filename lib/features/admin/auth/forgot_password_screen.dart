import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rs2_desktop/core/theme/app_colors.dart';
import 'package:rs2_desktop/core/utils/validators.dart';
import 'package:rs2_desktop/providers/auth_provider.dart';
import 'package:rs2_desktop/routes/app_router.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _showPasswordHelp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _showPasswordHelp = true);
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.resetPassword(
      email: _emailController.text.trim(),
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Password changed. Please sign in.'),
          ]),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.pushReplacementNamed(context, AppRouter.login);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(authProvider.error ?? 'Password reset failed')),
          ]),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Password must contain at least one uppercase letter';
    if (!RegExp(r'[a-z]').hasMatch(v)) return 'Password must contain at least one lowercase letter';
    if (!RegExp(r'\d').hasMatch(v)) return 'Password must contain at least one number';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.background,
              AppColors.surface,
              AppColors.primaryDark.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: _showPasswordHelp
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.lock_reset, size: 40, color: AppColors.primary),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Reset Password',
                          style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter your email and a new password.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        _buildField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'Enter your email',
                          icon: Icons.email_outlined,
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: _newPasswordController,
                          label: 'New Password',
                          hint: 'Enter new password',
                          icon: Icons.lock_outline,
                          obscure: _obscureNew,
                          onToggleObscure: () => setState(() => _obscureNew = !_obscureNew),
                          onChanged: (_) {
                            if (_showPasswordHelp) setState(() {});
                          },
                          validator: _validatePassword,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _PasswordRequirements(
                            password: _newPasswordController.text,
                            visible: _showPasswordHelp || _newPasswordController.text.isNotEmpty,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: _confirmController,
                          label: 'Confirm Password',
                          hint: 'Confirm new password',
                          icon: Icons.lock_outline,
                          obscure: _obscureConfirm,
                          onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          validator: (v) =>
                              v != _newPasswordController.text ? 'Passwords do not match' : null,
                        ),
                        const SizedBox(height: 24),
                        Consumer<AuthProvider>(
                          builder: (context, auth, _) => SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: auth.isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: auth.isLoading
                                  ? const SizedBox(
                                      height: 24, width: 24,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2.5),
                                    )
                                  : const Text('Reset Password',
                                      style: TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushReplacementNamed(context, AppRouter.login),
                          child: const Text('Back to Sign In',
                              style: TextStyle(color: AppColors.primary)),
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          onChanged: onChanged,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5)),
            prefixIcon: Icon(icon, color: AppColors.primary),
            suffixIcon: onToggleObscure != null
                ? IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: onToggleObscure,
                  )
                : null,
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.error)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}

class _PasswordRequirements extends StatelessWidget {
  final String password;
  final bool visible;

  const _PasswordRequirements({required this.password, required this.visible});

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    final items = [
      ('At least 8 characters', password.length >= 8),
      ('At least one uppercase letter', RegExp(r'[A-Z]').hasMatch(password)),
      ('At least one lowercase letter', RegExp(r'[a-z]').hasMatch(password)),
      ('At least one number', RegExp(r'\d').hasMatch(password)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        final ok = item.$2;
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(
                ok ? Icons.check_circle : Icons.cancel,
                size: 14,
                color: ok ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.$1,
                  style: TextStyle(
                    color: ok ? AppColors.success : AppColors.error.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
