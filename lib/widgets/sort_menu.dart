import 'package:crypto_portfolio_tracker/bloc/portfolio_bloc.dart';
import 'package:flutter/material.dart';

class SortMenu extends StatelessWidget {
  final PortfolioSortType currentSortType;
  final Function(PortfolioSortType) onSortSelected;

  const SortMenu({
    Key? key,
    required this.currentSortType,
    required this.onSortSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildSortOptions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: const Row(
        children: [
          Icon(
            Icons.sort,
            color: Colors.white,
            size: 24,
          ),
          SizedBox(width: 12),
          Text(
            'Sort Portfolio',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortOptions() {
    final sortOptions = [
      {
        'type': PortfolioSortType.addedDate,
        'title': 'Recently Added',
        'subtitle': 'Sort by date added',
        'icon': Icons.access_time,
      },
      {
        'type': PortfolioSortType.value,
        'title': 'Total Value',
        'subtitle': 'Highest value first',
        'icon': Icons.monetization_on,
      },
      {
        'type': PortfolioSortType.change24h,
        'title': '24h Change',
        'subtitle': 'Best performers first',
        'icon': Icons.trending_up,
      },
      {
        'type': PortfolioSortType.name,
        'title': 'Name',
        'subtitle': 'Alphabetical order',
        'icon': Icons.sort_by_alpha,
      },
      {
        'type': PortfolioSortType.symbol,
        'title': 'Symbol',
        'subtitle': 'Sort by ticker symbol',
        'icon': Icons.label,
      },
      {
        'type': PortfolioSortType.quantity,
        'title': 'Quantity',
        'subtitle': 'Largest holdings first',
        'icon': Icons.confirmation_number_outlined,
      },
    ];

    return Column(
      children: sortOptions.map((option) {
        final sortType = option['type'] as PortfolioSortType;
        final isSelected = currentSortType == sortType;

        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  isSelected ? Colors.blue.shade600 : const Color(0xFF0D1421),
            ),
            child: Icon(
              option['icon'] as IconData,
              color: isSelected ? Colors.white : Colors.grey.shade400,
              size: 20,
            ),
          ),
          title: Text(
            option['title'] as String,
            style: TextStyle(
              color: isSelected ? Colors.blue.shade400 : Colors.white,
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          subtitle: Text(
            option['subtitle'] as String,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
          trailing: isSelected
              ? Icon(
                  Icons.check_circle,
                  color: Colors.blue.shade400,
                  size: 24,
                )
              : null,
          onTap: () => onSortSelected(sortType),
        );
      }).toList(),
    );
  }
}
