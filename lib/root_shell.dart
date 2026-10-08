import 'package:flutter/material.dart';
import 'data/workout_repository.dart';
import 'models/workout_session.dart';
import 'screens/home_screen.dart';
import 'screens/logging_choice_screen.dart';
import 'screens/workouts_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/app_header.dart';
import 'widgets/glass_nav_bar.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _currentIndex = 0;

  final WorkoutRepository _repository = WorkoutRepository();
  List<WorkoutSession> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final loaded = await _repository.loadSessions();
    setState(() => _sessions = loaded);
  }

  Future<void> _addSession(WorkoutSession session) async {
    setState(() => _sessions = [session, ..._sessions]); // newest first
    await _repository.saveSessions(_sessions);
  }

  Future<void> _updateSession(WorkoutSession updated) async {
    setState(() {
      _sessions = [for (final s in _sessions) s.id == updated.id ? updated : s];
    });
    await _repository.saveSessions(_sessions);
  }

  Future<void> _deleteSession(WorkoutSession session) async {
    setState(() => _sessions = _sessions.where((s) => s.id != session.id).toList());
    await _repository.saveSessions(_sessions);
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(),
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomeScreen(),
          const WorkoutsScreen(),
          HistoryScreen(
            sessions: _sessions,
            onEdit: _updateSession,
            onDelete: _deleteSession,
          ),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: GlassNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        onCenterTap: () async {
          final result = await Navigator.push<WorkoutSession>(
            context,
            MaterialPageRoute(builder: (_) => const LoggingChoiceScreen()),
          );
          if (result != null) {
            await _addSession(result);
            setState(() => _currentIndex = 2); // jump to History tab so the new entry is visible
          }
        },
        items: const [
          GlassNavItem(Icons.home_rounded, 'Home'),
          GlassNavItem(Icons.fitness_center_rounded, 'Workouts'),
          GlassNavItem(Icons.history_rounded, 'History'),
          GlassNavItem(Icons.person_rounded, 'Profile'),
        ],
      ),
    );
  }
}
