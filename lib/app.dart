import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/repositories/auth_repository.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/theme/theme_cubit.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/chat/chat_loader_screen.dart';
import 'presentation/screens/history/history_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'core/theme/app_theme.dart';

class SmartMindApp extends StatelessWidget {
  const SmartMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthBloc(
            authRepository: AuthRepository(),
          ),
        ),
        BlocProvider(create: (context) => ThemeCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: 'SmartMind AI',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            home: const _AuthChecker(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/home': (context) => const ChatLoaderScreen(),
              '/history': (context) => const HistoryScreen(),
              '/settings': (context) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}

/// Checks SharedPreferences on app startup to decide
/// whether to go straight to chat or show login.
class _AuthChecker extends StatefulWidget {
  const _AuthChecker();

  @override
  State<_AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<_AuthChecker> {
  bool? _isLoggedIn;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (!mounted) return;
    setState(() => _isLoggedIn = loggedIn);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggedIn == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B0B0D),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF6A2B)),
        ),
      );
    }
    return _isLoggedIn! ? const ChatLoaderScreen() : const LoginScreen();
  }
}