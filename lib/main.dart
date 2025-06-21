import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const HabitTrackerApp());
}

class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData.dark().textTheme,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const HabitHomePage(),
    );
  }
}

class Habit {
  String name;
  Set<String> completedDates; // даты в формате 'yyyy-MM-dd'

  Habit(this.name, {Set<String>? completedDates})
      : completedDates = completedDates ?? {};

  bool isCompletedToday() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return completedDates.contains(today);
  }

  void toggleToday() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (completedDates.contains(today)) {
      completedDates.remove(today);
    } else {
      completedDates.add(today);
    }
  }

  // Серилизация в JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'completedDates': completedDates.toList(),
    };
  }

  static Habit fromJson(Map<String, dynamic> json) {
    return Habit(
      json['name'],
      completedDates: (json['completedDates'] as List<dynamic>)
          .map((e) => e as String)
          .toSet(),
    );
  }

  // Подсчёт количества дней подряд
  int getStreak() {
    if (completedDates.isEmpty) return 0;

    var dates = completedDates.toList()
      ..sort((a, b) => b.compareTo(a)); // сортируем от новейшей даты

    DateTime today = DateTime.now();
    int streak = 0;

    for (int i = 0; i < dates.length; i++) {
      DateTime date = DateTime.parse(dates[i]);
      Duration diff = today.difference(date);
      if (diff.inDays == streak) {
        streak++;
      } else if (diff.inDays > streak) {
        break;
      }
    }
    return streak;
  }
}

class HabitHomePage extends StatefulWidget {
  const HabitHomePage({super.key});

  @override
  State<HabitHomePage> createState() => _HabitHomePageState();
}

class _HabitHomePageState extends State<HabitHomePage> {
  final List<Habit> _habits = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();

  final TextEditingController _controller = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('habits');

    if (data != null) {
      final List<dynamic> jsonList = jsonDecode(data);
      _habits.clear();
      _habits.addAll(jsonList.map((e) => Habit.fromJson(e)).toList());
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonList =
        _habits.map((e) => e.toJson()).toList();
    prefs.setString('habits', jsonEncode(jsonList));
  }

  void _addHabit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final newHabit = Habit(text);
    setState(() {
      _habits.insert(0, newHabit);
      _listKey.currentState
          ?.insertItem(0, duration: const Duration(milliseconds: 300));
    });

    _controller.clear();
    _saveHabits();
  }

  void _toggleHabit(int index) {
    setState(() {
      _habits[index].toggleToday();
    });
    _saveHabits();
  }

  void _removeHabit(int index) {
    final removedHabit = _habits.removeAt(index);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildHabitItem(removedHabit, index, animation),
      duration: const Duration(milliseconds: 300),
    );
    _saveHabits();
  }

  void _showAddHabitDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Добавить привычку'),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Например, "Утренняя зарядка"',
            ),
            autofocus: true,
            onSubmitted: (_) {
              _addHabit();
              Navigator.of(context).pop();
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _controller.clear();
              },
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                _addHabit();
                Navigator.of(context).pop();
              },
              child: const Text('Добавить'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirm(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить привычку?'),
        content:
            Text('Вы уверены, что хотите удалить "${_habits[index].name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removeHabit(index);
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitItem(Habit habit, int index, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        color: habit.isCompletedToday()
            ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
            : Theme.of(context).colorScheme.surfaceVariant,
        child: ListTile(
          leading: IconButton(
            iconSize: 32,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: habit.isCompletedToday()
                  ? Icon(
                      Icons.check_circle,
                      key: const ValueKey('checked'),
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : Icon(
                      Icons.circle_outlined,
                      key: const ValueKey('unchecked'),
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
            ),
            onPressed: () => _toggleHabit(index),
          ),
          title: Text(
            habit.name,
            style: TextStyle(
              decoration: habit.isCompletedToday()
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            'Дней подряд: ${habit.getStreak()}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
            ),
          ),
          trailing: IconButton(
            icon: Icon(Icons.delete_outline,
                color: Theme.of(context).colorScheme.error),
            onPressed: () => _showDeleteConfirm(index),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat.yMMMMEEEEd().format(DateTime.now());
    return Scaffold(
      appBar: AppBar(
        title: const Text('📚 Мои Привычки'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    today,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _habits.isEmpty
                        ? Center(
                            child: Text(
                              'Добавь свою первую привычку ✨',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          )
                        : AnimatedList(
                            key: _listKey,
                            initialItemCount: _habits.length,
                            itemBuilder: (context, index, animation) {
                              final habit = _habits[index];
                              return _buildHabitItem(habit, index, animation);
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddHabitDialog,
        icon: const Icon(Icons.add),
        label: const Text('Добавить привычку'),
      ),
    );
  }
}
