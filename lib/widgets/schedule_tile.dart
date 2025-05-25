import 'package:flutter/material.dart';
import 'package:timefulness/models/prefs.dart';
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
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
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

            // Text content
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
                child: Text(
                  '${item.startTime} – ${item.endTime} | ${item.activity}',
                ),
              ),
            ),
            // Timer icon
            IconButton(
              icon: Icon(Icons.timer, size: 20, color: Color(Prefs.timerColor)),
              onPressed: onTap,
              tooltip: 'Start Timer',
            ),

            // Popup menu
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEdit?.call();
                if (value == 'delete') onDelete.call();
              },
              itemBuilder:
                  (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: const [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: const [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
              icon: const Icon(Icons.more_vert, size: 20),
              tooltip: 'More',
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
