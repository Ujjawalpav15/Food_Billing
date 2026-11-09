import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class DailyEntryScreen extends StatelessWidget {
  const DailyEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Entry'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_calendar_outlined,
                size: 72, color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Daily Meal Entry',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Coming in Module 6',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Add Entry',
        child: const Icon(Icons.add),
      ),
    );
  }
}
