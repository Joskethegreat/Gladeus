import 'package:flutter/material.dart';
import 'data/workout_repository.dart';
import 'models/workout_session.dart';
import 'screens/add_session_screen.dart';
import 'screens/home_screen.dart';
import 'screens/workouts_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/app_header.dart';

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

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        width: 64,
        height: 64,
        child: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push<WorkoutSession>(
              context,
              MaterialPageRoute(builder: (_) => const AddSessionScreen()),
            );
            if (result != null) {
              await _addSession(result);
              setState(() => _currentIndex = 2); // jump to History tab so the new entry is visible
            }
          },
          backgroundColor: const Color(0xFFF5A623),
          foregroundColor: Colors.white,
          elevation: 4,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 30),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomeScreen(),
          const WorkoutsScreen(),
          HistoryScreen(sessions: _sessions),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        backgroundColor: const Color(0xFF121218),
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Workouts'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
