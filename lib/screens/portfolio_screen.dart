import 'dart:async';

import 'package:crypto_portfolio_tracker/bloc/coin_list_bloc.dart';
import 'package:crypto_portfolio_tracker/bloc/portfolio_bloc.dart';
import 'package:crypto_portfolio_tracker/widgets/add_coin_sheet.dart';
import 'package:crypto_portfolio_tracker/widgets/empty_portfolio.dart';
import 'package:crypto_portfolio_tracker/widgets/portfolio_header.dart';
import 'package:crypto_portfolio_tracker/widgets/portfolio_item_card.dart';
import 'package:crypto_portfolio_tracker/widgets/sort_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';

class PortfolioScreen extends StatefulWidget {
  @override
  _PortfolioScreenState createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _fabAnimationController;
  late AnimationController _headerAnimationController;
  late Animation<double> _fabAnimation;
  late Animation<Offset> _headerSlideAnimation;

  final ScrollController _scrollController = ScrollController();
  bool _showFloatingHeader = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _initializeAnimations();
    _setupScrollController();
    _startDataLoading();
  }

  void _initializeAnimations() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    );

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutCubic,
    ));

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _headerAnimationController.forward();
      }
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _fabAnimationController.forward();
      }
    });
  }

  void _setupScrollController() {
    _scrollController.addListener(() {
      final shouldShow = _scrollController.offset > 200;
      if (shouldShow != _showFloatingHeader) {
        setState(() {
          _showFloatingHeader = shouldShow;
        });
      }
    });
  }

  void _startDataLoading() {
    context.read<PortfolioBloc>().add(StartPeriodicUpdatesEvent());

    final coinListState = context.read<CoinListBloc>().state;
    if (coinListState is! CoinListLoaded) {
      context.read<CoinListBloc>().add(LoadCoinListEvent());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        context.read<PortfolioBloc>().add(StartPeriodicUpdatesEvent());
        context.read<PortfolioBloc>().add(RefreshPricesEvent());
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        context.read<PortfolioBloc>().add(StopPeriodicUpdatesEvent());
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fabAnimationController.dispose();
    _headerAnimationController.dispose();
    _scrollController.dispose();
    context.read<PortfolioBloc>().add(StopPeriodicUpdatesEvent());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildFloatingHeader(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D1421),
              Color(0xFF1A2332),
              Color(0xFF0D1421),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SlideTransition(
                position: _headerSlideAnimation,
                child: PortfolioHeader(),
              ),
              Expanded(
                child: _buildPortfolioContent(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          heroTag: "add_coin_fab",
          onPressed: () async {
            HapticFeedback.lightImpact();

            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              enableDrag: true,
              useSafeArea: true,
              transitionAnimationController: AnimationController(
                vsync: this,
                duration: const Duration(milliseconds: 350),
              )..forward(),
              builder: (context) => AddCoinSheet(),
            );

            // FAB bounce animation after sheet closes
            await _fabAnimationController.reverse();
            await _fabAnimationController.forward();
          },
          icon: const Icon(Icons.add),
          label: const Text(
            'Add Coin',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          elevation: 8,
          highlightElevation: 12,
        ),
      ),
    );
  }

  PreferredSizeWidget? _buildFloatingHeader() {
    if (!_showFloatingHeader) return null;

    return AppBar(
      backgroundColor: const Color(0xFF1A2332).withOpacity(0.95),
      elevation: 8,
      title: BlocBuilder<PortfolioBloc, PortfolioState>(
        builder: (context, state) {
          if (state is PortfolioLoaded) {
            final formatter =
                NumberFormat.currency(symbol: '\$', decimalDigits: 2);
            return Row(
              children: [
                const Text(
                  'Portfolio',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  formatter.format(state.totalValue),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            );
          }
          return const Text('Portfolio');
        },
      ),
      actions: [
        _buildSortButton(),
        _buildRefreshButton(),
      ],
    );
  }

  Widget _buildPortfolioContent() {
    return BlocBuilder<PortfolioBloc, PortfolioState>(
      builder: (context, state) {
        if (state is PortfolioLoading) {
          return _buildLoadingState();
        }

        if (state is PortfolioError) {
          return _buildErrorState(state);
        }

        if (state is PortfolioLoaded) {
          if (state.items.isEmpty) {
            return EmptyPortfolio(
              onAddPressed: _showAddCoinSheet,
            );
          }

          return _buildPortfolioList(state);
        }

        return _buildLoadingState();
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Loading your portfolio...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(PortfolioError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 20),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              state.message,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            if (state.canRetry) ...[
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<PortfolioBloc>().add(LoadPortfolioEvent());
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioList(PortfolioLoaded state) {
    final sortedItems = state.sortedItems ?? [];

    if (sortedItems.isEmpty)
      return EmptyPortfolio(
        onAddPressed: _showAddCoinSheet,
      );

    return RefreshIndicator(
      onRefresh: () async {
        final completer = Completer<void>();
        context.read<PortfolioBloc>().add(RefreshPricesEvent());

        Timer(const Duration(seconds: 3), () {
          if (!completer.isCompleted) {
            completer.complete();
          }
        });

        return completer.future;
      },
      color: Colors.blue,
      backgroundColor: const Color(0xFF1A2332),
      child: AnimationLimiter(
        child: ListView.builder(
          controller: _scrollController,
          itemCount: sortedItems.length,
          itemBuilder: (context, index) {
            final item = sortedItems[index];
            if (item == null) return const SizedBox.shrink();
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 500),
              delay: Duration(milliseconds: index * 50),
              child: SlideAnimation(
                verticalOffset: 30.0,
                child: FadeInAnimation(
                  child: PortfolioItemCard(
                    key: ValueKey(item.coinId),
                    item: item,
                    onRemove: () => _removeItem(item.coinId),
                    onUpdate: (quantity) => _updateItem(item.coinId, quantity),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSortButton() {
    return BlocBuilder<PortfolioBloc, PortfolioState>(
      builder: (context, state) {
        if (state is! PortfolioLoaded || state.items.isEmpty) {
          return const SizedBox.shrink();
        }

        return IconButton(
          onPressed: () {
            HapticFeedback.selectionClick();
            _showSortMenu();
          },
          icon: const Icon(Icons.sort),
          tooltip: 'Sort portfolio',
        );
      },
    );
  }

  Widget _buildRefreshButton() {
    return BlocBuilder<PortfolioBloc, PortfolioState>(
      builder: (context, state) {
        if (state is PortfolioLoaded && state.isRefreshing) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        }

        return IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            context.read<PortfolioBloc>().add(RefreshPricesEvent());
          },
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh prices',
        );
      },
    );
  }

  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SortMenu(
        currentSortType:
            (context.read<PortfolioBloc>().state as PortfolioLoaded).sortType,
        onSortSelected: (sortType) {
          context.read<PortfolioBloc>().add(SortPortfolioEvent(sortType));
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showAddCoinSheet() {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      useSafeArea: true,
      builder: (context) => AddCoinSheet(),
    );
  }

  void _removeItem(String coinId) {
    HapticFeedback.mediumImpact();
    context.read<PortfolioBloc>().add(RemovePortfolioItemEvent(coinId));

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Asset removed from portfolio'),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            // Implement undo if you want
          },
        ),
      ),
    );
  }

  void _updateItem(String coinId, double quantity) {
    context.read<PortfolioBloc>().add(
          UpdatePortfolioItemEvent(coinId: coinId, quantity: quantity),
        );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Quantity updated'),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
