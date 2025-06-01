import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:my_time_schedule/widgets/duration_dial.dart';

class AddScheduleContentDialog extends StatelessWidget {
  final bool isEditing;
  final TimeOfDay? selectedStartTime;
  final int durationMinutes;
  final TextEditingController activityController;
  final VoidCallback onPickTime;
  final ValueChanged<int> onDurationChanged;
  final VoidCallback onSubmit;

  const AddScheduleContentDialog({
    super.key,
    required this.isEditing,
    required this.selectedStartTime,
    required this.durationMinutes,
    required this.activityController,
    required this.onPickTime,
    required this.onDurationChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    String formatTime(TimeOfDay time) {
      return MaterialLocalizations.of(context).formatTimeOfDay(time);
    }

    return AlertDialog(
      title: Text(isEditing ? l10n.editScheduleItem : l10n.addScheduleItem),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedStartTime != null
                      ? '${l10n.startLabel}: ${formatTime(selectedStartTime!)}'
                      : '${l10n.startLabel}: (${l10n.notSelected})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                ElevatedButton(onPressed: onPickTime, child: Text(l10n.change)),
              ],
            ),
            const SizedBox(height: 20),
            Text('${l10n.durationLabel}: $durationMinutes ${l10n.minutes}'),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: DurationDial(
                initialDuration: durationMinutes,
                onChanged: onDurationChanged,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: activityController,
              decoration: InputDecoration(labelText: l10n.activityLabel),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: onSubmit,
          child: Text(isEditing ? l10n.update : l10n.add),
        ),
      ],
    );
  }
}
