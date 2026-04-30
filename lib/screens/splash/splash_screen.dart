// lib/screens/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/user_preferences.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Animation Controllers ──────────────────────────────────────────────────
  late final AnimationController _glowCtrl;
  late final AnimationController _logoCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _taglineCtrl;

  // ── Animations ─────────────────────────────────────────────────────────────
  late final Animation<double> _glowOpacity;
  late final Animation<double> _glowRadius;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  late final Animation<double> _appNameOpacity;
  late final Animation<Offset>  _appNameSlide;

  late final Animation<double> _taglineOpacity;
  late final Animation<Offset>  _taglineSlide;

  late final Animation<double> _pulse;

  late final Animation<double> _versionOpacity;

  @override
  void initState() {
    super.initState();

    // ── 1. Glow fade-in (0 → 800ms) ─────────────────────
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _glowOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeOut),
    );
    _glowRadius = Tween<double>(begin: 0.3, end: 0.65).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeOut),
    );

    // ── 2. Logo scale + opacity (0 → 900ms, elastic) ─────
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // ── 3. App name slide up + fade (0 → 500ms) ──────────
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _appNameOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn),
    );
    _appNameSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));

    // ── 4. Tagline (0 → 400ms, slight delay after name) ──
    _taglineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeIn),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeOutCubic));

    // ── 5. Idle pulse on logo (repeats forever) ───────────
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // ── 6. Version number shares tagline opacity ──────────
    _versionOpacity = _taglineOpacity;

    // ── Kick off the sequence ─────────────────────────────
    _runSequence();
  }

  Future<void> _runSequence() async {
    // Slight pause before anything starts
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    // Glow first, logo overlaps
    _glowCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;

    await _logoCtrl.forward();
    if (!mounted) return;

    // App name
    await Future.delayed(const Duration(milliseconds: 100));
    await _textCtrl.forward();
    if (!mounted) return;

    // Tagline 150ms after name
    await Future.delayed(const Duration(milliseconds: 150));
    await _taglineCtrl.forward();
    if (!mounted) return;

    // Hold on screen then navigate
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    _navigate();
  }

  void _navigate() {
    // 1. Check if authenticated
    if (!AuthService.instance.isAuthenticated) {
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    // 2. Check if onboarding was already completed
    final box = Hive.box<UserPreferences>(AppConstants.hiveBoxSettings);
    final prefs = box.get('prefs');
    if (prefs != null && prefs.onboardingDone) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/onboarding');
    }
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _taglineCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // ── Layer 1: radial glow behind everything ──────
          _buildGlow(),

          // ── Layer 2: center content ─────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                _buildLogo(),

                const SizedBox(height: 32),

                // App name
                _buildAppName(),

                const SizedBox(height: 10),

                // Tagline
                _buildTagline(),
              ],
            ),
          ),

          // ── Layer 3: version number at bottom ───────────
          _buildVersion(),
        ],
      ),
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _buildGlow() {
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) {
        return CustomPaint(
          painter: _RadialGlowPainter(
            opacity: _glowOpacity.value,
            radiusFraction: _glowRadius.value,
            color: AppColors.primaryBlue,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_logoCtrl, _pulseCtrl]),
      builder: (_, __) {
        return Opacity(
          opacity: _logoOpacity.value,
          child: Transform.scale(
            scale: _logoScale.value * _pulse.value,
            child: _LogoWidget(),
          ),
        );
      },
    );
  }

  Widget _buildAppName() {
    return AnimatedBuilder(
      animation: _textCtrl,
      builder: (_, __) {
        return FadeTransition(
          opacity: _appNameOpacity,
          child: SlideTransition(
            position: _appNameSlide,
            child: RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Briefly',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.2,
                    ),
                  ),
                  TextSpan(
                    text: ' AI',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTagline() {
    return AnimatedBuilder(
      animation: _taglineCtrl,
      builder: (_, __) {
        return FadeTransition(
          opacity: _taglineOpacity,
          child: SlideTransition(
            position: _taglineSlide,
            child: const Text(
              AppConstants.appTagline,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVersion() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _taglineCtrl,
        builder: (_, __) {
          return Opacity(
            opacity: _versionOpacity.value,
            child: const Text(
              'v${AppConstants.appVersion}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textHint,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Logo widget ────────────────────────────────────────────────────────────────

class _LogoWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryBlue,
            AppColors.purpleAi,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.45),
            blurRadius: 36,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.purpleAi.withOpacity(0.2),
            blurRadius: 48,
            spreadRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'B',
          style: TextStyle(
            color: Colors.white,
            fontSize: 56,
            fontWeight: FontWeight.w800,
            letterSpacing: -3,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

// ── Radial glow painter ────────────────────────────────────────────────────────

class _RadialGlowPainter extends CustomPainter {
  final double opacity;
  final double radiusFraction;
  final Color color;

  const _RadialGlowPainter({
    required this.opacity,
    required this.radiusFraction,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * radiusFraction;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(0.18 * opacity),
          color.withOpacity(0.06 * opacity),
          color.withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_RadialGlowPainter old) =>
      old.opacity != opacity || old.radiusFraction != radiusFraction;
}