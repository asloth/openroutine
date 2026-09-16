import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import 'home_ink.dart';

/// The Add a routine pill, shared by Today and Routines.
///
/// The shell's nav pill floats over the body and reports itself as bottom
/// padding, which the Scaffold doesn't lift a button for. This pill is wide
/// enough to collide with it, so it lifts itself by [clearance].
class AddRoutineButton extends StatelessWidget {
  const AddRoutineButton({super.key, required this.clearance});

  /// The screen's own bottom padding, read above its Scaffold: inside the
  /// button slot, the Scaffold has already removed it.
  final double clearance;

  @override
  Widget build(BuildContext context) {
    final ink = HomeInk.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: clearance),
      child: FloatingActionButton.extended(
        onPressed: () => context.push('/routines/new'),
        backgroundColor: ink.action,
        foregroundColor: ink.onAction,
        shape: const StadiumBorder(),
        icon: const Icon(Icons.add),
        label: Text(
          AppLocalizations.of(context)!.homeAddRoutine,
          style: HomeInk.title.copyWith(fontSize: 15),
        ),
      ),
    );
  }
}
