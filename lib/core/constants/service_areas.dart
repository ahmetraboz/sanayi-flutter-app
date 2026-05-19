import 'package:flutter/material.dart';

class ServiceArea {
  final String value;
  final String label;
  final IconData icon;
  final Color bg;
  final Color color;

  const ServiceArea({
    required this.value,
    required this.label,
    required this.icon,
    required this.bg,
    required this.color,
  });
}

const kServiceAreas = [
  ServiceArea(value: 'motor', label: 'Motor', icon: Icons.local_fire_department_outlined, bg: Color(0xFFFEE2E2), color: Color(0xFFDC2626)),
  ServiceArea(value: 'elektrik', label: 'Elektrik', icon: Icons.bolt, bg: Color(0xFFFEF9C3), color: Color(0xFFCA8A04)),
  ServiceArea(value: 'fren', label: 'Fren', icon: Icons.album_outlined, bg: Color(0xFFFFEDD5), color: Color(0xFFEA580C)),
  ServiceArea(value: 'suspan', label: 'Süspansiyon', icon: Icons.tune, bg: Color(0xFFDBEAFE), color: Color(0xFF2563EB)),
  ServiceArea(value: 'kaporta', label: 'Kaporta', icon: Icons.format_paint_outlined, bg: Color(0xFFF3E8FF), color: Color(0xFF7C3AED)),
  ServiceArea(value: 'klima', label: 'Klima', icon: Icons.ac_unit, bg: Color(0xFFCFFAFE), color: Color(0xFF0891B2)),
  ServiceArea(value: 'lastik', label: 'Lastik', icon: Icons.tire_repair, bg: Color(0xFFF1F5F9), color: Color(0xFF475569)),
  ServiceArea(value: 'vites', label: 'Vites', icon: Icons.settings_outlined, bg: Color(0xFFE0E7FF), color: Color(0xFF4F46E5)),
  ServiceArea(value: 'egzoz', label: 'Egzoz', icon: Icons.cloud_outlined, bg: Color(0xFFD1FAE5), color: Color(0xFF059669)),
  ServiceArea(value: 'diger', label: 'Diğer', icon: Icons.help_outline, bg: Color(0xFFF3F4F6), color: Color(0xFF6B7280)),
];

ServiceArea? findServiceArea(String value) {
  try {
    return kServiceAreas.firstWhere((a) => a.value == value);
  } catch (_) {
    return null;
  }
}
