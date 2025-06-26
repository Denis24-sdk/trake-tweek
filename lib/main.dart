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
import 'dart:io' show Platform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';

// Helper function to replace withOpacity
Color withCustomOpacity(Color color, double opacity) {
  return color.withAlpha((opacity * color.alpha).round());
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru_RU', null);
  tz.initializeTimeZones();

  if (Platform.isAndroid || Platform.isIOS) {
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  } else {
    tz.setLocalLocation(tz.local);
  }

  runApp(const HabitTrackerApp());
}

class HabitTrackerApp extends StatefulWidget {
  const HabitTrackerApp({super.key});
  @override
  State<HabitTrackerApp> createState() => _HabitTrackerAppState();
}

class _HabitTrackerAppState extends State<HabitTrackerApp> {
  String _themeName = 'serene';
  final Map<String, ThemeData> _themes = {
    'serene': ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6C5CE7),
        brightness: Brightness.dark,
        primary: const Color(0xFF6C5CE7),
        secondary: const Color(0xFF00CEC9),
        surface: const Color(0xFF2D3436),
        background: const Color(0xFF1E272E),
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: const Color(0xFFF5F6FA),
        displayColor: const Color(0xFFF5F6FA),
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF1E272E),
    ),
    'sunset': ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFE17055),
        brightness: Brightness.dark,
        primary: const Color(0xFFE17055),
        secondary: const Color(0xFFFDCB6E),
        surface: const Color(0xFF2D3436),
        background: const Color(0xFF1E272E),
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: const Color(0xFFF5F6FA),
        displayColor: const Color(0xFFF5F6FA),
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF1E272E),
    ),
    'ocean': ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0984E3),
        brightness: Brightness.dark,
        primary: const Color(0xFF0984E3),
        secondary: const Color(0xFF00CEC9),
        surface: const Color(0xFF2D3436),
        background: const Color(0xFF1E272E),
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: const Color(0xFFF5F6FA),
        displayColor: const Color(0xFFF5F6FA),
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF1E272E),
    ),
    'forest': ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF00B894),
        brightness: Brightness.dark,
        primary: const Color(0xFF00B894),
        secondary: const Color(0xFF55EFC4),
        surface: const Color(0xFF2D3436),
        background: const Color(0xFF1E272E),
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: const Color(0xFFF5F6FA),
        displayColor: const Color(0xFFF5F6FA),
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF1E272E),
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
  String? emoji;

  Habit(this.name, {
    String? id,
    this.reminderTime,
    DateTime? createdAt,
    Set<String>? completedDates,
    this.firstActivationDate,
    this.color,
    this.emoji,
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
    'emoji': emoji,
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
      emoji: j['emoji'],
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
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final AndroidNotificationChannel _channel = const AndroidNotificationChannel(
    'habit_reminder_channel',
    'Habit Reminders',
    description: 'Уведомления о ваших привычках',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('notification'),
    enableVibration: true,
  );

  // Список доступных эмодзи для привычек
  final List<String> _availableEmojis = [
    '🏃', '📖', '💧', '🍎', '🏋️', '🧘', '🚭', '🛌', '🧠', '✍️',
    '🎯', '🌱', '☀️', '🌙', '🧹', '🚿', '🍏', '🥗', '🚶', '💪'
  ];
  String? _selectedEmoji;

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _load();
  }

  Future<void> _initNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {},
    );

    if (Platform.isAndroid) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }

    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    } else if (Platform.isAndroid) {
      await Permission.notification.request();
    }
  }

  Future<void> _scheduleNotification(Habit habit) async {
    if (habit.reminderTime == null) {
      debugPrint('Отменяем уведомление для ${habit.name}');
      await flutterLocalNotificationsPlugin.cancel(habit.id.hashCode);
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      habit.reminderTime!.hour,
      habit.reminderTime!.minute,
    );

    final notifyTime = scheduledDate.isBefore(now)
        ? scheduledDate.add(const Duration(days: 1))
        : scheduledDate;

    debugPrint('Планируем уведомление для ${habit.name} на $notifyTime');

    await flutterLocalNotificationsPlugin.cancel(habit.id.hashCode);

    final androidDetails = AndroidNotificationDetails(
      'habit_reminder_channel',
      'Habit Reminders',
      channelDescription: 'Уведомления о ваших привычках',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    final iosDetails = DarwinNotificationDetails();

    final notificationDetails =
    NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        habit.id.hashCode,
        'Напоминание о привычке',
        habit.name,
        notifyTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      if (e.toString().contains('exact_alarms_not_permitted')) {
        _showExactAlarmDialog();
      } else {
        rethrow;
      }
    }
  }

  void _showExactAlarmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Требуется разрешение'),
        content: const Text(
          'Для корректной работы уведомлений требуется разрешение на точные будильники. Перейдите в настройки и включите разрешение.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _openExactAlarmSettings();
            },
            child: const Text('Открыть настройки'),
          ),
        ],
      ),
    );
  }

  void _openExactAlarmSettings() {
    if (!Platform.isAndroid) return;

    final intent = AndroidIntent(action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM');
    intent.launch();
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final s = p.getString('habits');
      if (s != null && s.isNotEmpty) {
        final list = jsonDecode(s) as List;
        _habits.clear();
        for (var item in list) {
          try {
            _habits.add(Habit.fromJson(item));
          } catch (e) {
            debugPrint('Error parsing habit item: $e');
          }
        }
      }
      _sortList();
    } catch (e) {
      debugPrint('Error loading habits: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
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
      } else if (a.reminderTime != null && b.reminderTime == null) {
        return -1;
      } else if (a.reminderTime == null && b.reminderTime != null) {
        return 1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  Color _getRandomColor() {
    final colors = [
      const Color(0xFF6C5CE7),
      const Color(0xFF00CEC9),
      const Color(0xFFE17055),
      const Color(0xFFFDCB6E),
      const Color(0xFF0984E3),
      const Color(0xFF00B894),
      const Color(0xFF55EFC4),
      const Color(0xFFA29BFE),
      const Color(0xFFFD79A8),
    ];
    return colors[_random.nextInt(colors.length)];
  }

  void _editHabit(int index) {
    final habit = _habits[index];


    final nameController = TextEditingController(text: habit.name);
    TimeOfDay? currentReminderTime = habit.reminderTime;
    String? currentEmoji = habit.emoji;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Container(
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
                'Редактировать привычку',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),

              // Поле ввода названия
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Название привычки',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.edit),
                ),
              ),
              const SizedBox(height: 16),

              // Выбор времени
              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(currentReminderTime?.format(context) ?? 'Добавить напоминание'),
                trailing: currentReminderTime != null
                    ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setModalState(() {
                    currentReminderTime = null;
                  }),
                )
                    : null,
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: currentReminderTime ?? TimeOfDay.now(),
                  );
                  if (time != null) {
                    setModalState(() {
                      currentReminderTime = time;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Кнопки действий
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        if (nameController.text.trim().isEmpty) return;

                        setState(() {
                          habit.name = nameController.text.trim();
                          habit.reminderTime = currentReminderTime;
                          habit.emoji = currentEmoji;
                          _save();
                          _scheduleNotification(habit);
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Сохранить'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }


  void _deleteHabit(int index) {
    final habit = _habits[index];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить привычку?'),
        content: Text('Вы точно хотите удалить привычку "${habit.name}"?'),
        actions: [
          // Кнопка отмены
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Отмена',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),

          // Кнопка удаления
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Закрыть диалог
              setState(() {
                _habits.removeAt(index);
                _save();
                // Отменить уведомление
                flutterLocalNotificationsPlugin.cancel(habit.id.hashCode);
              });

              // Показать подтверждение удаления
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Привычка "${habit.name}" удалена'),
                  action: SnackBarAction(
                    label: 'Отменить',
                    onPressed: () {
                      setState(() {
                        _habits.insert(index, habit);
                        _save();
                        if (habit.reminderTime != null) {
                          _scheduleNotification(habit);
                        }
                      });
                    },
                  ),
                ),
              );
            },
            child: Text(
              'Удалить',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editAdd([int? idx]) {
    final isEdit = idx != null;
    if (isEdit) {
      final h = _habits[idx];
      _nameCtrl.text = h.name;
      _pickedTime = h.reminderTime;
      _selectedEmoji = h.emoji;
    } else {
      _nameCtrl.clear();
      _pickedTime = null;
      _selectedEmoji = _availableEmojis[_random.nextInt(_availableEmojis.length)];
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              )
            ],
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

              // Эмоджи пикер
              SizedBox(
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _availableEmojis.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) => GestureDetector(
                    onTap: () => st(() => _selectedEmoji = _availableEmojis[i]),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _selectedEmoji == _availableEmojis[i]
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                            : Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          _availableEmojis[i],
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),

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
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.text_fields),
                  counterText: '',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceVariant,
                ),
                onChanged: (_) {
                  if (_nameError != null) {
                    st(() => _nameError = null);
                  }
                },
              ),
              const SizedBox(height: 15),

              // Время напоминания
              Material(
                borderRadius: BorderRadius.circular(16),
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: _pickedTime ?? TimeOfDay.now(),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: Theme.of(context).colorScheme.primary,
                            onPrimary: Theme.of(context).colorScheme.onPrimary,
                            surface: Theme.of(context).colorScheme.surface,
                            onSurface: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (t != null) st(() => _pickedTime = t);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time,
                            color: Theme.of(context).colorScheme.onSurface),
                        const SizedBox(width: 12),
                        Text(
                          _pickedTime != null
                              ? _pickedTime!.format(context)
                              : 'Установить напоминание',
                          style: GoogleFonts.poppins(),
                        ),
                        const Spacer(),
                        if (_pickedTime != null)
                          IconButton(
                            icon: Icon(Icons.clear,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                            onPressed: () => st(() => _pickedTime = null),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Кнопка сохранения
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
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
                        final h = _habits[idx];
                        h.name = n;
                        h.reminderTime = _pickedTime;
                        h.emoji = _selectedEmoji;
                      } else {
                        _habits.add(Habit(
                          n,
                          reminderTime: _pickedTime,
                          color: _getRandomColor(),
                          emoji: _selectedEmoji,
                        ));
                      }
                      _sortList();
                    });
                    await _save();

                    final habit = isEdit ? _habits[idx!] : _habits.last;
                    await _scheduleNotification(habit);

                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                  child: Text(
                    isEdit ? 'Сохранить изменения' : 'Создать привычку',
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
          const SizedBox(height: 24),
          Text(
            'Начните свой путь к успеху',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Добавьте свою первую привычку и начните отслеживать прогресс',
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
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            height: 50,
            child: ElevatedButton(
              onPressed: () => _editAdd(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Text(
                'Добавить привычку',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsPanel() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок с кнопкой назад
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back,
                    color: theme.colorScheme.onSurface),
                onPressed: () => setState(() => _showSettings = false),
                splashRadius: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Настройки',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Секция тем
          _SectionHeader(
            title: 'Цветовая тема',
            icon: Icons.palette_outlined,
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 0.9,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: widget.themes.keys.map((themeName) {
              final themeData = widget.themes[themeName]!;
              final isActive = widget.currentTheme == themeName;

              return ThemeSelectionCard(
                themeName: themeName,
                isActive: isActive,
                color: themeData.colorScheme.primary,
                onTap: () => widget.onThemeChanged(themeName),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Секция статистики
          _SectionHeader(
            title: 'Ваша статистика',
            icon: Icons.insights_outlined,
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _StatCard(
                title: 'Привычек',
                value: _habits.length.toString(),
                icon: Icons.list_alt_outlined,
                color: Colors.blue,
              ),
              _StatCard(
                title: 'Сегодня',
                value: '${_habits.where((h) => h.isCompletedToday()).length}/${_habits.length}',
                icon: Icons.today_outlined,
                color: Colors.green,
              ),
              _StatCard(
                title: 'Лучшая серия',
                value: _habits.isNotEmpty
                    ? _habits.map((h) => h.getCurrentStreak()).reduce(max).toString()
                    : '0',
                icon: Icons.local_fire_department_outlined,
                color: Colors.orange,
              ),
              _StatCard(
                title: 'Уведомления',
                value: _habits.where((h) => h.reminderTime != null).length.toString(),
                icon: Icons.notifications_active_outlined,
                color: Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Секция информации
          _SectionHeader(
            title: 'О приложении',
            icon: Icons.info_outline,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          "TT",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Trake-Tweek',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _InfoRow(
                  icon: Icons.verified_user_outlined,
                  text: 'Версия 1.0.0',
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.update_outlined,
                  text: 'Последнее обновление: 26.06.2025',
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.favorite_outline,
                  text: 'Разработано с ❤️ для ваших привычек',
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                    ),
                    child: Text(
                      'Политика конфиденциальности',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }



  Widget _statCard(String title, String value, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
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

    final today = capitalizeFirstLetter(
        DateFormat('EEEE, d MMMM', 'ru_RU').format(DateTime.now())
    );

    final completedCount = _habits.where((h) => h.isCompletedToday()).length;
    final totalCount = _habits.length;
    final completionPercentage = totalCount > 0
        ? (completedCount / totalCount * 100).round()
        : 0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Верхняя панель с заголовком и кнопками
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Мои привычки',
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            today,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),

                      // Кнопки действий
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!_showSettings)
                            IconButton(
                              onPressed: () => _editAdd(),
                              icon: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.add,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            ),

                          const SizedBox(width: 8),

                          IconButton(
                            onPressed: () => setState(() => _showSettings = !_showSettings),
                            icon: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _showSettings
                                    ? Theme.of(context).colorScheme.secondary
                                    : Theme.of(context).colorScheme.surfaceVariant,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _showSettings ? Icons.close : Icons.settings,
                                color: _showSettings
                                    ? Theme.of(context).colorScheme.onSecondary
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Прогресс бар
                  if (!_showSettings && _habits.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Прогресс сегодня',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              '$completedCount/$totalCount ($completionPercentage%)',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: totalCount > 0 ? completedCount / totalCount : 0,
                          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                          color: Theme.of(context).colorScheme.primary,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Основной контент
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _showSettings
                    ? _settingsPanel()
                    : _habits.isEmpty
                    ? _emptyState()
                    : ReorderableColumn(
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
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: _HabitCard(
                            habit: _habits[i],
                            color: _habits[i].color ?? Theme.of(context).colorScheme.primary,
                            onToggle: () {
                              setState(() {
                                _habits[i].toggleToday();
                                _save();
                              });
                            },
                            onEdit: () => _editHabit(i),
                            onDelete: () => _deleteHabit(i),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String capitalizeFirstLetter(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}

class _HabitCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final done = habit.isCompletedToday();
    final progress = habit.getProgressForWeek();
    final streak = habit.getCurrentStreak();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: theme.colorScheme.surfaceContainerHighest,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Progress background
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: MediaQuery.of(context).size.width * (progress / 7) * 0.9,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      color.withOpacity(isDark ? 0.2 : 0.15),
                      color.withOpacity(0.01),
                    ],
                  ),
                ),
              ),
            ),

            Column(
              children: [
                // Main content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Emoji
                          if (habit.emoji != null)
                            Container(
                              margin: const EdgeInsets.only(right: 12),
                              child: Text(
                                habit.emoji!,
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),

                          // Title and stats
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title
                                Text(
                                  habit.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                // Stats row
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    children: [
                                      // Streak
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.local_fire_department,
                                            size: 16,
                                            color: streak > 0
                                                ? Colors.orange
                                                : theme.colorScheme.outline,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            streak > 0 ? '$streak' : '0',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: streak > 0
                                                  ? Colors.orange
                                                  : theme.colorScheme.outline,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(width: 12),

                                      // Progress
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.timeline,
                                            size: 16,
                                            color: theme.colorScheme.primary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$progress/7',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),

                                      if (habit.reminderTime != null) ...[
                                        const SizedBox(width: 12),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.access_time,
                                              size: 14,
                                              color: theme.colorScheme.outline,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              habit.reminderTime!.format(context),
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: theme.colorScheme.outline,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Creation date
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Создано: ${DateFormat("dd.MM.yy").format(habit.createdAt)}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Action buttons bar
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _BottomActionButton(
                        icon: Icons.edit_outlined,
                        label: 'Изменить',
                        onPressed: onEdit,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      _BottomActionButton(
                        icon: Icons.bar_chart,
                        label: 'Статистика',
                        onPressed: () {}, // Placeholder
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      _BottomActionButton(
                        icon: Icons.delete_outline,
                        label: 'Удалить',
                        onPressed: onDelete,
                        color: theme.colorScheme.error,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (done)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}



class _BottomActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const _BottomActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: EdgeInsets.zero,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}


// Вспомогательные виджеты
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 24,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class ThemeSelectionCard extends StatelessWidget {
  final String themeName;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const ThemeSelectionCard({
    required this.themeName,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isActive
              ? color.withOpacity(0.1)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? color : theme.colorScheme.outlineVariant,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              themeName[0].toUpperCase() + themeName.substring(1),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (isActive) ...[
              const SizedBox(height: 8),
              Icon(
                Icons.check_circle,
                size: 20,
                color: color,
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 24,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }
}