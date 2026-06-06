import 'package:flutter/material.dart';
import 'package:whatshoppy2/theme/app_theme.dart';
import 'package:whatshoppy2/screens/signin_screen.dart';

/// Landing screen shown to unauthenticated users.
///
/// This screen has NO session-resume logic — that is handled exclusively
/// by [AuthGate] at startup. WelcomeScreen is a pure marketing/entry page.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToSignIn() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const SignInScreen(),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.white,
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryGreen.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: size.height * 0.25,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.processingColor.withValues(alpha: 0.05),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideUp,
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLogo(),
                            const SizedBox(height: 36),
                            Text(
                              'WhatShoppy',
                              style: Theme.of(context)
                                  .textTheme
                                  .displayLarge
                                  ?.copyWith(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1.5,
                                    color: AppTheme.textDark,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Your AI-powered commerce dashboard.\nManage clients, orders & products.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: AppTheme.greyText,
                                    height: 1.6,
                                  ),
                            ),
                            const SizedBox(height: 48),
                            _buildFeaturePills(),
                          ],
                        ),
                      ),
                    ),
                    _buildCTAArea(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryGreen, AppTheme.darkGreen],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.greenShadow,
      ),
      child: const Icon(
        Icons.storefront_rounded,
        size: 44,
        color: AppTheme.white,
      ),
    );
  }

  Widget _buildFeaturePills() {
    final features = [
      (Icons.people_rounded, 'Clients', AppTheme.processingColor),
      (Icons.receipt_long_rounded, 'Orders', AppTheme.pendingColor),
      (Icons.inventory_2_rounded, 'Products', AppTheme.primaryGreen),
      (Icons.auto_awesome_rounded, 'AI', const Color(0xFF6366F1)),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: features.map((f) {
        final icon = f.$1;
        final label = f.$2;
        final color = f.$3;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCTAArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
      decoration: BoxDecoration(
        color: AppTheme.white,
        border: Border(
          top: BorderSide(color: AppTheme.borderGrey.withValues(alpha: 0.6)),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _goToSignIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: AppTheme.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Get Started',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: _goToSignIn,
            child: RichText(
              text: TextSpan(
                text: 'Already have an account? ',
                style: Theme.of(context).textTheme.bodyMedium,
                children: const [
                  TextSpan(
                    text: 'Sign In',
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Powered by BraindCode',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: AppTheme.greyText.withValues(alpha: 0.6),
                ),
          ),
        ],
      ),
    );
  }
}
