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
        return _StepTypeConfig(Icons.location_on, Colors.blue);
      case 'SNAPSHOT':
        return _StepTypeConfig(Icons.camera_alt, Colors.green);
      case 'QUEST':
        return _StepTypeConfig(Icons.quiz, Colors.purple);
      case 'OX_QUIZ':
        return _StepTypeConfig(Icons.check_circle, Colors.orange);
      case 'LIST':
        return _StepTypeConfig(Icons.checklist, Colors.teal);
      case 'BOARD':
        return _StepTypeConfig(Icons.dashboard, Colors.grey);
      case 'PANORAMA':
        return _StepTypeConfig(Icons.panorama, Colors.grey);
      case 'FACIAL':
        return _StepTypeConfig(Icons.face, Colors.grey);
      default:
        return _StepTypeConfig(Icons.help_outline, Colors.grey);
    }
  }
}

class _StepTypeConfig {
  final IconData icon;
  final Color color;

  const _StepTypeConfig(this.icon, this.color);
}
