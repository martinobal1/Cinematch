import 'package:flutter/material.dart';

import '../config/avatar_presets.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.avatarId,
    this.radius = 20,
    this.onTap,
  });

  final String avatarId;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final preset = avatarPresetById(avatarId);

    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: preset.color.withValues(alpha: 0.25),
      child: Icon(preset.icon, color: preset.color, size: radius),
    );

    if (onTap == null) return avatar;

    return GestureDetector(onTap: onTap, child: avatar);
  }
}
