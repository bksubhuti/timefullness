import 'package:flutter/material.dart';
import 'package:my_time_schedule/models/prefs.dart';
import 'package:my_time_schedule/widgets/solid_visual_timer.dart';
import 'package:my_time_schedule/l10n/app_localizations.dart';

class TimerScreen extends StatefulWidget {
  final ValueNotifier<int> timerNotifier;
  final int totalSeconds;
  final VoidCallback onStop;

  const TimerScreen({
    super.key,
    required this.timerNotifier,
    required this.totalSeconds,
    required this.onStop,
  });

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  late bool _oneHourDisplay;

  @override
  void initState() {
    super.initState();
    _oneHourDisplay = Prefs.oneHourDisplay;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return WillPopScope(
      onWillPop: () async {
        widget.onStop();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(title: Text(l10n.timer)),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                Prefs.activeTimerName,
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            const SizedBox(height: 20),
            ValueListenableBuilder<int>(
              valueListenable: widget.timerNotifier,
              builder: (_, remaining, __) {
                return SolidVisualTimer(
                  remaining: remaining,
                  total: widget.totalSeconds,
                );
              },
            ),
            const SizedBox(height: 20),
            Column(
              children: [
                Text(
                  _oneHourDisplay
                      ? l10n.oneHourDisplayMode
                      : l10n.fullTimeDisplayMode,
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                Switch(
                  value: _oneHourDisplay,
                  onChanged: (bool value) {
                    setState(() {
                      _oneHourDisplay = value;
                      Prefs.oneHourDisplay = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                widget.onStop();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.stop),
              label: Text(l10n.stopTimer),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
