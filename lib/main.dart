import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const HabitTrackerApp());

class HabitTrackerApp extends StatefulWidget {
  const HabitTrackerApp({super.key});
  @override
  State<HabitTrackerApp> createState() => _HabitTrackerAppState();
}

class _HabitTrackerAppState extends State<HabitTrackerApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        if (_themeMode != ThemeMode.system) return;
        final brightness = WidgetsBinding.instance.window.platformBrightness;
        _themeMode = brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
      });
    });
  }

  void _toggleTheme() => setState(() {
        _themeMode =
            _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
      });

  @override
  Widget build(BuildContext context) {
    final lightSeed = const Color(0xFF6C8CAF);
    final darkSeed = const Color(0xFF8AA6B1);

    final lightTheme = ThemeData(
      colorScheme:
          ColorScheme.fromSeed(seedColor: lightSeed, brightness: Brightness.light),
      textTheme: GoogleFonts.poppinsTextTheme(),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF5F7FA),
    );
    final darkTheme = ThemeData(
      colorScheme:
          ColorScheme.fromSeed(seedColor: darkSeed, brightness: Brightness.dark),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF12191F),
    );

    return AnimatedTheme(
      data: _themeMode == ThemeMode.dark ? darkTheme : lightTheme,
      duration: 600.ms,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: _themeMode,
        home: HabitHomePage(onToggleTheme: _toggleTheme),
      ),
    );
  }
}

class Habit {
  String name;
  TimeOfDay? reminderTime;
  DateTime createdAt;
  Set<String> completedDates;
  DateTime? firstActivationDate;

  Habit(this.name,
      {this.reminderTime,
      DateTime? createdAt,
      Set<String>? completedDates,
      this.firstActivationDate})
      : createdAt = createdAt ?? DateTime.now(),
        completedDates = completedDates ?? {};

  bool isCompletedToday() {
    final key = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return completedDates.contains(key);
  }

  void toggleToday() {
    final key = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (completedDates.contains(key)) {
      completedDates.remove(key);
    } else {
      if (firstActivationDate != null &&
          DateTime.now().difference(firstActivationDate!).inDays >= 7) {
        completedDates.clear();
        firstActivationDate = DateTime.now();
      } else if (firstActivationDate == null) {
        firstActivationDate = DateTime.now();
      }
      completedDates.add(key);
    }
  }

  int getProgressForWeek() {
    if (firstActivationDate == null) return 0;
    final days = DateTime.now().difference(firstActivationDate!).inDays;
    if (days >= 7) {
      firstActivationDate = null;
      completedDates.clear();
      return 0;
    }
    return completedDates.length;
  }

  int getCurrentStreak() {
    int streak = 0;
    DateTime d = DateTime.now();
    while (completedDates
        .contains(DateFormat('yyyy-MM-dd').format(d))) {
      streak++;
      d = d.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'reminderTime': reminderTime != null
            ? {'h': reminderTime!.hour, 'm': reminderTime!.minute}
            : null,
        'createdAt': createdAt.toIso8601String(),
        'completedDates': completedDates.toList(),
        'firstActivationDate':
            firstActivationDate?.toIso8601String(),
      };

  static Habit fromJson(Map<String, dynamic> j) {
    TimeOfDay? rt;
    if (j['reminderTime'] != null) {
      rt = TimeOfDay(
          hour: j['reminderTime']['h'], minute: j['reminderTime']['m']);
    }
    return Habit(
      j['name'],
      reminderTime: rt,
      createdAt: DateTime.parse(j['createdAt']),
      completedDates: (j['completedDates'] as List)
          .map((e) => e as String)
          .toSet(),
      firstActivationDate: j['firstActivationDate'] != null
          ? DateTime.parse(j['firstActivationDate'])
          : null,
    );
  }
}

class HabitHomePage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const HabitHomePage({super.key, required this.onToggleTheme});
  @override
  State<HabitHomePage> createState() => _HabitHomePageState();
}

class _HabitHomePageState extends State<HabitHomePage> {
  final _habits = <Habit>[];
  bool _loading = true;

  final _nameCtrl = TextEditingController();
  TimeOfDay? _pickedTime;

  String? _nameError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future _load() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString('habits');
    if (s != null) {
      final list = jsonDecode(s) as List;
      _habits.clear();
      _habits.addAll(list.map((e) => Habit.fromJson(e)));
    }
    _sortList();
    setState(() => _loading = false);
  }

  Future _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        'habits', jsonEncode(_habits.map((e) => e.toJson()).toList()));
  }

  void _sortList() {
    _habits.sort((a, b) {
      if (a.reminderTime == null && b.reminderTime == null) return 0;
      if (a.reminderTime == null) return 1;
      if (b.reminderTime == null) return -1;
      final aMinutes = a.reminderTime!.hour * 60 + a.reminderTime!.minute;
      final bMinutes = b.reminderTime!.hour * 60 + b.reminderTime!.minute;
      return aMinutes.compareTo(bMinutes);
    });
  }

  void _editAdd([int? idx]) {
    final isEdit = idx != null;
    if (isEdit) {
      final h = _habits[idx];
      _nameCtrl.text = h.name;
      _pickedTime = h.reminderTime;
    } else {
      _nameCtrl.clear();
      _pickedTime = null;
    }
    _nameError = null;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (c, st) => AlertDialog(
          title: Text(isEdit ? 'Редактировать' : 'Добавить'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: _nameCtrl,
              maxLength:25,
              decoration: InputDecoration(
                labelText: 'Название',
                errorText: _nameError,
                counterText: '', // Скрыть счётчик символов
              ),
              onChanged: (_) {
                if (_nameError != null) {
                  st(() => _nameError = null);
                }
              },
            ),
            Row(children: [
              const Text('Время: '),
              TextButton(
                onPressed: () async {
                  final t = await showTimePicker(
                      context: context,
                      initialTime: _pickedTime ?? TimeOfDay.now());
                  if (t != null) st(() => _pickedTime = t);
                },
                child: Text(_pickedTime?.format(context) ?? 'Выбрать'),
              )
            ]),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
            ElevatedButton(
                onPressed: () {
                  final n = _nameCtrl.text.trim();
                  if (n.isEmpty) {
                    st(() => _nameError = 'Введите название');
                    return;
                  }
                  if (n.length > 30) {
                    st(() => _nameError = 'Максимум 30 символов');
                    return;
                  }
                  setState(() {
                    if (isEdit) {
                      final h = _habits[idx!];
                      h.name = n;
                      h.reminderTime = _pickedTime;
                    } else {
                      _habits.add(
                          Habit(n, reminderTime: _pickedTime));
                    }
                    _sortList();
                  });
                  _save();
                  Navigator.pop(context);
                },
                child: Text(isEdit ? 'Сохранить' : 'Добавить'))
          ],
        ),
      ),
    );
  }

  Widget _card(int i) {
    final h = _habits[i];
    final done = h.isCompletedToday();
    final p = h.getProgressForWeek() / 7;
    final bg = done
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.surfaceVariant;

    final isHover = _hoverIndex == i;

    return MouseRegion(
      onEnter: (_) => setState(() {
        _hoverIndex = i;
      }),
      onExit: (_) => setState(() {
        _hoverIndex = -1;
      }),
      child: Animate(
        effects: [
          FadeEffect(),
          ScaleEffect(curve: Curves.easeOutBack),
          if (isHover)
            MoveEffect(
              duration: 250.ms,
              begin: const Offset(0, 0),
              end: const Offset(0, -5),
              curve: Curves.easeOut,
            ),
        ],
        child: AnimatedContainer(
          duration: 250.ms,
          curve: Curves.easeOut,
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isHover
                ? [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    )
                  ]
                : [],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                h.toggleToday();
              });
              _save();
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(
                        child: Text(
                      h.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    )),
                    if (h.reminderTime != null)
                      Row(children: [
                        const Icon(Icons.alarm, size: 18),
                        const SizedBox(width: 4),
                        Text(h.reminderTime!.format(context)),
                      ])
                  ]),
                  const SizedBox(height: 4), // уменьшенный отступ между заголовком и прогрессом
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: p),
                      duration: 600.ms,
                      builder: (_, v, __) => LinearProgressIndicator(
                        value: v,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade300,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Text('🔥 ${h.getCurrentStreak()} дн.',
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(width: 8),
                    IconButton(
                        icon: Icon(Icons.edit,
                            color: Theme.of(context).colorScheme.primary),
                        onPressed: () => _editAdd(i),
                        splashRadius: 20,
                        padding: EdgeInsets.zero),
                    IconButton(
                        icon: Icon(Icons.delete,
                            color: Theme.of(context).colorScheme.error),
                        onPressed: () {
                          setState(() => _habits.removeAt(i));
                          _save();
                        },
                        splashRadius: 20,
                        padding: EdgeInsets.zero),
                  ])
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _hoverIndex = -1;

  @override
  Widget build(BuildContext c) {
    final w = MediaQuery.of(c).size.width;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final isPhone = w < 600;
    final cols = (w / 300).floor().clamp(1, 4);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          automaticallyImplyLeading: false,
          flexibleSpace: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Первая строка: заголовок слева, кнопки справа
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '📚 Привычки',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              c.readTheme().brightness == Brightness.dark
                                  ? Icons.brightness_7
                                  : Icons.brightness_4,
                            ),
                            onPressed: widget.onToggleTheme,
                            tooltip: 'Сменить тему',
                          ),
                          const SizedBox(width: 4),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Добавить'),
                            onPressed: () => _editAdd(),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),

                  // Вторая строка: дата слева курсивом
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat.yMMMMd().format(DateTime.now()),
                      style: GoogleFonts.poppins(
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Padding(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  child: LayoutBuilder(
    builder: (context, constraints) {
      final isPhone = constraints.maxWidth < 600;
      if (isPhone) {
        return ListView.builder(
          itemCount: _habits.length,
          itemBuilder: (_, i) => SizedBox(height: 120, child: _card(i)),
        );
      } else {
        // На ПК — полоски по несколько в ряд, с max шириной карточки
        const maxCardWidth = 360.0;
        final crossAxisCount = (constraints.maxWidth / (maxCardWidth + 16)).floor();

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 3.5, // полоска (широкая)
          ),
          itemCount: _habits.length,
          itemBuilder: (_, i) => _card(i),
        );
      }
    },
  ),


      ),
      floatingActionButton: null,
    );
  }
}

extension _Ctx on BuildContext {
  ThemeData readTheme() => Theme.of(this);
}
