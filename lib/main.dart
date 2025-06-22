import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reorderables/reorderables.dart';
import 'package:uuid/uuid.dart';

// Helper function to replace withOpacity
Color withCustomOpacity(Color color, double opacity) {
  return color.withAlpha((opacity * color.alpha).round());
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru_RU', null);
  runApp(const HabitTrackerApp());
}

String capitalizeFirstLetter(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}

class HabitTrackerApp extends StatefulWidget {
  const HabitTrackerApp({super.key});
  @override
  State<HabitTrackerApp> createState() => _HabitTrackerAppState();
}

class _HabitTrackerAppState extends State<HabitTrackerApp> {
  String _themeName = 'ocean';
  final Map<String, ThemeData> _themes = {
    'ocean': ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2A9D8F),
        brightness: Brightness.dark,
        primary: const Color(0xFF2A9D8F),
        secondary: const Color(0xFFE76F51),
        surface: const Color(0xFF1D3340),
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: const Color(0xFFE9F1F7),
        displayColor: const Color(0xFFE9F1F7),
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF15202B),
    ),
    'sunset': ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFE76F51),
        brightness: Brightness.dark,
        primary: const Color(0xFFE76F51),
        secondary: const Color(0xFFF4A261),
        surface: const Color(0xFF2A1E2C),
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: const Color(0xFFFDF0E0),
        displayColor: const Color(0xFFFDF0E0),
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF1E1520),
    ),
    'forest': ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2A9D8F),
        brightness: Brightness.dark,
        primary: const Color(0xFF2A9D8F),
        secondary: const Color(0xFFA7C957),
        surface: const Color(0xFF1A2A1D),
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: const Color(0xFFE8F5E9),
        displayColor: const Color(0xFFE8F5E9),
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF121E14),
    ),
    'orchid': ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF9B5DE5),
        brightness: Brightness.dark,
        primary: const Color(0xFF9B5DE5),
        secondary: const Color(0xFFF15BB5),
        surface: const Color(0xFF251A2F),
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: const Color(0xFFF5E6FF),
        displayColor: const Color(0xFFF5E6FF),
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF1A1121),
    ),
  };

  void _changeTheme(String themeName) {
    setState(() => _themeName = themeName);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _themes[_themeName],
      home: HabitHomePage(
        onThemeChanged: _changeTheme,
        currentTheme: _themeName,
        themes: _themes,
      ),
    );
  }
}

class Habit {
  String id;
  String name;
  TimeOfDay? reminderTime;
  DateTime createdAt;
  Set<String> completedDates;
  DateTime? firstActivationDate;
  Color? color;

  Habit(this.name, {
    String? id,
    this.reminderTime,
    DateTime? createdAt,
    Set<String>? completedDates,
    this.firstActivationDate,
    this.color
  }) : id = id ?? const Uuid().v4(),
      createdAt = createdAt ?? DateTime.now(),
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
    'id': id,
    'name': name,
    'reminderTime': reminderTime != null
        ? {'h': reminderTime!.hour, 'm': reminderTime!.minute}
        : null,
    'createdAt': createdAt.toIso8601String(),
    'completedDates': completedDates.toList(),
    'firstActivationDate': firstActivationDate?.toIso8601String(),
    'color': color?.value,
  };
  static Habit fromJson(Map<String, dynamic> j) {
    TimeOfDay? rt;
    if (j['reminderTime'] != null) {
      rt = TimeOfDay(
          hour: j['reminderTime']['h'], minute: j['reminderTime']['m']);
    }
    return Habit(
      j['name'],
      id: j['id'],
      reminderTime: rt,
      createdAt: DateTime.parse(j['createdAt']),
      completedDates: (j['completedDates'] as List)
          .map((e) => e as String)
          .toSet(),
      firstActivationDate: j['firstActivationDate'] != null
          ? DateTime.parse(j['firstActivationDate'])
          : null,
      color: j['color'] != null ? Color(j['color']) : null,
    );
  }
}

class HabitHomePage extends StatefulWidget {
  final Function(String) onThemeChanged;
  final String currentTheme;
  final Map<String, ThemeData> themes;

  const HabitHomePage({
    super.key,
    required this.onThemeChanged,
    required this.currentTheme,
    required this.themes,
  });

  @override
  State<HabitHomePage> createState() => _HabitHomePageState();
}

class _HabitHomePageState extends State<HabitHomePage> {
  final _habits = <Habit>[];
  bool _loading = true;
  final _nameCtrl = TextEditingController();
  TimeOfDay? _pickedTime;
  String? _nameError;
  final _random = Random();
  bool _showSettings = false;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final s = p.getString('habits');
      if (s != null && s.isNotEmpty) {
        try {
          final list = jsonDecode(s) as List;
          _habits.clear();
          for (var item in list) {
            try {
              _habits.add(Habit.fromJson(item));
            } catch (e) {
              debugPrint('Error parsing habit item: $e');
            }
          }
        } catch (e) {
          debugPrint('Error decoding habits JSON: $e');
          await p.remove('habits');
        }
      }
      _sortList();
    } catch (e) {
      debugPrint('Error loading habits: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        'habits', jsonEncode(_habits.map((e) => e.toJson()).toList()));
  }

  void _sortList() {
    _habits.sort((a, b) {
      if (a.reminderTime != null && b.reminderTime != null) {
        final aMinutes = a.reminderTime!.hour * 60 + a.reminderTime!.minute;
        final bMinutes = b.reminderTime!.hour * 60 + b.reminderTime!.minute;
        return aMinutes.compareTo(bMinutes);
      }
      else if (a.reminderTime != null && b.reminderTime == null) {
        return -1;
      }
      else if (a.reminderTime == null && b.reminderTime != null) {
        return 1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  Color _getRandomColor() {
    final colors = [
      const Color(0xFF2A9D8F),
      const Color(0xFFE76F51),
      const Color(0xFFF4A261),
      const Color(0xFF9B5DE5),
      const Color(0xFF00BBF9),
      const Color(0xFFF15BB5),
      const Color(0xFF6A67CE),
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
    ];
    return colors[_random.nextInt(colors.length)];
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (c, st) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEdit ? 'Редактировать привычку' : 'Новая привычка',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameCtrl,
                maxLength: 25,
                style: GoogleFonts.poppins(),
                decoration: InputDecoration(
                  labelText: 'Название привычки',
                  labelStyle: GoogleFonts.poppins(),
                  hintText: 'Бег по утрам',
                  hintStyle: GoogleFonts.poppins(),
                  errorText: _nameError,
                  errorStyle: GoogleFonts.poppins(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  prefixIcon: const Icon(Icons.text_fields),
                  counterText: '',
                ),
                onChanged: (_) {
                  if (_nameError != null) {
                    st(() => _nameError = null);
                  }
                },
              ),
              const SizedBox(height: 15),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(
                  _pickedTime?.format(context) ?? 'Установить напоминание',
                  style: GoogleFonts.poppins(),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => st(() => _pickedTime = null),
                ),
                onTap: () async {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: _pickedTime ?? TimeOfDay.now(),
                  );
                  if (t != null) st(() => _pickedTime = t);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
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
                        _habits.add(Habit(n,
                            reminderTime: _pickedTime,
                            color: _getRandomColor()));
                      }
                      _sortList();
                    });
                    _save();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    isEdit ? 'Сохранить' : 'Создать',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _habitCard(int i) {
    final h = _habits[i];
    return _HabitCard(
      habit: h,
      color: h.color ?? Theme.of(context).colorScheme.primary,
      onToggle: () {
        setState(() {
          h.toggleToday();
          _save();
        });
      },
      onEdit: () => _editAdd(i),
      onDelete: () {
        setState(() {
          _habits.removeAt(i);
          _save();
        });
      },
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.self_improvement,
            size: 100,
            color: withCustomOpacity(
              Theme.of(context).colorScheme.primary,
              0.3
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Пока нет привычек',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Начните добавлять свои привычки для отслеживания',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: withCustomOpacity(
                  Theme.of(context).colorScheme.onSurface,
                  0.7
                ),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Настройки',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Цветовая тема',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: widget.themes.keys.map((themeName) {
              final isActive = widget.currentTheme == themeName;
              return ChoiceChip(
                label: Text(
                  themeName[0].toUpperCase() + themeName.substring(1),
                  style: GoogleFonts.poppins(
                    color: isActive
                        ? widget.themes[themeName]!.colorScheme.onPrimary
                        : widget.themes[themeName]!.colorScheme.onSurface,
                  ),
                ),
                selected: isActive,
                onSelected: (_) => widget.onThemeChanged(themeName),
                backgroundColor: widget.themes[themeName]!.colorScheme.surface,
                selectedColor: widget.themes[themeName]!.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text(
            'Статистика',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _statCard('Привычки', _habits.length.toString()),
              const SizedBox(width: 15),
              _statCard(
                'Выполнено',
                _habits
                    .where((h) => h.isCompletedToday())
                    .length
                    .toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: withCustomOpacity(
                  Theme.of(context).colorScheme.onSurface,
                  0.7
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Заголовок с красивым шрифтом
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical:6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Мои привычки',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!_showSettings)
                        IconButton(
                          icon: const Icon(Icons.add),
                          color: Theme.of(context).colorScheme.onSurface,
                          iconSize: 28,
                          onPressed: () => _editAdd(),
                          tooltip: 'Добавить привычку',
                        ),
                      IconButton(
                        icon: Icon(
                          _showSettings ? Icons.close : Icons.settings,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 28,
                        ),
                        onPressed: () {
                          setState(() => _showSettings = !_showSettings);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    capitalizeFirstLetter(
                      DateFormat('EEEE, d MMMM', 'ru_RU').format(DateTime.now()),
                    ),
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                      color: withCustomOpacity(
                        Theme.of(context).colorScheme.onSurface,
                        0.8
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_habits.where((h) => h.isCompletedToday()).length}/${_habits.length}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _showSettings
                  ? _settingsPanel()
                  : _habits.isEmpty
                      ? _emptyState()
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 600) {
                              return ReorderableWrap(
                                spacing: 20,
                                runSpacing: 20,
                                padding: const EdgeInsets.all(20),
                                buildDraggableFeedback: (context, constraints, child) {
                                  return Transform.scale(
                                    scale: 1.05,
                                    child: Material(
                                      elevation: 8,
                                      borderRadius: BorderRadius.circular(20),
                                      child: child,
                                    ),
                                  );
                                },
                                children: List.generate(_habits.length, (index) {
                                  return SizedBox(
                                    key: ValueKey(_habits[index].id),
                                    width: (constraints.maxWidth - 60) / 2,
                                    child: _HabitCard(
                                      habit: _habits[index],
                                      color: _habits[index].color ?? Theme.of(context).colorScheme.primary,
                                      onToggle: () {
                                        setState(() {
                                          _habits[index].toggleToday();
                                          _save();
                                        });
                                      },
                                      onEdit: () => _editAdd(index),
                                      onDelete: () {
                                        setState(() {
                                          _habits.removeAt(index);
                                          _save();
                                        });
                                      },
                                    ),
                                  );
                                }),
                                onReorder: (oldIndex, newIndex) {
                                  setState(() {
                                    final habit = _habits.removeAt(oldIndex);
                                    _habits.insert(newIndex, habit);
                                    _save();
                                  });
                                },
                              );
                            }
                            else {
                              return ReorderableColumn(
                                scrollController: _scrollController,
                                onReorder: (oldIndex, newIndex) {
                                  setState(() {
                                    if (oldIndex < newIndex) newIndex--;
                                    final habit = _habits.removeAt(oldIndex);
                                    _habits.insert(newIndex, habit);
                                    _save();
                                  });
                                },
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (int i = 0; i < _habits.length; i++)
                                    KeyedSubtree(
                                      key: ValueKey(_habits[i].id),
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            left: 20, right: 20, bottom: 20),
                                        child: _HabitCard(
                                          habit: _habits[i],
                                          color: _habits[i].color ?? Theme.of(context).colorScheme.primary,
                                          onToggle: () {
                                            setState(() {
                                              _habits[i].toggleToday();
                                              _save();
                                            });
                                          },
                                          onEdit: () => _editAdd(i),
                                          onDelete: () {
                                            setState(() {
                                              _habits.removeAt(i);
                                              _save();
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            }
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitCard extends StatefulWidget {
  final Habit habit;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Color color;
  const _HabitCard({
    required this.habit,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.color,
  });
  @override
  _HabitCardState createState() => _HabitCardState();
}

class _HabitCardState extends State<_HabitCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final h = widget.habit;
    final done = h.isCompletedToday();
    final progress = h.getProgressForWeek();
    final streak = h.getCurrentStreak();
    final color = widget.color;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onToggle,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Animate(
          effects: [
            ScaleEffect(
              duration: 300.ms,
              curve: Curves.easeOutBack,
              begin: const Offset(0.95, 0.95),
              end: const Offset(1, 1),
            ),
            if (_hovered)
              ShakeEffect(
                hz: 3,
                duration: 300.ms,
                curve: Curves.easeInOut,
              ),
          ],
          child: Card(
            elevation: _hovered ? 8 : 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    withCustomOpacity(color, 0.15),
                    withCustomOpacity(color, 0.05),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                h.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: CircularProgressIndicator(
                                    value: progress / 7,
                                    strokeWidth: 8,
                                    backgroundColor: withCustomOpacity(
                                      Theme.of(context).colorScheme.onSurface,
                                      0.1
                                    ),
                                    color: color,
                                  ),
                                ),
                                Text(
                                  '$progress/7',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.local_fire_department,
                                        size: 18, color: Colors.orange),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Серия: $streak дней',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Создано: ${DateFormat("dd.MM.yyyy").format(h.createdAt)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: withCustomOpacity(
                                      Theme.of(context).colorScheme.onSurface,
                                      0.7
                                    ),
                                  ),
                                )],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (h.reminderTime != null)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: withCustomOpacity(
                            Theme.of(context).colorScheme.secondary,
                            0.2
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time,
                                size: 14,
                                color: Theme.of(context).colorScheme.onSurface),
                            const SizedBox(width: 4),
                            Text(
                              h.reminderTime!.format(context),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit,
                              color: Theme.of(context).colorScheme.onSurface),
                          onPressed: widget.onEdit,
                          tooltip: 'Редактировать',
                        ),
                        IconButton(
                          icon: Icon(Icons.delete,
                              color: Theme.of(context).colorScheme.error),
                          onPressed: widget.onDelete,
                          tooltip: 'Удалить',
                        ),
                      ],
                    ),
                  ),
                  if (done)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                        child: const Icon(Icons.check, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}