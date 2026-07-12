import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../bloc/theme/theme_cubit.dart';

const _bgColor = Color(0xFF0B0B0D);
const _cardBg = Color(0xFF1A1A1D);
const _accent = Color(0xFFFF6A2B);
const _hintColor = Color(0xFF8A8A8E);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _personaKey = 'default_persona';

  String _defaultPersona = 'assistant';
  bool _isClearing = false;

  @override
  void initState() {
    super.initState();
    _loadDefaultPersona();
  }

  Future<void> _loadDefaultPersona() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _defaultPersona = prefs.getString(_personaKey) ?? 'assistant';
    });
  }

  Future<void> _saveDefaultPersona(String persona) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_personaKey, persona);
    setState(() => _defaultPersona = persona);
  }

  Future<void> _clearAllHistory() async {
    setState(() => _isClearing = true);
    try {
      await ChatRepository().deleteAllConversations();
    } catch (_) {
      // best-effort — still clear local cache below
    }
    await ChatRepository().clearAllCachedMessages();
    if (!mounted) return;
    setState(() => _isClearing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All conversation history cleared')),
    );
  }

  Future<void> _confirmAndClearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        title: const Text('Clear all history?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'This permanently deletes all your conversations from the server and clears locally cached messages. This cannot be undone.',
          style: TextStyle(color: _hintColor),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) _clearAllHistory();
  }

  Future<void> _confirmAndLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        title: const Text('Log out?', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AuthRepository().logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const personas = {
      'assistant': 'Assistant',
      'teacher': 'Teacher',
      'coder': 'Coder',
      'friend': 'Friend',
      'analyst': 'Analyst',
    };

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        children: [
          _sectionHeader('Appearance'),
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, mode) => Column(
              children: [
                _radioTile(
                  title: 'Dark',
                  selected: mode == ThemeMode.dark,
                  onTap: () =>
                      context.read<ThemeCubit>().setThemeMode(ThemeMode.dark),
                ),
                _radioTile(
                  title: 'Light',
                  selected: mode == ThemeMode.light,
                  onTap: () =>
                      context.read<ThemeCubit>().setThemeMode(ThemeMode.light),
                ),
                _radioTile(
                  title: 'System',
                  selected: mode == ThemeMode.system,
                  onTap: () =>
                      context.read<ThemeCubit>().setThemeMode(ThemeMode.system),
                ),
              ],
            ),
          ),
          _sectionHeader('Default AI Persona'),
          ...personas.entries.map((entry) => _radioTile(
            title: entry.value,
            selected: _defaultPersona == entry.key,
            onTap: () => _saveDefaultPersona(entry.key),
          )),
          _sectionHeader('Data'),
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
            title: const Text('Clear all history',
                style: TextStyle(color: Colors.white)),
            subtitle: const Text('Removes locally cached messages',
                style: TextStyle(color: _hintColor)),
            trailing: _isClearing
                ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _accent))
                : null,
            onTap: _isClearing ? null : _confirmAndClearHistory,
          ),
          _sectionHeader('Account'),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
            title: const Text('Log out', style: TextStyle(color: Colors.white)),
            onTap: _confirmAndLogout,
          ),
          _sectionHeader('About'),
          const ListTile(
            leading: Icon(Icons.info_outline, color: Colors.white),
            title: Text('App version', style: TextStyle(color: Colors.white)),
            subtitle: Text('1.0.0+1', style: TextStyle(color: _hintColor)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
    child: Text(title,
        style: const TextStyle(
            color: _accent, fontSize: 13, fontWeight: FontWeight.w600)),
  );

  Widget _radioTile({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected ? _accent : Colors.white,
      ),
      title: Text(title,
          style: TextStyle(
              color: selected ? _accent : Colors.white,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
      onTap: onTap,
    );
  }
}