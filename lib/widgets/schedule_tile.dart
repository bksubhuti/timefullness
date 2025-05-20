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
    return Dismissible(
      key: ValueKey(item.startTime + item.endTime + item.activity),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Checkbox(value: item.done, onChanged: onChanged),
              Expanded(
                child: Text(
                  '${item.startTime} – ${item.endTime} | ${item.activity}',
                  style: TextStyle(
                    decoration: item.done ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              // Edit button
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              // Delete button
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: Colors.red,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
