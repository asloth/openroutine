import 'package:flutter/material.dart';

import '../screens/routines_list/home/home_ink.dart';
import '../theme/theme.dart';

/// A form screen's one filled action, full width at the bottom. Put it in
/// the Scaffold's `bottomNavigationBar`; a null `onPressed` greys it out.
class FormSaveButton extends StatelessWidget {
  const FormSaveButton({
    super.key,
    required this.label,
    required this.saving,
    required this.onPressed,
  });

  final String label;
  final bool saving;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ink = HomeInk.of(context);
    final enabled = onPressed != null;
    return Material(
      color: enabled ? ink.action : ink.muted(0.12),
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      child: InkWell(
        onTap: onPressed,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          // heightFactor, or the Center fills every pixel the Scaffold offers
          // its bottom bar and leaves the form no room at all.
          child: Center(
            heightFactor: 1,
            child: saving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ink.onAction,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTypography.display,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: enabled ? ink.onAction : ink.muted(0.5),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
