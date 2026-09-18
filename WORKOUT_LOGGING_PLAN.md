# Workout Logging — Implementation Plan

**Locked-in decisions:**
- **Add UI:** full new page via `Navigator.push` (not a modal/bottom sheet).
- **Persistence:** saved to disk, survives app restart.
- **Sets/reps shape:** one session = one sets count + one reps count (not per-set rows).
- **Workout types (for now):** Push-up, Pull-up, Squat only.

This doc is the full spec. Nothing here has been coded yet — implement it by hand to learn it.

---

## 1. Data model

New file: `lib/models/workout_session.dart`

```dart
enum WorkoutType { pushup, pullup, squat }

extension WorkoutTypeLabel on WorkoutType {
  String get label => switch (this) {
    WorkoutType.pushup => 'Push-up',
    WorkoutType.pullup => 'Pull-up',
    WorkoutType.squat => 'Squat',
  };
}

class WorkoutSession {
  final String id;          // e.g. DateTime.now().microsecondsSinceEpoch.toString()
  final WorkoutType type;
  final int sets;
  final int reps;
  final DateTime loggedAt;

  const WorkoutSession({
    required this.id,
    required this.type,
    required this.sets,
    required this.reps,
    required this.loggedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'sets': sets,
    'reps': reps,
    'loggedAt': loggedAt.toIso8601String(),
  };

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => WorkoutSession(
    id: json['id'] as String,
    type: WorkoutType.values.byName(json['type'] as String),
    sets: json['sets'] as int,
    reps: json['reps'] as int,
    loggedAt: DateTime.parse(json['loggedAt'] as String),
  );
}
```

---

## 2. Persistence

Add to `pubspec.yaml`:
```yaml
dependencies:
  shared_preferences: ^2.3.0
```
Run `flutter pub get` after adding it.

New file: `lib/data/workout_repository.dart`

Wraps `SharedPreferences`, storing all sessions as one JSON-encoded list under a single key (e.g. `'workout_sessions'`). Keep it dumb — load the whole list, save the whole list; no need for incremental updates at this scale.

- `Future<List<WorkoutSession>> loadSessions()` — read the string, `jsonDecode` to a `List`, map to `WorkoutSession.fromJson`. Return `[]` if the key is missing or empty.
- `Future<void> saveSessions(List<WorkoutSession> sessions)` — `jsonEncode(sessions.map((s) => s.toJson()).toList())`, write to prefs.

---

## 3. App-level state (who owns the list)

`RootShell` (`lib/root_shell.dart`) already owns the tab index as a `StatefulWidget` — extend it to also own the session list, since it's the parent of both the FAB (triggers "add") and `HistoryScreen` (displays the list).

In `_RootShellState`:
```dart
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
```

`_screens` can no longer be a `const` list since `HistoryScreen` now needs data — build it inline in `build()` instead:
```dart
body: IndexedStack(
  index: _currentIndex,
  children: [
    const HomeScreen(),
    const WorkoutsScreen(),
    HistoryScreen(sessions: _sessions),
    const ProfileScreen(),
  ],
),
```

FAB `onPressed`:
```dart
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
```

---

## 4. Add Session screen

New file: `lib/screens/add_session_screen.dart`

`StatefulWidget` holding form state locally (`WorkoutType? _selectedType`, plus either `TextEditingController`s for sets/reps or plain `int?` state updated via `TextField.onChanged`).

UI, top to bottom:
- `AppBar` with title "Add Session".
- `DropdownButtonFormField<WorkoutType>` listing `WorkoutType.values`, showing `.label`, required.
- Two number fields (`TextField(keyboardType: TextInputType.number)`) for **Sets** and **Reps**.
- Row with **Cancel** and **OK** buttons at the bottom.

Button behavior:
- **Cancel** → `Navigator.pop(context)` with no result (screen closes, nothing added).
- **OK** →
  1. Validate: type selected, sets > 0, reps > 0 (show a `SnackBar` or inline error text if invalid — do not pop).
  2. Build a `WorkoutSession` (id from timestamp, `loggedAt: DateTime.now()`).
  3. `Navigator.pop(context, session)` — returns the new session to `RootShell`.

Keep validation simple (non-empty, parses as positive int) — this is a learning project, not production input hardening.

---

## 5. History screen

Update `lib/screens/history_screen.dart`:

- Becomes `class HistoryScreen extends StatelessWidget`, taking `final List<WorkoutSession> sessions` in its constructor.
- If `sessions.isEmpty`, show the existing centered "History" placeholder text (or a "No sessions yet" message).
- Otherwise, `ListView.builder` over `sessions`, one `ListTile` per session:
  - `leading`: icon per type (e.g. `Icons.fitness_center`).
  - `title`: `'${session.type.label} · ${session.sets} sets × ${session.reps} reps'`.
  - `subtitle`: formatted `session.loggedAt` (`loggedAt.toString()` for now, or a small manual formatter — no need for `intl` unless you want nicer formatting later).

---

## 6. Files touched

| File | Change |
|---|---|
| `pubspec.yaml` | add `shared_preferences` |
| `lib/models/workout_session.dart` | **new** — data model |
| `lib/data/workout_repository.dart` | **new** — load/save via SharedPreferences |
| `lib/screens/add_session_screen.dart` | **new** — the add-session form page |
| `lib/screens/history_screen.dart` | edit — accept and render `sessions` list |
| `lib/root_shell.dart` | edit — own `_sessions` state, load on init, wire FAB to push `AddSessionScreen` and persist result, pass sessions into `HistoryScreen` |

## 7. Suggested build order

1. **Model** (`workout_session.dart`) — no dependencies, easy to sanity-check in isolation.
2. **Repository** (`workout_repository.dart`) — add `shared_preferences`, wire load/save.
3. **`AddSessionScreen`** — build and test the form UI/pop logic on its own (temporarily push it from anywhere to check it returns a session).
4. **Wire `RootShell`** — state fields, `initState` load, FAB `onPressed`, pass sessions to `IndexedStack`.
5. **Update `HistoryScreen`** to render the list.
6. **Manual test** — add a session of each type, confirm it appears at the top of History, hot-restart the app (not just hot reload) and confirm it's still there (proves persistence).

---

*Not implemented by Claude — per project rule, code edits are left for Joshua to write by hand. Ask again with a message starting `AUTO` if you want Claude to implement this directly instead.*
