import 'package:flutter/material.dart';
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
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () => onChanged(!item.done),
                child:
                    item.done
                        ? Image.asset(
                          'assets/icons/checked_icon.png',
                          width: 34,
                          height: 34,
                        )
                        : Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${item.startTime} – ${item.endTime} | ${item.activity}',
                style: TextStyle(
                  fontSize: 14,
                  decoration:
                      item.done
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                ),
              ),
            ),
            if (onEdit != null) ...[
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Edit',
              ),
              const SizedBox(width: 4),
            ],
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Delete',
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}
