// schedule_screet.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:my_time_schedule/constants.dart';
import 'package:my_time_schedule/dialogs/help_dialog.dart';
import 'package:my_time_schedule/screens/timer_screen.dart';
import 'package:my_time_schedule/services/notification_service.dart';
import 'package:my_time_schedule/services/utilities.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:my_time_schedule/models/prefs.dart';
import 'package:my_time_schedule/plugin.dart';
import 'package:my_time_schedule/screens/settings_screen.dart';
import 'package:my_time_schedule/services/hive_schedule_repository.dart';
import 'package:my_time_schedule/dialogs/add_schedule_content_dialog.dart';
import '../models/schedule_item.dart';
import '../widgets/schedule_tile.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:my_time_schedule/services/example_includes.dart';
import 'package:my_time_schedule/l10n/app_localizations.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with WidgetsBindingObserver {
  List<ScheduleItem> schedule = [];
  TimeOfDay? selectedStartTime;
  int durationMinutes = 50; // Default duration of 30 minutes
  final _activityController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isDefaultScheduleLoaded = false;
  late final HiveScheduleRepository scheduleRepo;
  int _activeDuration = 0;
  int _remainingSeconds = 0;
  Timer? _countdownTimer;
  bool _timerVisible = false;
  DateTime? _destinationTime;
  Timer? _updateTimer;
  final ValueNotifier<int> timerNotifier = ValueNotifier(0);

  bool _notificationsEnabled = false;
  bool _allNotificationsEnabled = Prefs.allNotificationsEnabled;

  @override
  void initState() {
    super.initState();
    final box = Hive.box('schedules');
    scheduleRepo = HiveScheduleRepository(box);
    _loadSchedule();

    if (Platform.isAndroid) _isAndroidPermissionGranted();
    _requestPermissions();

    _resumeVisualTimerIfNeeded();
    WidgetsBinding.instance.addObserver(this);
    _checkForMidnightReset();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    selectNotificationStream.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForMidnightReset();
    }
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
      // Load default json file from assets
      final raw = await rootBundle.loadString('assets/default_schedule.json');
      final List<dynamic> data = json.decode(raw);
      final List<ScheduleItem> items =
          data
              .map((e) => ScheduleItem.fromJson(Map<String, dynamic>.from(e)))
              .toList();

      setState(() {
        schedule = items;
        _isDefaultScheduleLoaded = true;
        _sortScheduleByTime();
      });

      // Save the default schedule
      Prefs.currentScheduleId = kDefaultScheduleName;
      await _saveSchedule();
    } catch (e) {
      debugPrint('Error loading default schedule: $e');
    }
  }

  void _addScheduleItem() {
    if (selectedStartTime == null || _activityController.text.isEmpty) return;

    // Calculate end time based on start time and duration
    final endTime = _addDurationToTime(selectedStartTime!, durationMinutes);
    final newItem = ScheduleItem(
      id: UniqueKey().toString(),
      startTime: _formatTime(selectedStartTime!),
      endTime: _formatTime(endTime),
      activity: _activityController.text,
      checkedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );

    setState(() {
      schedule.add(newItem);
      _sortScheduleByTime();
    });
    _saveSchedule();

    if (Prefs.allNotificationsEnabled) {
      scheduleNotification(newItem);
    }
    _activityController.clear();
    selectedStartTime = null;
    Navigator.of(context).pop();
  }

  void _updateScheduleItem(int index) {
    if (selectedStartTime == null || _activityController.text.isEmpty) return;

    final oldItem = schedule[index];
    final endTime = _addDurationToTime(selectedStartTime!, durationMinutes);

    final updatedItem = ScheduleItem(
      id: oldItem.id, // keep same ID
      startTime: _formatTime(selectedStartTime!),
      endTime: _formatTime(endTime),
      activity: _activityController.text,
      done: oldItem.done,
      checkedAt: oldItem.checkedAt,
    );

    if (Prefs.allNotificationsEnabled) {
      flutterLocalNotificationsPlugin.cancel(oldItem.id.hashCode);
    }

    setState(() {
      schedule[index] = updatedItem;
      _sortScheduleByTime();
    });

    _saveSchedule();

    if (Prefs.allNotificationsEnabled) {
      scheduleNotification(updatedItem);
    }

    _activityController.clear();
    selectedStartTime = null;
    Navigator.of(context).pop();
  }

  Future<void> _playBellSound({bool timer = false}) async {
    String soundFile = 'bell-meditation-trim.mp3';
    //timer ? 'bell-meditation-75335.mp3' : 'bell-meditation-trim.mp3';

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
    if (newValue && Prefs.shouldPlaySoundOnCheck) {
      _playBellSound();
    }

    _saveSchedule();
  }

  void _deleteItem(int index) {
    final item = schedule[index];

    if (Prefs.allNotificationsEnabled) {
      flutterLocalNotificationsPlugin.cancel(item.id.hashCode);
    }
    setState(() {
      schedule.removeAt(index);
    });
    _saveSchedule();
  }

  void _sortScheduleByTime() {
    final format = DateFormat('h:mm a', 'en_US');
    schedule.sort((a, b) {
      try {
        final aTime = format.parseStrict(cleanTime(a.startTime));
        final bTime = format.parseStrict(cleanTime(b.startTime));
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
      final start = format.parse(cleanTime(item.startTime));
      final end = format.parse(cleanTime(item.endTime));
      final duration = end.difference(start);
      final int totalSeconds = duration.inSeconds;

      final now = DateTime.now();
      final destination = now.add(duration);

      Prefs.destinationTime = _destinationTime = destination;
      _activeDuration = totalSeconds;
      _remainingSeconds = totalSeconds;
      Prefs.activeTimerDuration = totalSeconds;
      timerNotifier.value = totalSeconds;
      Prefs.activeTimerName = item.activity;

      WakelockPlus.enable();

      await timerNotification(duration, context);

      _updateTimer?.cancel();
      _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        final now = DateTime.now();
        final remaining = _destinationTime!.difference(now).inSeconds;

        if (remaining <= 0) {
          timerNotifier.value = 0;
          _stopVisualTimer();
          //_playBellSound(); why
          WakelockPlus.disable();
        } else {
          timerNotifier.value = remaining;
        }
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => TimerScreen(
                totalSeconds: totalSeconds,
                timerNotifier: timerNotifier,
                onStop: () async {
                  _stopVisualTimer(early: true);
                  if (Prefs.activeTimerHash != 0) {
                    await flutterLocalNotificationsPlugin.cancel(
                      Prefs.activeTimerHash,
                    );
                    Prefs.activeTimerHash = 0;
                  }
                },
              ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Could not start visual timer: $e');
      if (await WakelockPlus.enabled) WakelockPlus.disable();
    }
  }

  void _stopVisualTimer({bool early = false}) async {
    _updateTimer?.cancel();
    Prefs.destinationTime = _destinationTime = null;
    WakelockPlus.disable();

    if (early && Prefs.activeTimerHash != 0) {
      await flutterLocalNotificationsPlugin.cancel(Prefs.activeTimerHash);
      Prefs.activeTimerHash = 0;
    }

    setState(() => _timerVisible = false);
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
      Prefs.allNotificationsEnabled = false;
      cancelAllNotifications();
      setState(() {
        for (var item in schedule) {
          item.done = false;
        }
        _allNotificationsEnabled = false;
      });
      await prefs.setString('lastResetDate', today);
      await _saveSchedule();
    }
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
      final parsedStartTime = format.parseStrict(cleanTime(item.startTime));
      /*
      DateTime parsedTime = DateFormat(
        'h:mm a',
        'en_US',
      ).parseStrict(timeString);
      selectedStartTime = TimeOfDay.fromDateTime(parsedTime);
*/

      _activityController.text = item.activity;
      final parsedEndTime = format.parseStrict(cleanTime(item.endTime));

      final endTime = parsedEndTime;
      final durationInMinutes = endTime.difference(parsedStartTime).inMinutes;
      durationMinutes = durationInMinutes > 0 ? durationInMinutes : 50;

      selectedStartTime = TimeOfDay.fromDateTime(
        DateFormat('h:mm a', 'en_US').parseStrict(cleanTime(item.startTime)),
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
        timerNotifier.value = remaining;
        if (remaining <= 0) {
          _stopVisualTimer();
          //_playBellSound(timer: true); //why
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => TimerScreen(
                  totalSeconds: _activeDuration,
                  timerNotifier: timerNotifier,
                  onStop: () async {
                    _stopVisualTimer(early: true);
                    if (Prefs.activeTimerHash != 0) {
                      await flutterLocalNotificationsPlugin.cancel(
                        Prefs.activeTimerHash,
                      );
                      Prefs.activeTimerHash = 0;
                    }
                  },
                ),
          ),
        );
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
              return AddScheduleContentDialog(
                isEditing: isEditing,
                selectedStartTime: selectedStartTime,
                durationMinutes: durationMinutes,
                activityController: _activityController,
                onPickTime: () async {
                  await _pickStartTime();
                  setDialogState(() {});
                },
                onDurationChanged: (val) {
                  setDialogState(() => durationMinutes = val);
                },
                onSubmit: () {
                  if (isEditing && editIndex != null) {
                    _updateScheduleItem(editIndex);
                  } else {
                    _addScheduleItem();
                  }
                },
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      12,
                    ), // Adjust as desired
                    child: Image.asset(
                      'assets/icon/icon.png',
                      height: 60,
                      width: 60,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.menu,
                    style: const TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text(AppLocalizations.of(context)!.settings),
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
              title: Text(l10n.about),
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.help_outline),
              title: Text(l10n.help),
              onTap: () {
                Navigator.pop(context);
                _showHelpDialog(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.rate_review),
              title: Text(l10n.rateThisApp),
              onTap: () async {
                final InAppReview inAppReview = InAppReview.instance;
                if (await inAppReview.isAvailable()) {
                  inAppReview.openStoreListing();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: Text(AppLocalizations.of(context)!.shareThisApp),
              onTap: () {
                Navigator.pop(context); // close drawer

                SharePlus.instance.share(
                  ShareParams(
                    text: AppLocalizations.of(context)!.shareAppMessage,
                  ),
                );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/icon/icon.png', height: 30),
            const SizedBox(width: 10),
            Text(l10n.appName, style: TextStyle(fontSize: 20)),
          ],
        ),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Row(
              children: [
                Text(
                  "${scheduleRepo.getScheduleName(Prefs.currentScheduleId)} Schedule: ",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                buildNotificationToggle(),
              ],
            ),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
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
      applicationName: AppLocalizations.of(context)!.appName,
      applicationVersion: AppLocalizations.of(context)!.appVersion,
      applicationLegalese: AppLocalizations.of(context)!.appCopyright,
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => HelpDialogWidget());
  }

  Widget buildNotificationToggle() {
    final l10n = AppLocalizations.of(context)!;

    // Refresh local state from Prefs
    _allNotificationsEnabled = Prefs.allNotificationsEnabled;

    return Tooltip(
      message:
          _allNotificationsEnabled
              ? l10n.shouldTurnOffNotifcations
              : l10n.shouldTurnOnNotifcations,
      child: IconButton(
        icon: Icon(
          _allNotificationsEnabled
              ? Icons.notifications_active
              : Icons.notifications_off,
          color: _allNotificationsEnabled ? getAdjustedColor(context) : null,
        ),
        onPressed: () async {
          final shouldProceed = await showDialog<bool>(
            context: context,
            builder:
                (_) => AlertDialog(
                  title: Text(
                    _allNotificationsEnabled
                        ? l10n.shouldTurnOffNotifcations
                        : l10n.shouldTurnOnNotifcations,
                  ),
                  content: Text(
                    _allNotificationsEnabled
                        ? l10n.thisWillStopFutureNotifications
                        : l10n.thisWillEnableAllReminders,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l10n.cancel),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(l10n.ok),
                    ),
                  ],
                ),
          );

          if (shouldProceed != true) return;

          setState(() {
            _allNotificationsEnabled = !_allNotificationsEnabled;
            Prefs.allNotificationsEnabled = _allNotificationsEnabled;
          });

          if (_allNotificationsEnabled) {
            final schedule = await scheduleRepo.loadSchedule(
              Prefs.currentScheduleId,
            );
            final now = DateTime.now();
            final format = DateFormat('h:mm a', 'en_US');

            for (final item in schedule) {
              try {
                final startTime = format.parseStrict(cleanTime(item.startTime));
                final fullStartTime = DateTime(
                  now.year,
                  now.month,
                  now.day,
                  startTime.hour,
                  startTime.minute,
                );

                if (fullStartTime.isAfter(now)) {
                  await scheduleNotification(item);
                }
              } catch (e) {
                debugPrint(
                  '❌ Failed to parse startTime for "${item.activity}": $e',
                );
              }
            }
          } else {
            await _cancelScheduledNotificationsOnly();
          }
        },
      ),
    );
  }

  Future<void> _cancelScheduledNotificationsOnly() async {
    final schedule = await scheduleRepo.loadSchedule(Prefs.currentScheduleId);
    for (var item in schedule) {
      await flutterLocalNotificationsPlugin.cancel(item.id.hashCode);
    }
  }
}

// extra code not used but kept
/*
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
*/

/*
  Future<void> _requestNotificationPolicyAccess() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    await androidImplementation?.requestNotificationPolicyAccess();
  }
*/
