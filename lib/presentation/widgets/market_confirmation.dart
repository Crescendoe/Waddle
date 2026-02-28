import 'package:flutter/material.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/presentation/widgets/common.dart';

/// Shows a confirmation dialog before a purchase or use action.
/// Returns `true` if the user confirmed, `false` otherwise.
Future<bool> showMarketConfirmation(
  BuildContext context, {
  required String action, // e.g. 'purchase' or 'use'
  required String itemName,
  int? cost, // drops cost (null for use actions)
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Confirm ${action[0].toUpperCase()}${action.substring(1)}',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      content: Text(
        cost != null
            ? 'Are you sure you want to $action $itemName for $cost Drops?'
            : 'Are you sure you want to $action $itemName?',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: ActiveThemeColors.of(context).primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            action == 'use' ? 'Use It' : 'Buy',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
  return result == true;
}
