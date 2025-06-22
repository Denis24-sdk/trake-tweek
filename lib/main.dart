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
  Set<String> completedDates;

  Habit(this.name, {Set<String>? completedDates})
      : completedDates = completedDates ?? {};

  bool isCompletedOn(DateTime date) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    return completedDates.contains(key);
  }

  void toggleOn(DateTime date) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    if (completedDates.contains(key)) {
      completedDates.remove(key);
    } else {
      completedDates.add(key);
    }
  }

  int getCurrentStreak() {
    if (completedDates.isEmpty) return 0;

    DateTime today = DateTime.now();
    int streak = 0;

    while (completedDates.contains(DateFormat('yyyy-MM-dd').format(today))) {
      streak++;
      today = today.subtract(const Duration(days: 1));
    }

    return streak;
  }

  int getBestStreak() {
    if (completedDates.isEmpty) return 0;

    List<String> sortedDates = completedDates.toList()..sort();

    int bestStreak = 0;
    int currentStreak = 1;

    for (int i = 1; i < sortedDates.length; i++) {
      DateTime prev = DateTime.parse(sortedDates[i - 1]);
      DateTime current = DateTime.parse(sortedDates[i]);

      if (current.difference(prev).inDays == 1) {
        currentStreak++;
      } else {
        bestStreak = bestStreak < currentStreak ? currentStreak : bestStreak;
        currentStreak = 1;
      }
    }

    bestStreak = bestStreak < currentStreak ? currentStreak : bestStreak;

    return bestStreak;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'completedDates': completedDates.toList(),
    };
  }

  static Habit fromJson(Map<String, dynamic> json) {
    return Habit(
      json['name'],
      completedDates:
          (json['completedDates'] as List<dynamic>).map((e) => e as String).toSet(),
    );
  }
}

class HabitHomePage extends StatefulWidget {
  const HabitHomePage({super.key});

  @override
  State<HabitHomePage> createState() => _HabitHomePageState();
}

class _HabitHomePageState extends State<HabitHomePage> {
  final List<Habit> _habits = [];
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

    setState(() {
      _habits.insert(0, Habit(text));
    });

    _controller.clear();
    _saveHabits();
  }

  void _toggleHabitOnDate(int habitIndex, DateTime date) {
    setState(() {
      _habits[habitIndex].toggleOn(date);
    });
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
              hintText: 'Например, "Пить воду"',
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

  void _deleteHabit(int index) {
    setState(() {
      _habits.removeAt(index);
    });
    _saveHabits();
  }

  Widget _buildHabitCard(int index) {
    final habit = _habits[index];
    final last7Days = List.generate(
      7,
      (i) => DateTime.now().subtract(Duration(days: 6 - i)),
    );

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  habit.name,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteHabit(index),
                  color: Theme.of(context).colorScheme.error,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('🔥 Стрик: ${habit.getCurrentStreak()}'),
                Text('🏆 Лучший: ${habit.getBestStreak()}'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: last7Days.map((date) {
                final isCompleted = habit.isCompletedOn(date);
                final weekday = DateFormat.E().format(date);

                return Expanded(
                  child: GestureDetector(
                    onTap: () => _toggleHabitOnDate(index, date),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.7)
                            : Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            weekday,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Icon(
                            isCompleted
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 20,
                            color: isCompleted
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
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
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    today,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _habits.isEmpty
                        ? Center(
                            child: Text(
                              'Добавьте свою первую привычку ✨',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          )
                        : ListView.builder(
                            itemCount: _habits.length,
                            itemBuilder: (context, index) =>
                                _buildHabitCard(index),
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
