import 'package:crypto_portfolio_tracker/bloc/portfolio_bloc.dart';
import 'package:crypto_portfolio_tracker/models/coin.dart';
import 'package:crypto_portfolio_tracker/models/portfolio_item.dart';
import 'package:crypto_portfolio_tracker/widgets/coin_search_delegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddCoinSheet extends StatefulWidget {
  @override
  _AddCoinSheetState createState() => _AddCoinSheetState();
}

class _AddCoinSheetState extends State<AddCoinSheet>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _quantityFocusNode = FocusNode();

  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  Coin? _selectedCoin;
  bool _isValidQuantity = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    _initializeAnimations();
    _setupControllers();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    ));

    _slideController.forward();
    _scaleController.forward();
  }

  void _setupControllers() {
    _quantityController.addListener(_validateQuantity);
  }

  void _validateQuantity() {
    final text = _quantityController.text;
    final quantity = double.tryParse(text);

    setState(() {
      _isValidQuantity = quantity != null && quantity > 0;
      _errorMessage = '';

      if (text.isNotEmpty && (quantity == null || quantity <= 0)) {
        _errorMessage = 'Please enter a valid positive number';
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    _searchController.dispose();
    _quantityController.dispose();
    _searchFocusNode.dispose();
    _quantityFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A2332),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildDragHandle(),
                      _buildHeader(),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(20),
                          children: [
                            _buildSearchSection(),
                            const SizedBox(height: 20),
                            if (_selectedCoin != null) ...[
                              _buildSelectedCoinCard(),
                              const SizedBox(height: 20),
                            ],
                            _buildQuantitySection(),
                            const SizedBox(height: 30),
                            _buildActionButtons(),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade600,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Add Cryptocurrency',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close,
              color: Colors.grey,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Search Cryptocurrency',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _showCoinSearch,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1421),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedCoin != null
                    ? Colors.blue.shade600
                    : Colors.grey.shade700,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: Colors.grey.shade400,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedCoin?.displayName ??
                        'Tap to search cryptocurrencies...',
                    style: TextStyle(
                      color: _selectedCoin != null
                          ? Colors.white
                          : Colors.grey.shade400,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (_selectedCoin != null)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCoin = null;
                      });
                    },
                    child: Icon(
                      Icons.clear,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedCoinCard() {
    if (_selectedCoin == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade600.withOpacity(0.2),
            Colors.blue.shade700.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.shade600.withOpacity(0.3),
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
                  Colors.blue.shade400,
                  Colors.blue.shade600,
                ],
              ),
            ),
            child: Center(
              child: Text(
                _selectedCoin!.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedCoin!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _selectedCoin!.symbol.toUpperCase(),
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: Colors.green.shade400,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quantity',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _quantityController,
          focusNode: _quantityFocusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
          decoration: InputDecoration(
            hintText: 'Enter quantity...',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(
              Icons.confirmation_number_outlined,
              color: Colors.grey.shade400,
            ),
            suffixIcon: _selectedCoin != null
                ? Text(
                    _selectedCoin!.symbol.toUpperCase(),
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 60,
              minHeight: 40,
            ),
            filled: true,
            fillColor: const Color(0xFF0D1421),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.blue.shade600,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.red.shade600,
                width: 2,
              ),
            ),
            errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final canAdd = _selectedCoin != null && _isValidQuantity;

    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade600),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: canAdd ? _addToPortfolio : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  canAdd ? Colors.blue.shade600 : Colors.grey.shade700,
              disabledBackgroundColor: Colors.grey.shade700,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: canAdd ? 8 : 0,
            ),
            child: const Text(
              'Add to Portfolio',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showCoinSearch() async {
    final result = await showSearch<Coin?>(
      context: context,
      delegate: CoinSearchDelegate(),
    );

    if (result != null) {
      setState(() {
        _selectedCoin = result;
      });
      _quantityFocusNode.requestFocus();
    }
  }

  void _addToPortfolio() {
    if (_selectedCoin == null || !_isValidQuantity) return;

    final quantity = double.parse(_quantityController.text);

    final portfolioItem = PortfolioItem(
      coinId: _selectedCoin!.id,
      symbol: _selectedCoin!.symbol,
      name: _selectedCoin!.name,
      quantity: quantity,
      addedDate: DateTime.now(),
    );

    context.read<PortfolioBloc>().add(AddPortfolioItemEvent(portfolioItem));
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_selectedCoin!.name} added to portfolio'),
        backgroundColor: Colors.green.shade600,
        action: SnackBarAction(
          label: 'VIEW',
          onPressed: () {
            // Could navigate to portfolio if needed
          },
        ),
      ),
    );

    HapticFeedback.mediumImpact();
  }
}
