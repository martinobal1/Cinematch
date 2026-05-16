import 'package:flutter/material.dart';

class AvatarPreset {
  const AvatarPreset({
    required this.id,
    required this.icon,
    required this.color,
    required this.label,
  });

  final String id;
  final IconData icon;
  final Color color;
  final String label;
}

const avatarPresets = <AvatarPreset>[
  AvatarPreset(id: 'popcorn', icon: Icons.movie_rounded, color: Color(0xFFE50914), label: 'Film'),
  AvatarPreset(id: 'star', icon: Icons.star_rounded, color: Color(0xFFF5C518), label: 'Hviezda'),
  AvatarPreset(id: 'clapper', icon: Icons.movie_filter_rounded, color: Color(0xFF9C27B0), label: 'Klapa'),
  AvatarPreset(id: 'ticket', icon: Icons.local_movies_rounded, color: Color(0xFF3399FF), label: 'Lístok'),
  AvatarPreset(id: 'director', icon: Icons.videocam_rounded, color: Color(0xFF4CAF50), label: 'Kamera'),
  AvatarPreset(id: 'mask', icon: Icons.theater_comedy_rounded, color: Color(0xFFFF9800), label: 'Komédia'),
  AvatarPreset(id: 'horror', icon: Icons.nightlight_round, color: Color(0xFF607D8B), label: 'Noc'),
  AvatarPreset(id: 'heart', icon: Icons.favorite_rounded, color: Color(0xFFE91E63), label: 'Romantika'),
  AvatarPreset(id: 'rocket', icon: Icons.rocket_launch_rounded, color: Color(0xFF00BCD4), label: 'Sci-fi'),
  AvatarPreset(id: 'crown', icon: Icons.workspace_premium_rounded, color: Color(0xFFFFD700), label: 'Top'),
  AvatarPreset(id: 'ghost', icon: Icons.auto_awesome, color: Color(0xFF7E57C2), label: 'AI'),
  AvatarPreset(id: 'user', icon: Icons.person_rounded, color: Color(0xFF78909C), label: 'Klasik'),
];

AvatarPreset avatarPresetById(String? id) {
  if (id == null) return avatarPresets.last;
  return avatarPresets.firstWhere(
    (p) => p.id == id,
    orElse: () => avatarPresets.last,
  );
}
