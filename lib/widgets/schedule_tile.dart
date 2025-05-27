import 'package:flutter/material.dart';
import 'package:my_time_schedule/models/prefs.dart';
import '../models/schedule_item.dart';

class ScheduleTile extends StatelessWidget {
  final ScheduleItem item;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onTap;

  const ScheduleTile({
    super.key,
    required this.item,
    required this.onChanged,
    required this.onDelete,
    this.onEdit,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => onChanged(!item.done),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder:
                    (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                child:
                    item.done
                        ? Image.asset(
                          'assets/icons/checked_icon.png',
                          width: 34,
                          height: 34,
                          key: const ValueKey(true),
                        )
                        : Container(
                          key: const ValueKey(false),
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
              ),
            ),
            const SizedBox(width: 12),

            // Content column
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                style: TextStyle(
                  fontSize: 14,
                  color:
                      Theme.of(context).textTheme.bodyMedium?.color ??
                      Colors.black,
                  decoration:
                      item.done
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${item.startTime} – ${item.endTime}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(Prefs.timerColor),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              size: 20,
                              color: Color(Prefs.timerColor),
                            ),
                            onPressed: onEdit,
                            tooltip: 'Start Timer',
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.activity,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            IconButton(
              icon: Icon(Icons.timer, size: 20, color: Color(Prefs.timerColor)),
              onPressed: onTap,
              tooltip: 'Launch Timer',
            ),
            IconButton(
              icon: Icon(
                Icons.delete,
                size: 20,
                color: Color(Prefs.timerColor),
              ),
              tooltip: 'Delete',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Are you sure?'),
                        content: const Text(
                          'Do you really want to delete this item?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                );

                if (confirm == true) {
                  onDelete();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
