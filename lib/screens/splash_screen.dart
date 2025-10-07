import 'dart:math' as math;

import 'package:animations/animations.dart';
import 'package:crypto_portfolio_tracker/bloc/coin_list_bloc.dart';
import 'package:crypto_portfolio_tracker/bloc/portfolio_bloc.dart';
import 'package:crypto_portfolio_tracker/screens/portfolio_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;

  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _initializeAnimations();
    _startAnimationSequence();
    _initializeData();
  }

  void _initializeAnimations() {
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 4 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 500));

    _scaleController.forward();
    await Future.delayed(const Duration(milliseconds: 300));

    _fadeController.forward();
    _rotationController.forward();

    await Future.delayed(const Duration(milliseconds: 800));
    _pulseController.repeat(reverse: true);

    await Future.delayed(const Duration(milliseconds: 1500));
    _checkDataAndNavigate();
  }

  void _initializeData() {
    context.read<CoinListBloc>().add(LoadCoinListEvent());
    context.read<PortfolioBloc>().add(LoadPortfolioEvent());
  }

  void _checkDataAndNavigate() async {
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    _navigateToPortfolio();
  }

  void _navigateToPortfolio() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PortfolioScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeThroughTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 1000),
        reverseTransitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              Color(0xFF2A3441),
              Color(0xFF1A2332),
              Color(0xFF0D1421),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Center(
                  child: _buildAnimatedLogo(),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAppTitle(),
                  const SizedBox(height: 40),
                  _buildLoadingIndicator(),
                  const SizedBox(height: 20),
                  _buildLoadingText(),
                ],
              ),
              Flexible(child: _buildFooter()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _scaleAnimation,
        _rotationAnimation,
        _pulseAnimation,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value * _pulseAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF64B5F6).withOpacity(0.9),
                    Color(0xFF42A5F5),
                    Color(0xFF2196F3),
                    Color(0xFF1E88E5),
                    Color(0xFF1976D2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.2),
                    blurRadius: 50,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.trending_up,
                    size: 70,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  Positioned(
                    top: 25,
                    right: 25,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Icon(
                        Icons.show_chart,
                        size: 12,
                        color: Colors.blue.shade600,
                      ),
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

  Widget _buildAppTitle() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Color(0xFF64B5F6),
                Color(0xFF2196F3),
                Color(0xFF1976D2),
              ],
            ).createShader(bounds),
            child: const Text(
              'Crypto Portfolio',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track • Analyze • Grow',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade300,
              fontWeight: FontWeight.w400,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: BlocBuilder<CoinListBloc, CoinListState>(
        builder: (context, state) {
          if (state is CoinListLoading) {
            return _buildAnimatedProgress();
          } else if (state is CoinListLoaded) {
            return _buildSuccessIndicator();
          } else if (state is CoinListError) {
            return _buildErrorIndicator();
          }
          return _buildAnimatedProgress();
        },
      ),
    );
  }

  Widget _buildAnimatedProgress() {
    return Container(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.blue.shade400,
              ),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.shade600.withOpacity(0.2),
            ),
            child: Icon(
              Icons.downloading,
              color: Colors.blue.shade300,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessIndicator() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.green.shade600,
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.check,
        color: Colors.white,
        size: 30,
      ),
    );
  }

  Widget _buildErrorIndicator() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.red.shade600,
      ),
      child: const Icon(
        Icons.error_outline,
        color: Colors.white,
        size: 30,
      ),
    );
  }

  Widget _buildLoadingText() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: BlocBuilder<CoinListBloc, CoinListState>(
        builder: (context, state) {
          String text = 'Initializing...';

          if (state is CoinListLoading) {
            text = state.isRefreshing
                ? 'Updating data...'
                : 'Loading cryptocurrencies...';
          } else if (state is CoinListLoaded) {
            text = 'Ready to track your portfolio!';
          } else if (state is CoinListError) {
            text = 'Using cached data...';
          }

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              text,
              key: ValueKey(text),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w300,
              ),
              textAlign: TextAlign.center,
            ),
          );
        },
      ),
    );
  }

  Widget _buildFooter() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 30),
        child: Column(
          children: [
            Text(
              'Powered by CoinGecko',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 2,
              width: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.blue.shade400,
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
