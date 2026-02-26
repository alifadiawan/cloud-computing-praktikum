import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../screens/login_page.dart';
import '../accel/pages/accel_page.dart';
import '../gps/pages/gps_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;
  late AnimationController _floatingController;
  late Animation<double> _animation1;
  late Animation<double> _animation2;
  late Animation<double> _animation3;

  @override
  void initState() {
    super.initState();

    _controller1 = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _controller2 = AnimationController(
      duration: const Duration(milliseconds: 1300),
      vsync: this,
    );
    _controller3 = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );
    _floatingController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    _animation1 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller1, curve: Curves.easeOut),
    );
    _animation2 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller2, curve: Curves.easeOut),
    );
    _animation3 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller3, curve: Curves.easeOut),
    );

    _controller1.forward();
    _controller2.forward();
    _controller3.forward();
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: Stack(
          children: [
            /// Premium gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0A0E1A),
                    const Color(0xFF151D2F),
                    const Color(0xFF0F1420),
                  ],
                ),
              ),
            ),

            /// Animated floating orbs in background
            Positioned(
              top: -200,
              right: -100,
              child: AnimatedBuilder(
                animation: _floatingController,
                builder: (_, __) {
                  return Transform.translate(
                    offset: Offset(
                      50 * math.sin(_floatingController.value * math.pi * 2),
                      80 * math.cos(_floatingController.value * math.pi * 2),
                    ),
                    child: Container(
                      width: 500,
                      height: 500,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF6366F1).withOpacity(0.15),
                            const Color(0xFF6366F1).withOpacity(0.03),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            Positioned(
              bottom: -150,
              left: -150,
              child: AnimatedBuilder(
                animation: _floatingController,
                builder: (_, __) {
                  return Transform.translate(
                    offset: Offset(
                      60 * math.cos(_floatingController.value * math.pi * 2),
                      -70 * math.sin(_floatingController.value * math.pi * 2),
                    ),
                    child: Container(
                      width: 450,
                      height: 450,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFEC4899).withOpacity(0.12),
                            const Color(0xFFEC4899).withOpacity(0.02),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            /// Main content with scroll
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Welcome header
                    FadeInUp(
                      animation: _animation1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dashboard',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Poppins',
                              color: Colors.white,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Kelola semua aktivitas dalam satu tempat',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'Poppins',
                              color: Colors.white.withOpacity(0.5),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 50),

                    /// Main hero card - Absensi
                    FadeInUp(
                      delay: 100,
                      animation: _animation2,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                          );
                        },
                        child: HeroCard(
                          title: 'Absensi',
                          subtitle: 'QR Code Check-in',
                          backgroundColor: const Color(0xFF6366F1),
                          icon: Icons.qr_code_2,
                          isLarge: true,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    /// Feature cards row - Accelerometer & GPS
                    FadeInUp(
                      delay: 200,
                      animation: _animation3,
                      child: Row(
                        children: [
                          /// Accelerometer card - positioned slightly lower
                          Expanded(
                            child: Transform.translate(
                              offset: const Offset(0, 20),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AccelPage(),
                                    ),
                                  );
                                },
                                child: FeatureCard(
                                  title: 'Accelerometer',
                                  backgroundColor: const Color(0xFFEC4899),
                                  icon: Icons.speed,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          /// GPS card - positioned slightly higher
                          Expanded(
                            child: Transform.translate(
                              offset: const Offset(0, -10),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const GpsPage(),
                                    ),
                                  );
                                },
                                child: FeatureCard(
                                  title: 'GPS Tracking',
                                  backgroundColor: const Color(0xFF10B981),
                                  icon: Icons.location_on,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 50),

                    /// Info card at bottom
                    FadeInUp(
                      delay: 300,
                      animation: _animation1,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF1F2937).withOpacity(0.6),
                              const Color(0xFF111827).withOpacity(0.6),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF6366F1).withOpacity(0.3),
                                    const Color(0xFF8B5CF6).withOpacity(0.3),
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.shield,
                                color: Color(0xFF6366F1),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Data Aman & Terlindungi',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Semua data anda dienkripsi dengan aman',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      fontFamily: 'Poppins',
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hero Card Component
class HeroCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final IconData icon;
  final bool isLarge;

  const HeroCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.icon,
    this.isLarge = false,
  });

  @override
  State<HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<HeroCard> with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _hoverAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onHover(bool hovering) {
    if (hovering != _isHovered) {
      _isHovered = hovering;
      if (hovering) {
        _hoverController.forward();
      } else {
        _hoverController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      cursor: SystemMouseCursors.click,
      child: AnimatedBuilder(
        animation: _hoverAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -10 * _hoverAnimation.value),
            child: Container(
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: widget.backgroundColor.withOpacity(0.4 + (_hoverAnimation.value * 0.3)),
                    blurRadius: 50 + (_hoverAnimation.value * 40),
                    offset: Offset(0, 20 + (_hoverAnimation.value * 15)),
                    spreadRadius: 5 + (_hoverAnimation.value * 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  /// Gradient background
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(36),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.backgroundColor,
                          widget.backgroundColor.withOpacity(0.75),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2 + (_hoverAnimation.value * 0.15)),
                        width: 1.5,
                      ),
                    ),
                  ),

                  /// Animated shine effect
                  Positioned(
                    left: -400 + (_hoverAnimation.value * 1000),
                    top: 0,
                    child: Container(
                      width: 200,
                      height: 240,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0),
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  /// Content
                  Padding(
                    padding: const EdgeInsets.all(36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        /// Icon container
                        Transform.scale(
                          scale: 1 + (_hoverAnimation.value * 0.15),
                          child: Transform.rotate(
                            angle: _hoverAnimation.value * 0.5,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.2 + (_hoverAnimation.value * 0.2)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.15 + (_hoverAnimation.value * 0.25)),
                                    blurRadius: 25 + (_hoverAnimation.value * 20),
                                    spreadRadius: 5 + (_hoverAnimation.value * 8),
                                  ),
                                ],
                              ),
                              child: Icon(
                                widget.icon,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                        ),

                        /// Text content
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Poppins',
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.subtitle,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                fontFamily: 'Poppins',
                                color: Colors.white.withOpacity(0.75),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Feature Card Component
class FeatureCard extends StatefulWidget {
  final String title;
  final Color backgroundColor;
  final IconData icon;

  const FeatureCard({
    super.key,
    required this.title,
    required this.backgroundColor,
    required this.icon,
  });

  @override
  State<FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<FeatureCard> with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );
    _hoverAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onHover(bool hovering) {
    if (hovering != _isHovered) {
      _isHovered = hovering;
      if (hovering) {
        _hoverController.forward();
      } else {
        _hoverController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      cursor: SystemMouseCursors.click,
      child: AnimatedBuilder(
        animation: _hoverAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -8 * _hoverAnimation.value),
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: widget.backgroundColor.withOpacity(0.4 + (_hoverAnimation.value * 0.3)),
                    blurRadius: 40 + (_hoverAnimation.value * 35),
                    offset: Offset(0, 15 + (_hoverAnimation.value * 12)),
                    spreadRadius: 3 + (_hoverAnimation.value * 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  /// Gradient background
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.backgroundColor,
                          widget.backgroundColor.withOpacity(0.75),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2 + (_hoverAnimation.value * 0.15)),
                        width: 1.5,
                      ),
                    ),
                  ),

                  /// Animated shine effect
                  Positioned(
                    left: -350 + (_hoverAnimation.value * 850),
                    top: 0,
                    child: Container(
                      width: 180,
                      height: 220,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0),
                            Colors.white.withOpacity(0.25),
                            Colors.white.withOpacity(0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  /// Content centered
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        /// Icon
                        Transform.scale(
                          scale: 1 + (_hoverAnimation.value * 0.2),
                          child: Transform.rotate(
                            angle: _hoverAnimation.value * 0.6,
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.2 + (_hoverAnimation.value * 0.2)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.15 + (_hoverAnimation.value * 0.25)),
                                    blurRadius: 20 + (_hoverAnimation.value * 18),
                                    spreadRadius: 4 + (_hoverAnimation.value * 7),
                                  ),
                                ],
                              ),
                              child: Icon(
                                widget.icon,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        /// Title
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Poppins',
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Fade In Up animation widget
class FadeInUp extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;
  final int delay;

  const FadeInUp({
    super.key,
    required this.child,
    required this.animation,
    this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final delayedValue = (animation.value - (delay / 1600)).clamp(0.0, 1.0);
        return Opacity(
          opacity: delayedValue,
          child: Transform.translate(
            offset: Offset(0, 40 * (1 - delayedValue)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
