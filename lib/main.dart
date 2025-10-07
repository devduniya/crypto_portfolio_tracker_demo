import 'package:crypto_portfolio_tracker/bloc/coin_list_bloc.dart';
import 'package:crypto_portfolio_tracker/bloc/portfolio_bloc.dart';
import 'package:crypto_portfolio_tracker/screens/splash_screen.dart';
import 'package:crypto_portfolio_tracker/services/api_service.dart';
import 'package:crypto_portfolio_tracker/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(CryptoPortfolioApp());
}

class CryptoPortfolioApp extends StatelessWidget {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  CryptoPortfolioApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CoinListBloc>(
          create: (context) => CoinListBloc(
            apiService: _apiService,
            storageService: _storageService,
          ),
        ),
        BlocProvider<PortfolioBloc>(
          create: (context) => PortfolioBloc(
            storageService: _storageService,
            apiService: _apiService,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Crypto Portfolio Tracker',
        debugShowCheckedModeBanner: false,
        theme: _buildAppTheme(),
        home: SplashScreen(),
      ),
    );
  }

  ThemeData _buildAppTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0D1421),
      cardColor: const Color(0xFF1A2332),
      dividerColor: const Color(0xFF2A3441),
      textTheme: const TextTheme(
        displayLarge:
            TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        displayMedium:
            TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: Colors.white70),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A2332),
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 8,
        highlightElevation: 12,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF1A2332),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0D1421),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
        ),
        hintStyle: TextStyle(color: Colors.grey.shade400),
      ),
    );
  }
}
