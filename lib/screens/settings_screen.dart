// settings_screen.dart
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:my_time_schedule/constants.dart';
import 'package:my_time_schedule/models/schedule_item.dart';
import 'package:my_time_schedule/plugin.dart';
import '../models/prefs.dart';
import '../services/hive_schedule_repository.dart';
import 'package:hive/hive.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:my_time_schedule/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Color selectedColor = Color(Prefs.timerColor);
  late HiveScheduleRepository _repo;
  List<String> _scheduleIds = [];
  String? _activeId;
  String _selectedScheduleId = '';
  late final HiveScheduleRepository scheduleRepo;
  bool _backgroundEnabled = Prefs.backgroundEnabled;

  @override
  void initState() {
    super.initState();
    final box = Hive.box('schedules');
    _repo = HiveScheduleRepository(box);
    scheduleRepo = HiveScheduleRepository(box);
    _loadScheduleData();
  }

  Future<void> _loadScheduleData() async {
    final ids = await scheduleRepo.listScheduleIds();
    final active = await scheduleRepo.getActiveScheduleId();

    setState(() {
      _scheduleIds = ids;
      if (active != null && ids.contains(active)) {
        _selectedScheduleId = active;
      } else {
        _selectedScheduleId = ids.isNotEmpty ? ids.first : '';
      }
    });
  }

  Future<void> _loadSchedules() async {
    final ids = await _repo.listScheduleIds();
    final active = await _repo.getActiveScheduleId();
    setState(() {
      _scheduleIds = ids;
      _activeId = active;
    });
  }

  Future<void> _setActive(String? id) async {
    if (id != null) {
      await _repo.setActiveScheduleId(id);
      setState(() => _activeId = id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Divider(height: 40),
          Row(
            children: [
              Icon(Icons.language, color: Color(Prefs.timerColor)),
              SizedBox(width: 8),
              Text(l10n.language, style: TextStyle(fontSize: 18)),
            ],
          ),
          const SizedBox(height: 10),
          Consumer<LocaleProvider>(
            builder: (context, localeProvider, _) {
              final currentLocale = localeProvider.locale?.languageCode ?? 'en';
              return DropdownButton<String>(
                value: currentLocale,
                onChanged: (String? code) {
                  if (code == null) return;
                  final newLocale = Locale(code);
                  localeProvider.setLocale(newLocale);
                },
                items:
                    supportedLocales.map((locale) {
                      return DropdownMenuItem(
                        value: locale.languageCode,
                        child: Text(languageLabels[locale.languageCode]!),
                      );
                    }).toList(),
              );
            },
          ),
          const Divider(height: 40),

          ListTile(
            title: Text(
              AppLocalizations.of(context)!.timerCircleColor,
              style: TextStyle(fontSize: 18),
            ),
            subtitle: Text(
              AppLocalizations.of(context)!.tapToSelect,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            trailing: CircleAvatar(backgroundColor: Color(Prefs.timerColor)),
            onTap:
                () => showDialog(
                  context: context,
                  builder:
                      (_) => AlertDialog(
                        title: Text(
                          AppLocalizations.of(context)!.pickTimerColor,
                        ),
                        content: SingleChildScrollView(
                          child: ColorPicker(
                            pickerColor: Color(Prefs.timerColor),
                            onColorChanged: (color) {
                              setState(() => Prefs.timerColor = color.value);
                            },
                            showLabel: false,
                            pickerAreaHeightPercent: 0.8,
                          ),
                        ),
                        actions: [
                          TextButton(
                            child: Text(AppLocalizations.of(context)!.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                ),
          ),
          const Divider(height: 40),
          Text(
            AppLocalizations.of(context)!.selectActiveSchedule,
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 10),
          DropdownButton<String>(
            value:
                _scheduleIds.contains(_selectedScheduleId)
                    ? _selectedScheduleId
                    : null,
            hint: Text(AppLocalizations.of(context)!.selectActiveSchedule),
            items:
                _scheduleIds.map((id) {
                  return DropdownMenuItem<String>(value: id, child: Text(id));
                }).toList(),
            onChanged: (value) async {
              if (value == null) return;
              Prefs.currentScheduleId = value;
              await scheduleRepo.setActiveScheduleId(value);
              setState(() {
                _selectedScheduleId = value;
              });
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _addNewSchedule,
                child: Text(AppLocalizations.of(context)!.add),
              ),
              ElevatedButton(
                onPressed: _renameSchedule,
                child: Text(AppLocalizations.of(context)!.rename),
              ),
              ElevatedButton(
                onPressed: _deleteSchedule,
                child: Text(AppLocalizations.of(context)!.delete),
              ),
            ],
          ),
          const Divider(height: 40),
          SwitchListTile(
            title: Text(AppLocalizations.of(context)!.playSoundWhenChecked),
            subtitle: Text(AppLocalizations.of(context)!.playSoundSubtitle),
            value: Prefs.shouldPlaySoundOnCheck,
            onChanged: (value) {
              setState(() {
                Prefs.shouldPlaySoundOnCheck = value;
              });
            },
          ),
          SizedBox(height: 10),
          if (Platform.isAndroid || true)
            SwitchListTile(
              title: Text(AppLocalizations.of(context)!.timerBypassDndTitle),
              subtitle: Text(
                AppLocalizations.of(context)!.timerBypassDndSubtitle,
              ),
              value: Prefs.timerBypassDnd,
              onChanged: (val) async {
                setState(() {
                  Prefs.timerBypassDnd = val;
                });
                if (Prefs.timerBypassDnd) {
                  await _createNotificationChannelWithDndBypass(context);
                }
              },
            ),

          const Divider(height: 40),
        ],
      ),
    );
  }

  Future<void> _addNewSchedule() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.newScheduleName),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.enterScheduleName,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: Text(AppLocalizations.of(context)!.create),
              ),
            ],
          ),
    );

    if (name == null || name.isEmpty) return;

    final existing = await scheduleRepo.loadSchedule(name);
    if (existing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.scheduleAlreadyExists(name),
          ),
        ),
      );
      return;
    }

    // Add default entry
    await scheduleRepo.saveSchedule(name, [
      ScheduleItem(
        id: UniqueKey().toString(),
        startTime: '6:00 AM',
        endTime: '7:00 AM',
        activity: AppLocalizations.of(context)!.meditation,
      ),
    ]);

    // Set active and save preferences
    await scheduleRepo.setActiveScheduleId(name);
    Prefs.currentScheduleId = name;

    // Reload from source to avoid duplicates
    await _loadScheduleData();

    setState(() {
      _selectedScheduleId = name;
    });
  }

  Future<void> _renameSchedule() async {
    if (_selectedScheduleId.isEmpty) return;
    if (_selectedScheduleId == defaultScheduleId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.youCannotRenameDefault),
        ),
      );
      return;
    }

    final controller = TextEditingController(text: _selectedScheduleId);

    final newName = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.renameScheduleTitle),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.newScheduleNameHint,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: Text(AppLocalizations.of(context)!.rename),
              ),
            ],
          ),
    );

    if (newName == null || newName.isEmpty || newName == _selectedScheduleId)
      return;

    final existing = await scheduleRepo.loadSchedule(newName);
    if (existing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.newScheduleAlreadyExists(newName),
          ),
        ),
      );
      return;
    }

    final oldData = await scheduleRepo.loadSchedule(_selectedScheduleId);
    await scheduleRepo.saveSchedule(newName, oldData);
    await scheduleRepo.deleteSchedule(_selectedScheduleId);

    final wasActive =
        await scheduleRepo.getActiveScheduleId() == _selectedScheduleId;
    if (wasActive) {
      await scheduleRepo.setActiveScheduleId(newName);
      Prefs.currentScheduleId = newName;
    }

    await _loadScheduleData();

    setState(() {
      _selectedScheduleId = newName;
    });
  }

  Future<void> _deleteSchedule() async {
    if (_selectedScheduleId.isEmpty) return;

    if (_selectedScheduleId == defaultScheduleId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.youCannotDeleteDefault),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.deleteScheduleTitle),
            content: Text(
              AppLocalizations.of(
                context,
              )!.deleteScheduleConfirmation(_selectedScheduleId),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(AppLocalizations.of(context)!.delete),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    await scheduleRepo.deleteSchedule(_selectedScheduleId);

    final remaining =
        _scheduleIds.where((id) => id != _selectedScheduleId).toList();
    String newSelectedId = '';
    if (remaining.isNotEmpty) {
      newSelectedId = remaining.first;
      await scheduleRepo.setActiveScheduleId(newSelectedId);
      Prefs.currentScheduleId = newSelectedId;
    } else {
      await scheduleRepo.setActiveScheduleId('');
      Prefs.currentScheduleId = '';
    }

    await _loadScheduleData();

    setState(() {
      _selectedScheduleId = newSelectedId;
    });
  }

  Future<void> _createNotificationChannelWithDndBypass(
    BuildContext context,
  ) async {
    const AndroidNotificationChannel androidNotificationChannel =
        AndroidNotificationChannel(
          kDndBypassTimerChannelId,
          kDndBypassTimerChannelName,
          description: kDndBypassTimerChannelDescription,
          bypassDnd: true,
          sound: RawResourceAndroidNotificationSound('bell'),
          playSound: true,
          importance: Importance.max,
        );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    // Check if DND access is already granted
    final bool? hasPolicyAccess =
        await androidPlugin?.hasNotificationPolicyAccess();

    if (hasPolicyAccess ?? false) {
      await androidPlugin?.createNotificationChannel(
        androidNotificationChannel,
      );
      return;
    }

    final shouldOpenSettings = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.enableDndBypassTitle),
            content: Text(AppLocalizations.of(context)!.enableDndBypassMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(AppLocalizations.of(context)!.grantAccess),
              ),
            ],
          ),
    );

    if (shouldOpenSettings == true) {
      final intent = AndroidIntent(
        action: 'android.settings.NOTIFICATION_POLICY_ACCESS_SETTINGS',
      );
      await intent.launch();

      // ✅ Show "Continue" dialog
      showDialog<void>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(AppLocalizations.of(context)!.finishSetupTitle),
              content: Text(AppLocalizations.of(context)!.finishSetupMessage),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop(); // close dialog
                    final newAccess =
                        await androidPlugin?.hasNotificationPolicyAccess();
                    if (newAccess ?? false) {
                      await androidPlugin?.createNotificationChannel(
                        androidNotificationChannel,
                      );
                      debugPrint(
                        "DND bypass channel created after user clicked Continue.",
                      );
                    } else {
                      debugPrint("Still no DND access.");
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.continueLabel),
                ),
              ],
            ),
      );
    }
  }
}
