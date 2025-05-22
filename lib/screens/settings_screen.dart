// settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../models/prefs.dart';
import '../services/hive_schedule_repository.dart';
import 'package:hive/hive.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

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
      _selectedScheduleId = active ?? (ids.isNotEmpty ? ids.first : '');
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
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text(
              "Timer Circle Color",
              style: TextStyle(fontSize: 18),
            ),
            subtitle: Text(
              "Tap to select",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            trailing: CircleAvatar(backgroundColor: Color(Prefs.timerColor)),
            onTap:
                () => showDialog(
                  context: context,
                  builder:
                      (_) => AlertDialog(
                        title: const Text('Pick Timer Color'),
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
                            child: const Text('Close'),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                ),
          ),
          const Divider(height: 40),
          const Text("Select Active Schedule", style: TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          DropdownButton<String>(
            value: _selectedScheduleId.isNotEmpty ? _selectedScheduleId : null,
            hint: const Text("Select Schedule"),
            items:
                _scheduleIds.map((id) {
                  return DropdownMenuItem(value: id, child: Text(id));
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
                child: const Text("Add"),
              ),
              ElevatedButton(
                onPressed: _renameSchedule,
                child: const Text("Rename"),
              ),
              ElevatedButton(
                onPressed: _deleteSchedule,
                child: const Text("Delete"),
              ),
            ],
          ),
          SwitchListTile(
            title: const Text(
              "Enable Background Service",
              style: TextStyle(fontSize: 18),
            ),
            subtitle: const Text(
              "Allow timer to run in background",
              style: TextStyle(color: Colors.grey),
            ),
            value: _backgroundEnabled,
            onChanged: (bool value) async {
              setState(() {
                _backgroundEnabled = value;
              });
              Prefs.backgroundEnabled = value;

              final service = FlutterBackgroundService();
              if (value) {
                final success = await service.startService();
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Failed to start background service."),
                    ),
                  );
                }
              } else {
                service.invoke('stopService');
              }
            },
          ),
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
            title: const Text('New Schedule Name'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Enter schedule name',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: const Text('Create'),
              ),
            ],
          ),
    );

    if (name == null || name.isEmpty) return;

    final existing = await scheduleRepo.loadSchedule(name);
    if (existing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Schedule "$name" already exists')),
      );
      return;
    }

    await scheduleRepo.saveSchedule(name, []);
    await scheduleRepo.setActiveScheduleId(name);
    Prefs.currentScheduleId = name;
    await _loadScheduleData();

    setState(() {
      _selectedScheduleId = name;
      _scheduleIds.add(name);
    });
  }

  Future<void> _renameSchedule() async {
    if (_selectedScheduleId.isEmpty) return;

    final controller = TextEditingController(text: _selectedScheduleId);

    final newName = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Rename Schedule'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'New schedule name'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: const Text('Rename'),
              ),
            ],
          ),
    );

    if (newName == null || newName.isEmpty || newName == _selectedScheduleId)
      return;

    final existing = await scheduleRepo.loadSchedule(newName);
    if (existing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Schedule "$newName" already exists')),
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

    setState(() {
      final idx = _scheduleIds.indexOf(_selectedScheduleId);
      _scheduleIds[idx] = newName;
      _selectedScheduleId = newName;
    });
  }

  Future<void> _deleteSchedule() async {
    if (_selectedScheduleId.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Schedule?'),
            content: Text(
              'Are you sure you want to delete "$_selectedScheduleId"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    await scheduleRepo.deleteSchedule(_selectedScheduleId);
    final wasActive =
        await scheduleRepo.getActiveScheduleId() == _selectedScheduleId;
    if (wasActive) {
      final remaining =
          _scheduleIds.where((id) => id != _selectedScheduleId).toList();
      if (remaining.isNotEmpty) {
        await scheduleRepo.setActiveScheduleId(remaining.first);
        Prefs.currentScheduleId = remaining.first;
        _selectedScheduleId = remaining.first;
      } else {
        await scheduleRepo.setActiveScheduleId('');
        Prefs.currentScheduleId = '';
        _selectedScheduleId = '';
      }
    }

    setState(() {
      _scheduleIds.remove(_selectedScheduleId);
    });
  }
}
