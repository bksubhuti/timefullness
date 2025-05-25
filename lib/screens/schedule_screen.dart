// schedule_screet.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:my_time_schedule/models/prefs.dart';
import 'package:my_time_schedule/plugin.dart';
import 'package:my_time_schedule/screens/settings_screen.dart';
import 'package:my_time_schedule/services/hive_schedule_repository.dart';
import 'package:my_time_schedule/services/notification_service.dart';
import 'package:my_time_schedule/widgets/duration_dial.dart';
import 'package:my_time_schedule/widgets/solid_visual_timer.dart';
import '../models/schedule_item.dart';
import '../widgets/schedule_tile.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:my_time_schedule/services/example_includes.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  List<ScheduleItem> schedule = [];
  TimeOfDay? selectedStartTime;
  int durationMinutes = 50; // Default duration of 30 minutes
  final _activityController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isDefaultScheduleLoaded = false;
  late final HiveScheduleRepository scheduleRepo;
  static const String defaultScheduleId = 'default';
  int _activeDuration = 0;
  int _remainingSeconds = 0;
  Timer? _countdownTimer;
  bool _timerVisible = false;
  DateTime? _destinationTime;
  Timer? _updateTimer;

  // eample stuff
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    final box = Hive.box('schedules');
    scheduleRepo = HiveScheduleRepository(box);
    _loadSchedule();

    _isAndroidPermissionGranted();
    _requestPermissions();

    _resumeVisualTimerIfNeeded();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    selectNotificationStream.close();

    super.dispose();
  }

  Future<void> _isAndroidPermissionGranted() async {
    if (Platform.isAndroid) {
      final bool granted =
          await flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.areNotificationsEnabled() ??
          false;

      setState(() {
        _notificationsEnabled = granted;
      });
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS || Platform.isMacOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      final bool? grantedNotificationPermission =
          await androidImplementation?.requestNotificationsPermission();
      setState(() {
        _notificationsEnabled = grantedNotificationPermission ?? false;
      });
    }
  }

  Future<void> _requestPermissionsWithCriticalAlert() async {
    if (Platform.isIOS || Platform.isMacOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            critical: true,
          );
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            critical: true,
          );
    }
  }

  Future<void> _requestNotificationPolicyAccess() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    await androidImplementation?.requestNotificationPolicyAccess();
  }

  Future<void> _zonedScheduleNotification(Duration duration) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'My Time Schedule',
      'Your session has ended.',
      tz.TZDateTime.now(tz.local).add(duration),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'my_time_schedule_channel',
          'My Time Schedule Timer',
          channelDescription:
              'Notifications for your My Time Schedule timer sessions.',
          sound: RawResourceAndroidNotificationSound('bell'),
          playSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> _zonedScheduleAlarmClockNotification() async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      123,
      'scheduled alarm clock title',
      'scheduled alarm clock body',
      tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'alarm_clock_channel',
          'Alarm Clock Channel',
          channelDescription: 'Alarm Clock Notification',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.alarmClock,
    );
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dt); // e.g., 6:30 AM
  }

  TimeOfDay _addDurationToTime(TimeOfDay startTime, int durationMinutes) {
    int totalMinutes = startTime.hour * 60 + startTime.minute + durationMinutes;
    int newHour = (totalMinutes ~/ 60) % 24;
    int newMinute = totalMinutes % 60;
    return TimeOfDay(hour: newHour, minute: newMinute);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedStartTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        selectedStartTime = picked;
      });
    }
  }

  Future<void> _saveSchedule() async {
    final activeId = Prefs.currentScheduleId;
    await scheduleRepo.saveSchedule(activeId, schedule);
  }

  Future<void> _loadSchedule() async {
    final items = await scheduleRepo.loadSchedule(Prefs.currentScheduleId);
    if (items.isEmpty) {
      debugPrint(
        "📭 No items found for schedule '${Prefs.currentScheduleId}', loading default...",
      );
      await _loadDefaultSchedule();
      return;
    }

    setState(() {
      schedule = items;
    });

    await _checkForMidnightReset();
  }

  Future<void> _loadDefaultSchedule() async {
    try {
      // Load CSV file from assets
      final String csvString = await rootBundle.loadString(
        'assets/daily schedule - Sheet1.csv',
      );
      debugPrint("📄 CSV raw content:\n$csvString");

      // Parse CSV
      List<List<dynamic>> csvTable = const CsvToListConverter().convert(
        csvString,
      );

      // Skip header row
      if (csvTable.length > 1) {
        // Start from index 1 to skip header
        // 🟢 Replace with mapped parsing from CSV header
        final headers = csvTable.first.cast<String>(); // 🟢
        final rows = csvTable.skip(1); // 🟢

        final defaultSchedule =
            rows.map((row) {
              // 🟢
              final map = Map<String, dynamic>.fromIterables(
                headers,
                row,
              ); // 🟢
              return ScheduleItem.fromCsv(map); // 🟢
            }).toList();
        setState(() {
          schedule = defaultSchedule;
          _isDefaultScheduleLoaded = true;
          _sortScheduleByTime();
        });

        // Save the default schedule
        await _saveSchedule();
      }
    } catch (e) {
      debugPrint('Error loading default schedule: $e');
    }
  }

  void _addScheduleItem() {
    if (selectedStartTime == null || _activityController.text.isEmpty) return;

    // Calculate end time based on start time and duration
    final endTime = _addDurationToTime(selectedStartTime!, durationMinutes);

    setState(() {
      schedule.add(
        ScheduleItem(
          id: UniqueKey().toString(),
          startTime: _formatTime(selectedStartTime!),
          endTime: _formatTime(endTime),
          activity: _activityController.text,
          checkedAt: DateTime.fromMillisecondsSinceEpoch(0),
        ),
      );
      _sortScheduleByTime();
    });
    _saveSchedule();
    _activityController.clear();
    selectedStartTime = null;
    Navigator.of(context).pop();
  }

  void _updateScheduleItem(int index) {
    if (selectedStartTime == null || _activityController.text.isEmpty) return;

    // Calculate end time based on start time and duration
    final endTime = _addDurationToTime(selectedStartTime!, durationMinutes);

    setState(() {
      schedule[index] = ScheduleItem(
        id: schedule[index].id,
        startTime: _formatTime(selectedStartTime!),
        endTime: _formatTime(endTime),
        activity: _activityController.text,
        done: schedule[index].done,
        checkedAt: schedule[index].checkedAt,
      );
      _sortScheduleByTime();
    });
    _saveSchedule();
    _activityController.clear();
    selectedStartTime = null;
    Navigator.of(context).pop();
  }

  Future<void> _playBellSound({bool timer = false}) async {
    String soundFile =
        timer ? 'bell-meditation-75335.mp3' : 'bell-meditation-trim.mp3';

    try {
      final player = AudioPlayer(); // Create a fresh instance each time
      await player.play(AssetSource(soundFile));
      // Dispose after sound finishes (non-blocking)
      player.onPlayerComplete.listen((event) {
        player.dispose();
      });
    } catch (e) {
      debugPrint('Error playing bell sound: $e');
    }
  }

  void _updateItem(int index, bool? value) {
    final bool newValue = value ?? false;

    setState(() {
      schedule[index].done = newValue;
      schedule[index].checkedAt =
          newValue ? DateTime.now() : DateTime.fromMillisecondsSinceEpoch(0);
    });

    // Play bell sound when item is checked (marked as done)
    if (newValue) {
      _playBellSound();
    }

    _saveSchedule();
  }

  void _deleteItem(int index) {
    setState(() {
      schedule.removeAt(index);
    });
    _saveSchedule();
  }

  void _sortScheduleByTime() {
    final format = DateFormat('h:mm a', 'en_US');
    schedule.sort((a, b) {
      try {
        final aTime = format.parseStrict(_cleanTime(a.startTime));
        final bTime = format.parseStrict(_cleanTime(b.startTime));
        return aTime.compareTo(bTime);
      } catch (e) {
        debugPrint('❌ Error parsing time during sort: $e');
        return 0;
      }
    });
  }

  Future<void> _startVisualTimer(int index) async {
    final item = schedule[index];
    final format = DateFormat('h:mm a', 'en_US');

    try {
      final start = format.parse(_cleanTime(item.startTime));
      final end = format.parse(_cleanTime(item.endTime));
      final duration = end.difference(start);

      final now = DateTime.now();
      final destination = now.add(duration);

      Prefs.destinationTime = _destinationTime = destination;
      WakelockPlus.enable();

      //for testing
      //_destinationTime = DateTime.now().add(const Duration(seconds: 10));
      /*      await notificationService.scheduleNotification(
        id: 1,
        title: 'My Time Schedule',
        body: '⏰ Your session is complete.',
        scheduledDateTime: _destinationTime!,
      );
      */
      // TESTING
      //_zonedScheduleNotification(Duration(seconds: 8));
      ///////////////////////////////////////////////////////////////

      //Platform.isAndroid
      _zonedScheduleNotification(duration);
      _updateTimer?.cancel();
      _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        final now = DateTime.now();
        final remaining = _destinationTime!.difference(now).inSeconds;

        if (remaining <= 0) {
          _stopVisualTimer();
          _playBellSound();
          WakelockPlus.disable();
        } else {
          setState(() {
            _remainingSeconds = remaining;
            _activeDuration = duration.inSeconds;
            Prefs.activeTimerDuration = _activeDuration;
            _timerVisible = true;
          });
        }
      });

      setState(() {
        _remainingSeconds = duration.inSeconds;
        _activeDuration = duration.inSeconds;
        _timerVisible = true;
      });
    } catch (e) {
      debugPrint('❌ Could not start visual timer: $e');
      if (await WakelockPlus.enabled) WakelockPlus.disable();
    }
  }

  void _stopVisualTimer() async {
    _updateTimer?.cancel();
    Prefs.destinationTime = _destinationTime = null;
    WakelockPlus.disable();
    //    await notificationService.cancelNotification(1);
    //await _cancelNotification();
    setState(() => _timerVisible = false);
  }

  Future<void> _cancelNotification() async {
    await flutterLocalNotificationsPlugin.cancel(--id);
  }

  Future<void> _cancelNotificationWithTag() async {
    await flutterLocalNotificationsPlugin.cancel(--id, tag: 'tag');
  }

  Future<void> _cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> _showProgressNotification(Duration duration) async {
    id++;
    final int progressId = id;
    const int maxProgress = 5;
    for (int i = 0; i <= maxProgress; i++) {
      await Future<void>.delayed(duration, () async {
        final AndroidNotificationDetails androidNotificationDetails =
            AndroidNotificationDetails(
              'progress channel',
              'progress channel',
              channelDescription: 'progress channel description',
              channelShowBadge: false,
              importance: Importance.max,
              priority: Priority.high,
              onlyAlertOnce: true,
              showProgress: true,
              maxProgress: maxProgress,
              progress: i,
            );
        final NotificationDetails notificationDetails = NotificationDetails(
          android: androidNotificationDetails,
        );
        await flutterLocalNotificationsPlugin.show(
          progressId,
          'progress notification title',
          'progress notification body',
          notificationDetails,
          payload: 'item x',
        );
      });
    }
  }

  Future<void> _showIndeterminateProgressNotification() async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'indeterminate progress channel',
          'indeterminate progress channel',
          channelDescription: 'indeterminate progress channel description',
          channelShowBadge: false,
          importance: Importance.max,
          priority: Priority.high,
          onlyAlertOnce: true,
          showProgress: true,
          indeterminate: true,
        );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );
    await flutterLocalNotificationsPlugin.show(
      id++,
      'indeterminate progress notification title',
      'indeterminate progress notification body',
      notificationDetails,
      payload: 'item x',
    );
  }

  Future<void> _checkForMidnightReset() async {
    final prefs = await SharedPreferences.getInstance();
    final lastResetDate = prefs.getString('lastResetDate');
    final today = DateTime.now().toIso8601String().substring(
      0,
      10,
    ); // 'YYYY-MM-DD'

    if (lastResetDate != today) {
      debugPrint("🌅 New day detected, resetting schedule");
      setState(() {
        for (var item in schedule) {
          item.done = false;
        }
      });
      await prefs.setString('lastResetDate', today);
      await _saveSchedule();
    }
  }

  String _cleanTime(String time) {
    return time
        .replaceAll(RegExp(r'[\u202F\u00A0]'), ' ') // Convert NBSP to space
        .replaceFirstMapped(
          RegExp(r'^(\d):'),
          (m) => '0${m[1]}:',
        ) // Add leading zero
        .trim();
  }

  void _editItem(int index) {
    final item = schedule[index];
    debugPrint('🕒 Editing item: "${item.activity}"');
    debugPrint('🔹 Raw start time: "${item.startTime}"');
    debugPrint('🔹 Raw end time: "${item.endTime}"');

    try {
      String timeString = item.startTime.trim(); // Ensure no extra spaces
      // Normalize to include leading zero if needed (e.g., "7:30 AM" -> "07:30 AM")
      timeString = timeString.replaceFirstMapped(
        RegExp(r'^(\d):'), // Match single-digit hour
        (match) => '0${match.group(1)}:', // Add leading zero
      );

      // Use en_US locale to ensure 12-hour format with AM/PM
      final format = DateFormat('h:mm a', 'en_US');
      final parsedStartTime = format.parseStrict(_cleanTime(item.startTime));
      /*
      DateTime parsedTime = DateFormat(
        'h:mm a',
        'en_US',
      ).parseStrict(timeString);
      selectedStartTime = TimeOfDay.fromDateTime(parsedTime);
*/

      _activityController.text = item.activity;
      final parsedEndTime = format.parseStrict(_cleanTime(item.endTime));

      final endTime = parsedEndTime;
      final durationInMinutes = endTime.difference(parsedStartTime).inMinutes;
      durationMinutes = durationInMinutes > 0 ? durationInMinutes : 50;

      selectedStartTime = TimeOfDay.fromDateTime(
        DateFormat('h:mm a', 'en_US').parseStrict(_cleanTime(item.startTime)),
      );

      _openAddDialog(isEditing: true, editIndex: index);
    } catch (e) {
      debugPrint('❌ FormatException in _editItem(): $e');
    }
  }

  void _resumeVisualTimerIfNeeded() {
    final dest = Prefs.destinationTime;
    if (dest == null) return;

    final remaining = dest.difference(DateTime.now()).inSeconds;
    if (remaining > 0) {
      _destinationTime = dest;

      _activeDuration = Prefs.activeTimerDuration;

      _remainingSeconds = remaining;

      _updateTimer?.cancel();
      _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        final remaining =
            _destinationTime!.difference(DateTime.now()).inSeconds;
        if (remaining <= 0) {
          _stopVisualTimer();
          _playBellSound(timer: true);
        } else {
          setState(() {
            _remainingSeconds = remaining;
            _timerVisible = true;
          });
        }
      });

      setState(() {
        _timerVisible = true;
      });
    } else {
      Prefs.destinationTime = null;
    }
  }

  void _openAddDialog({bool isEditing = false, int? editIndex}) {
    if (!isEditing) {
      // Reset duration to default when opening dialog for new item
      durationMinutes = 50;
      _activityController.clear();
      selectedStartTime = null;
    }

    showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text(
                  isEditing ? 'Edit Schedule Item' : 'Add Schedule Item',
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Start time picker
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedStartTime != null
                                ? 'Start: ${_formatTime(selectedStartTime!)}'
                                : 'Start: (not selected)',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              await _pickStartTime();
                              setDialogState(() {});
                            },
                            child: const Text('Change'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Duration selector with dial
                      Text('Duration: $durationMinutes minutes'),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 200,
                        child: DurationDial(
                          initialDuration: durationMinutes,
                          onChanged: (newDuration) {
                            setDialogState(() {
                              durationMinutes = newDuration;
                            });
                          },
                        ),
                      ),

                      // Show calculated end time if start time is selected
                      if (selectedStartTime != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          'End: ${_formatTime(_addDurationToTime(selectedStartTime!, durationMinutes))}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],

                      const SizedBox(height: 20),
                      TextField(
                        controller: _activityController,
                        decoration: const InputDecoration(
                          labelText: 'Activity',
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (isEditing && editIndex != null) {
                        _updateScheduleItem(editIndex);
                      } else {
                        _addScheduleItem();
                      }
                    },
                    child: Text(isEditing ? 'Update' : 'Add'),
                  ),
                ],
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                Navigator.pop(context); // close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ).then(
                  (_) => setState(() {
                    _loadSchedule();
                  }),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.info),
              title: Text('About'),
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.help_outline),
              title: Text('Help'),
              onTap: () {
                Navigator.pop(context);
                _showHelpDialog(context);
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('My Time Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  )
                  .then(
                    (_) => setState(() {
                      _loadSchedule();
                    }),
                  );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_timerVisible)
            ElevatedButton(
              onPressed: () async {
                _stopVisualTimer();
                await _cancelAllNotifications();
              },
              child: Text("Stop Timer"),
            ),
          if (_timerVisible)
            SolidVisualTimer(
              remaining: _remainingSeconds,
              total: _activeDuration,
            ),
          Expanded(
            child: ListView.builder(
              itemCount: schedule.length,
              itemBuilder: (context, index) {
                final item = schedule[index];
                return ScheduleTile(
                  item: item,
                  onChanged: (value) => _updateItem(index, value),
                  onDelete: () => _deleteItem(index),
                  onEdit: () => _editItem(index),
                  onTap: () => _startVisualTimer(index),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'My Time Schedule',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2025 Bhante Subhuti',
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Help'),
            content: const Text(
              '• Tap an item to start the timer.\n• Long-press to edit.\n• Use the menu for settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}
