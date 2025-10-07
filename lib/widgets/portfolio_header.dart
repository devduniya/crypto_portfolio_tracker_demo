import 'package:crypto_portfolio_tracker/bloc/portfolio_bloc.dart';
import 'package:crypto_portfolio_tracker/widgets/animated_counter.dart';
import 'package:crypto_portfolio_tracker/widgets/change_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class PortfolioHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(),
          const SizedBox(height: 20),
          _buildPortfolioCard(),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return const Row(
      children: [
        Text(
          'Your Portfolio',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Spacer(),
      ],
    );
  }

  Widget _buildPortfolioCard() {
    return BlocBuilder<PortfolioBloc, PortfolioState>(
      builder: (context, state) {
        double totalValue = 0.0;
        double totalChange24h = 0.0;
        double totalChange24hPercentage = 0.0;
        DateTime? lastUpdated;

        if (state is PortfolioLoaded) {
          totalValue = state.totalValue;
          totalChange24h = state.totalChange24h;
          totalChange24hPercentage = state.totalChange24hPercentage;
          lastUpdated = state.lastUpdated;
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade600,
                Colors.blue.shade700,
                Colors.blue.shade800,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.blue.withOpacity(0.1),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      'Total Portfolio Value',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        overflow: TextOverflow.visible
                      ),
                    ),
                  ),
                  if (lastUpdated != null)
                    Flexible(
                      child: Text(
                        'Updated ${_formatTime(lastUpdated)}',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedCounter(
                value: totalValue,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 12),
              if (totalChange24h != 0 || totalChange24hPercentage != 0)
                ChangeIndicator(
                  changeValue: totalChange24h,
                  changePercentage: totalChange24hPercentage,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM d, y').format(dateTime);
    }
  }
}
