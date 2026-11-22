import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/ds.dart';

/// Bottom bar of the agreed design: Home, Trends, Scan, Profile.
/// Scan opens the scan flow instead of switching tab.
class BottomNav extends StatelessWidget {
  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onScan,
  });

  /// 0 = Home, 1 = Trends, 2 = Profile.
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: DS.navy.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Item(
                label: 'Home'.tr,
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                selected: currentIndex == 0,
                onTap: () => onTabSelected(0),
              ),
              _Item(
                label: 'Trends'.tr,
                icon: Icons.show_chart_rounded,
                activeIcon: Icons.show_chart_rounded,
                selected: currentIndex == 1,
                onTap: () => onTabSelected(1),
              ),
              _Item(
                label: 'Scan'.tr,
                icon: Icons.document_scanner_outlined,
                activeIcon: Icons.document_scanner_outlined,
                selected: false,
                onTap: onScan,
              ),
              _Item(
                label: 'Profile'.tr,
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                selected: currentIndex == 2,
                onTap: () => onTabSelected(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? DS.navy : DS.iconMuted;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 76, minHeight: 56),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? activeIcon : icon, size: 26, color: color),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: DS.text(
                    size: 12.5,
                    weight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: color,
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
