import 'package:flutter/material.dart';
import 'package:my_time_schedule/l10n/app_localizations.dart';

class HelpDialogWidget extends StatelessWidget {
  const HelpDialogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.helpTitle),
      content: Text(l10n.helpText),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
