import 'package:flutter/material.dart';
import 'package:frontend/core/movil/theme.dart';
import 'package:frontend/screens/movil/home/home_tab.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.current, required this.onSelected});

  final HomeTab current;
  final ValueChanged<HomeTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
        child: Container(
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(26),
            boxShadow: AppShadows.cardStrong,
          ),
          child: Row(
            children: [
              for (final tab in HomeTab.values)
                Expanded(
                  child: _NavItem(
                    tab: tab,
                    selected: tab == current,
                    onTap: () => onSelected(tab),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final HomeTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.wine : AppColors.inkSoft;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: AppColors.wineSoft.withAlpha(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.wineSoft.withAlpha(16) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Icon(
                  tab.icon,
                  key: ValueKey('${tab.name}-$selected'),
                  size: 22,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}