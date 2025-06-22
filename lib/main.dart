import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const HabitTrackerApp());

enum AppThemeMode { systemAuto, light, dark }

class HabitTrackerApp extends StatefulWidget {
  const HabitTrackerApp({super.key});
  @override
  State<HabitTrackerApp> createState() => _HabitTrackerAppState();
}

class _HabitTrackerAppState extends State<HabitTrackerApp> {
  AppThemeMode _appThemeMode = AppThemeMode.systemAuto;

  ThemeMode get _themeMode {
    if (_appThemeMode == AppThemeMode.light) return ThemeMode.light;
    if (_appThemeMode == AppThemeMode.dark) return ThemeMode.dark;
    final hour = DateTime.now().hour;
    return (hour >= 7 && hour < 19) ? ThemeMode.light : ThemeMode.dark;
  }

  void _toggleThemeMode() {
    setState(() {
      _appThemeMode = AppThemeMode.values[
          (_appThemeMode.index + 1) % AppThemeMode.values.length];
    });
  }

  @override
  Widget build(BuildContext context) {
    const lightSeed = Color(0xFF4A90E2);
    const darkSeed = Color(0xFF1F2937);

    final lightTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
          seedColor: lightSeed, brightness: Brightness.light),
      textTheme: GoogleFonts.interTextTheme(),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF9FAFB),
      appBarTheme: const AppBarTheme(
          elevation: 0, backgroundColor: Colors.transparent),
      cardTheme: const CardThemeData(
        color: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12))),
        elevation: 2,
        margin: EdgeInsets.zero,
      ),
    );

    final darkTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
          seedColor: darkSeed, brightness: Brightness.dark),
      textTheme:
          GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
          elevation: 0, backgroundColor: Colors.transparent),
      cardTheme: const CardThemeData(
        color: Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12))),
        elevation: 2,
        margin: EdgeInsets.zero,
      ),
    );

    return AnimatedTheme(
      data: _themeMode == ThemeMode.dark ? darkTheme : lightTheme,
      duration: 300.ms,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: _themeMode,
        home: HabitHomePage(
            currentMode: _appThemeMode, onToggleMode: _toggleThemeMode),
      ),
    );
  }
}

class Habit {
  String name;
  TimeOfDay? reminder;
  Set<String> doneDates;
  DateTime? weekStart;

  Habit(this.name, {this.reminder, Set<String>? doneDates, this.weekStart})
      : doneDates = doneDates ?? {};

  bool isDoneToday() {
    final key = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return doneDates.contains(key);
  }

  void toggleDone() {
    final key = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (doneDates.contains(key)) {
      doneDates.remove(key);
    } else {
      if (weekStart != null &&
          DateTime.now().difference(weekStart!).inDays >= 7) {
        doneDates.clear();
        weekStart = DateTime.now();
      } else if (weekStart == null) {
        weekStart = DateTime.now();
      }
      doneDates.add(key);
    }
  }

  int weeklyProgress() {
    if (weekStart == null) return 0;
    final days = DateTime.now().difference(weekStart!).inDays;
    if (days >= 7) {
      weekStart = null;
      doneDates.clear();
      return 0;
    }
    return doneDates.length;
  }

  int currentStreak() {
    int streak = 0;
    DateTime d = DateTime.now();
    while (doneDates.contains(DateFormat('yyyy-MM-dd').format(d))) {
      streak++;
      d = d.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'reminder': reminder != null
            ? {'h': reminder!.hour, 'm': reminder!.minute}
            : null,
        'done': doneDates.toList(),
        'weekStart': weekStart?.toIso8601String(),
      };

  static Habit fromJson(Map<String, dynamic> j) {
    TimeOfDay? rm;
    if (j['reminder'] != null) {
      rm = TimeOfDay(hour: j['reminder']['h'], minute: j['reminder']['m']);
    }
    return Habit(
      j['name'],
      reminder: rm,
      doneDates: (j['done'] as List).map((e) => e as String).toSet(),
      weekStart:
          j['weekStart'] != null ? DateTime.parse(j['weekStart']) : null,
    );
  }
}

class HabitHomePage extends StatefulWidget {
  final AppThemeMode currentMode;
  final VoidCallback onToggleMode;

  const HabitHomePage(
      {super.key, required this.currentMode, required this.onToggleMode});
  @override
  State<HabitHomePage> createState() => _HabitHomePageState();
}

class _HabitHomePageState extends State<HabitHomePage> {
  final List<Habit> _habits = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = prefs.getString('habits');
      if (s != null) {
        final list = jsonDecode(s) as List<dynamic>;
        _habits.clear();
        _habits.addAll(list.map((e) => Habit.fromJson(e)));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'habits', jsonEncode(_habits.map((e) => e.toJson()).toList()));
  }

  void _showEditDialog([int? idx]) {
    final isEdit = idx != null;
    final ctrl = TextEditingController(text: isEdit ? _habits[idx!].name : '');
    TimeOfDay? pick = isEdit ? _habits[idx].reminder : null;
    String? error;

    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(builder: (c, st) {
        return AlertDialog(
          title: Text(
              isEdit ? 'Редактировать привычку' : 'Добавить привычку'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                maxLength:20,
                decoration: InputDecoration(
                    labelText: 'Название', errorText: error, counterText: ''),
                onChanged: (_) => st(() => error = null),
              ),
              const SizedBox(height: 12),
              Row(children: [
                const Text('Время:'),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    final t = await showTimePicker(
                        context: c,
                        initialTime: pick ?? TimeOfDay.now());
                    if (t != null) st(() => pick = t);
                  },
                  child: Text(pick?.format(context) ?? 'Выбрать'),
                )
              ])
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c), child: const Text('Отмена')),
            ElevatedButton(
              onPressed: () {
                final name = ctrl.text.trim();
                if (name.isEmpty) {
                  st(() => error = 'Введите название');
                  return;
                }
                setState(() {
                  if (isEdit) {
                    _habits[idx!].name = name;
                    _habits[idx].reminder = pick;
                  } else {
                    _habits.add(Habit(name, reminder: pick));
                  }
                });
                _saveHabits();
                Navigator.pop(c);
              },
              child: Text(isEdit ? 'Сохранить' : 'Добавить'),
            )
          ],
        );
      }),
    );
  }

  int _hoverIndex = -1;

  Widget _buildCard(int i, BoxConstraints cons) {
    final h = _habits[i];
    final done = h.isDoneToday();
    final prog = h.weeklyProgress() / 7;
    final bg = done
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).cardTheme.color!;
    final hover = _hoverIndex == i;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoverIndex = i),
      onExit: (_) => setState(() => _hoverIndex = -1),
      child: Animate(
        effects: [
          FadeEffect(duration: 250.ms),
          if (hover)
            ScaleEffect(begin: const Offset(1, 1), end: const Offset(1.02, 1.02), duration: 200.ms)
        ],
        child: Card(
          color: bg,
          child: InkWell(
            onTap: () {
              setState(() {
                h.toggleDone();
              });
              _saveHabits();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(h.name,
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                      if (h.reminder != null) ...[
                        const Icon(Icons.alarm, size: 16),
                        const SizedBox(width: 4),
                        Text(h.reminder!.format(context),
                            style: Theme.of(context).textTheme.bodySmall)
                      ]
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(value: prog, minHeight: 8),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('🔥 ${h.currentStreak()} дн.'),
                      Row(children: [
                        IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showEditDialog(i)),
                        IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() => _habits.removeAt(i));
                              _saveHabits();
                            }),
                      ])
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(
        title: Text('📚 Привычки', style: GoogleFonts.poppins(fontSize: 22)),
        actions: [
          IconButton(icon: const Icon(Icons.palette), onPressed: widget.onToggleMode),
          IconButton(
            icon: Icon(
              widget.currentMode == AppThemeMode.dark
                  ? Icons.dark_mode
                  : widget.currentMode == AppThemeMode.light
                      ? Icons.light_mode
                      : Icons.auto_mode,
            ),
            onPressed: widget.onToggleMode,
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              DateFormat.yMMMMd().format(DateTime.now()),
              style: GoogleFonts.poppins(fontStyle: FontStyle.italic),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(builder: (context, cons) {
          final isMobile = cons.maxWidth < 600;
          if (isMobile) {
            return ListView.builder(
              itemCount: _habits.length,
              itemBuilder: (_, i) => SizedBox(height: 100, child: _buildCard(i, cons)),
            );
          }
          final cols = (cons.maxWidth / 300).floor().clamp(1, 4);
          return GridView.builder(
            itemCount: _habits.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 3,
            ),
            itemBuilder: (_, i) => _buildCard(i, cons),
          );
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
