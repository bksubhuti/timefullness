import 'package:flutter/material.dart';
import 'package:my_time_schedule/models/prefs.dart';
import 'package:my_time_schedule/widgets/solid_visual_timer.dart';
import 'package:my_time_schedule/l10n/app_localizations.dart';

class TimerScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return WillPopScope(
      onWillPop: () async {
        onStop(); // stop timer and cancel notifications
        return true; // allow the pop
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
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            const SizedBox(height: 20),
            ValueListenableBuilder<int>(
              valueListenable: timerNotifier,
              builder: (_, remaining, __) {
                return SolidVisualTimer(
                  remaining: remaining,
                  total: totalSeconds,
                );
              },
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                onStop();
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
