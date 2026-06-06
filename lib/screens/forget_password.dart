import 'package:flutter/material.dart';
import 'package:whatshoppy2/widgets/custom_scaffold.dart';
import 'package:whatshoppy2/services/auth_service.dart';
import 'package:whatshoppy2/services/api_client.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int currentStep = 0;
  bool isLoading = false;

  final emailController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String? _accessToken;
  String? _refreshToken;

  @override
  void dispose() {
    emailController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter your email"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final emailRegex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter a valid email"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await AuthService.resetPasswordForEmail(email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Reset link sent! Check your email."),
          backgroundColor: Colors.green,
        ),
      );

      setState(() => currentStep = 1);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', 'Failed to send reset email: '),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _onTokenReceived() {
    setState(() => currentStep = 2);
  }

  Future<void> _resetPassword() async {
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a new password"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password must be at least 6 characters"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Passwords do not match"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_accessToken == null || _accessToken!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "In production, the token comes from the email link (deep link). "
            "Paste tokens from the reset link if testing manually.",
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );

      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }

    setState(() => isLoading = true);

    try {
      // If we have tokens from a deep link, use the full backend reset flow.
      if (_accessToken != null && _accessToken!.isNotEmpty) {
        await AuthService.resetPasswordWithToken(
          accessToken: _accessToken!,
          refreshToken: _refreshToken ?? '',
          newPassword: newPassword,
        );
      } else {
        // No tokens available — this happens when the user clicks "I Clicked the Link"
        // without actually coming from a deep link (e.g. testing manually).
        // The backend reset-password route requires a valid token, so we inform the user.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Open the reset link from your email on this device to complete the reset.",
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
          Navigator.pop(context);
        }
        return;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password updated successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', 'Failed to reset password: '),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(24),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildStep(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    if (currentStep == 0) return _emailStep();
    if (currentStep == 1) return _codeStep();
    return _resetStep();
  }

  Widget _emailStep() {
    return Column(
      key: const ValueKey(1),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.lock_reset, size: 42, color: Colors.green),
        const SizedBox(height: 18),
        const Text(
          "Forgot Your Password",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          "Enter your email and we'll send you a reset link",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 25),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: "Enter Your Email",
            prefixIcon: const Icon(Icons.email_outlined),
            filled: true,
            fillColor: const Color(0xFFF4F4F4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isLoading ? null : _sendResetEmail,
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text("Send Reset Link"),
          ),
        ),
        const SizedBox(height: 14),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Back to sign in"),
        ),
      ],
    );
  }

  Widget _codeStep() {
    return Column(
      key: const ValueKey(2),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.mark_email_read_outlined, size: 42, color: Colors.green),
        const SizedBox(height: 18),
        const Text(
          "Check Your Email",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          "We sent a reset link to\n${emailController.text.trim()}",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 25),
        const Text(
          "Click the link in your email, then come back here to set your new password.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.black45),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _onTokenReceived,
            child: const Text("I Clicked the Link"),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _sendResetEmail,
          child: const Text(
            "Didn't get email? Resend",
            style: TextStyle(color: Colors.green),
          ),
        ),
      ],
    );
  }

  Widget _resetStep() {
    return Column(
      key: const ValueKey(3),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.lock_open, size: 42, color: Colors.green),
        const SizedBox(height: 18),
        const Text(
          "Set New Password",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 25),
        TextField(
          controller: newPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: "New password (min 6 characters)",
            prefixIcon: const Icon(Icons.lock_outline),
            filled: true,
            fillColor: const Color(0xFFF4F4F4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: confirmPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: "Confirm new password",
            prefixIcon: const Icon(Icons.lock_outline),
            filled: true,
            fillColor: const Color(0xFFF4F4F4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isLoading ? null : _resetPassword,
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text("Reset Password"),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
      ],
    );
  }
}
