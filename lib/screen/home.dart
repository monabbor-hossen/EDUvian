import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../model/widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: appBar(context, "EDUvian"),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: offWhite,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Center(
              child: Wrap(
                spacing: 10,

                runSpacing: 10,
                children: [
                  _buildSmallButton(
                    context,
                    icon: Icons.calculate,
                    label: 'Credit & Cost Calculator',
                    color: primaryColor,
                    onTap: "/credit",
                  ),

                  _buildSmallButton(
                    context,
                    icon: Icons.calculate,
                    label: 'GPA Calculator',
                    color: primaryColor,
                    onTap: "/gpa",
                  ),
                  _buildSmallButton(
                    context,
                    icon: Icons.calculate,
                    label: 'CGPA Calculator',
                    color: primaryColor,
                    onTap: "/cgpa",
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required String onTap,
  }) {
    return GestureDetector(
      onTap: () => context.push(onTap),
      child: Container(
        width: MediaQuery.of(context).size.width / 2 - 30,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: Colors.white),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
