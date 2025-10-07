import 'package:flutter/material.dart';

class EmptyPortfolio extends StatefulWidget {
  final VoidCallback onAddPressed;

  const EmptyPortfolio({
    Key? key,
    required this.onAddPressed,
  }) : super(key: key);

  @override
  _EmptyPortfolioState createState() => _EmptyPortfolioState();
}

class _EmptyPortfolioState extends State<EmptyPortfolio>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildIcon(),
                      const SizedBox(height: 32),
                      _buildTitle(),
                      const SizedBox(height: 16),
                      _buildSubtitle(),
                      const SizedBox(height: 48),
                      _buildGetStartedButton(),
                      const SizedBox(height: 24),
                      _buildFeaturesList(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade400.withOpacity(0.2),
            Colors.blue.shade600.withOpacity(0.3),
          ],
        ),
        border: Border.all(
          color: Colors.blue.shade600.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Icon(
        Icons.pie_chart_outline,
        size: 60,
        color: Colors.blue.shade400,
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'Start Your Crypto Journey',
      style: TextStyle(
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'Track your cryptocurrency investments\nand watch your portfolio grow',
      style: TextStyle(
        color: Colors.grey.shade400,
        fontSize: 16,
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildGetStartedButton() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 280),
      child: ElevatedButton.icon(
        onPressed: widget.onAddPressed,
        icon: const Icon(Icons.add, size: 24),
        label: const Text(
          'Add Your First Cryptocurrency',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 8,
          shadowColor: Colors.blue.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      {
        'icon': Icons.show_chart,
        'title': 'Real-time Prices',
        'subtitle': 'Get live market data',
      },
      {
        'icon': Icons.sync,
        'title': 'Auto Updates',
        'subtitle': 'Prices refresh every 5 minutes',
      },
      {
        'icon': Icons.storage,
        'title': 'Secure Storage',
        'subtitle': 'Your data stays on device',
      },
    ];

    return Column(
      children: features.map((feature) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2332).withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade800.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                feature['icon'] as IconData,
                color: Colors.blue.shade400,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature['title'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      feature['subtitle'] as String,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
