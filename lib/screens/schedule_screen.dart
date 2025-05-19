import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/schedule_item.dart';
import '../widgets/schedule_tile.dart';

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

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
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
    final prefs = await SharedPreferences.getInstance();
    final data = schedule.map((item) => item.toJson()).toList();
    await prefs.setString('schedule', jsonEncode(data));
  }

  Future<void> _loadSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('schedule');

    if (jsonStr != null) {
      final List<dynamic> data = jsonDecode(jsonStr);
      final loadedSchedule = data.map((e) => ScheduleItem.fromJson(e)).toList();
      _sortScheduleByTime(); // optional if sorting doesn't rely on state yet

      setState(() {
        schedule = loadedSchedule;
      });

      await _checkForMidnightReset();
    } else {
      await _loadDefaultSchedule();
    }
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
        _saveSchedule();
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
          startTime: _formatTime(selectedStartTime!),
          endTime: _formatTime(endTime),
          activity: _activityController.text,
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
        startTime: _formatTime(selectedStartTime!),
        endTime: _formatTime(endTime),
        activity: _activityController.text,
        done: schedule[index].done,
      );
      _sortScheduleByTime();
    });
    _saveSchedule();
    _activityController.clear();
    selectedStartTime = null;
    Navigator.of(context).pop();
  }

  Future<void> _playBellSound() async {
    try {
      final player = AudioPlayer(); // Create a fresh instance each time
      await player.play(AssetSource('bell-meditation-trim.mp3'));
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
                      Text('Duration: ${durationMinutes} minutes'),
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
      appBar: AppBar(title: const Text('Timefulness')),
      body: ListView.builder(
        itemCount: schedule.length,
        itemBuilder: (context, index) {
          final item = schedule[index];
          return ScheduleTile(
            item: item,
            onChanged: (value) => _updateItem(index, value),
            onDelete: () => _deleteItem(index),
            onEdit: () => _editItem(index),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Custom duration dial widget
class DurationDial extends StatefulWidget {
  final int initialDuration;
  final ValueChanged<int> onChanged;

  const DurationDial({
    super.key,
    required this.initialDuration,
    required this.onChanged,
  });

  @override
  State<DurationDial> createState() => _DurationDialState();
}

class _DurationDialState extends State<DurationDial> {
  late double _angle;
  late int _duration;

  @override
  void initState() {
    super.initState();
    _duration = widget.initialDuration;
    // Convert duration to angle (0-360 degrees)
    _angle = (_duration / 120) * 2 * math.pi; // Max 2 hours (120 minutes)
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final center = Offset(box.size.width / 2, box.size.height / 2);
        final position = details.localPosition;
        final angle =
            (math.atan2(position.dy - center.dy, position.dx - center.dx) +
                math.pi * 2.5) %
            (math.pi * 2);

        setState(() {
          _angle = angle;
          // Convert angle to duration (5-120 minutes)
          _duration = math.max(
            5,
            math.min(120, (angle / (2 * math.pi) * 120).round()),
          );
          widget.onChanged(_duration);
        });
      },
      child: CustomPaint(
        size: const Size(200, 200),
        painter: DialPainter(angle: _angle, duration: _duration),
      ),
    );
  }
}

class DialPainter extends CustomPainter {
  final double angle;
  final int duration;

  DialPainter({required this.angle, required this.duration});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Draw dial background
    final backgroundPaint =
        Paint()
          ..color = Colors.grey.shade200
          ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw dial border
    final borderPaint =
        Paint()
          ..color = Colors.grey.shade400
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    canvas.drawCircle(center, radius, borderPaint);

    // Draw selected segment
    final selectedPaint =
        Paint()
          ..color = Colors.blue.withOpacity(0.3)
          ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      angle,
      true,
      selectedPaint,
    );

    // Draw indicator line
    final linePaint =
        Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
    final lineEnd = Offset(
      center.dx + radius * math.cos(angle - math.pi / 2),
      center.dy + radius * math.sin(angle - math.pi / 2),
    );
    canvas.drawLine(center, lineEnd, linePaint);

    // Draw indicator knob
    final knobPaint =
        Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.fill;
    canvas.drawCircle(lineEnd, 8, knobPaint);

    // Draw duration text using a simpler approach
    final textStyle = TextStyle(
      color: Colors.black,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );
    final paragraphStyle = ui.ParagraphStyle(
      textAlign: TextAlign.center,
      fontSize: 16,
    );
    final paragraphBuilder =
        ui.ParagraphBuilder(paragraphStyle)
          ..pushStyle(textStyle.getTextStyle())
          ..addText('$duration min');
    final paragraph = paragraphBuilder.build();
    paragraph.layout(ui.ParagraphConstraints(width: size.width));
    canvas.drawParagraph(
      paragraph,
      Offset(center.dx - paragraph.width / 2, center.dy - paragraph.height / 2),
    );
  }

  @override
  bool shouldRepaint(DialPainter oldDelegate) {
    return oldDelegate.angle != angle || oldDelegate.duration != duration;
  }
}
