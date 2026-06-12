import 'package:flutter/material.dart';

class StepTypeIcon extends StatelessWidget {
  final String stepType;
  final double size;

  const StepTypeIcon({
    super.key,
    required this.stepType,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(stepType);
    return Container(
      width: size + 8,
      height: size + 8,
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        config.icon,
        color: config.color,
        size: size * 0.6,
      ),
    );
  }

  _StepTypeConfig _getConfig(String type) {
    switch (type.toUpperCase()) {
      case 'CHECKPOINT':
        return const _StepTypeConfig(Icons.location_on, Colors.blue);
      case 'SNAPSHOT':
        return const _StepTypeConfig(Icons.camera_alt, Colors.green);
      case 'QUEST':
        return const _StepTypeConfig(Icons.quiz, Colors.purple);
      case 'OX_QUIZ':
        return const _StepTypeConfig(Icons.check_circle, Colors.orange);
      case 'LIST':
        return const _StepTypeConfig(Icons.checklist, Colors.teal);
      case 'BOARD':
        return const _StepTypeConfig(Icons.dashboard, Colors.grey);
      case 'PANORAMA':
        return const _StepTypeConfig(Icons.panorama, Colors.grey);
      case 'FACIAL':
        return const _StepTypeConfig(Icons.face, Colors.grey);
      case 'GROUP_PHOTO':
        return const _StepTypeConfig(Icons.groups, Colors.green);
      case 'PARTY_MISSION':
        return const _StepTypeConfig(Icons.celebration, Colors.red);
      case 'RECEIPT':
        return const _StepTypeConfig(Icons.receipt_long, Colors.blue);
      default:
        return const _StepTypeConfig(Icons.help_outline, Colors.grey);
    }
  }
}

class _StepTypeConfig {
  final IconData icon;
  final Color color;

  const _StepTypeConfig(this.icon, this.color);
}
