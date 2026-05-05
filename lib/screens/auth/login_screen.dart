import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../providers/preferences_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    final success = await AuthService.instance.signInWithGoogle();
    setState(() => _isLoading = false);

    if (success && mounted) {
      final user = AuthService.instance.user;
      if (user != null) {
        ref.read(preferencesProvider.notifier).updateProfile(
          displayName: user['full_name'] ?? user['email']?.split('@')[0],
          email: user['email'],
        );
      }
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Sign-In failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep Slate
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Logo & Title
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome, size: 64, color: Colors.blueAccent),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppConstants.appName,
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppConstants.appTagline,
                      style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              
              // Google Sign In Button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleGoogleSignIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  ),
                  elevation: 0,
                ),
                icon: _isLoading 
                  ? const SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54)
                    )
                  : Image.network(
                      'https://www.gstatic.com/images/branding/product/1x/gsa_512dp.png',
                      height: 24,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_circle, size: 24, color: Colors.blueAccent),
                    ),
                label: const Text(
                  'Continue with Google',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Email Login Placeholder (for future expansion)
              OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email login coming soon! Use Google for now.')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  ),
                ),
                child: const Text('Continue with Email'),
              ),
              
              const SizedBox(height: 48),
              
              Center(
                child: Text(
                  'By continuing, you agree to our Terms of Service',
                  style: theme.textTheme.labelSmall?.copyWith(color: Colors.white38),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

extension on TextTheme {
  get slateGrey => const TextStyle(color: Color(0xFF94A3B8));
}
