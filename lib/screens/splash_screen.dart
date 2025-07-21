import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:veda_jyoti_new/services/ephemeris_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  String _statusText = 'Initializing Veda Jyoti...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      setState(() {
        _statusText = 'Loading Swiss Ephemeris...';
      });

      // Initialize the ephemeris service
      final ephemerisService = ref.read(ephemerisServiceProvider);
      await ephemerisService.initialize();

      setState(() {
        _statusText = 'Preparing astrological calculations...';
      });

      // Add a small delay for better UX
      await Future.delayed(const Duration(milliseconds: 1500));

      setState(() {
        _statusText = 'Ready!';
        _isLoading = false;
      });

      // Navigate to home after a brief pause
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      setState(() {
        _statusText = 'Initialization failed. Continuing anyway...';
        _isLoading = false;
      });
      
      // Still navigate to home even if initialization fails
      await Future.delayed(const Duration(milliseconds: 2000));
      
      if (mounted) {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Icon/Logo placeholder
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(
                  Icons.stars,
                  size: 60,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // App name
              Text(
                'Veda Jyoti',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // App description
              Text(
                'Vedic Astrology Application',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Loading indicator
              if (_isLoading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
              ],
              
              // Status text
              Text(
                _statusText,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}