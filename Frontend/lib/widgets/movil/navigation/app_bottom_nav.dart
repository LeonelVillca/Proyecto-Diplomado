import 'package:flutter/material.dart';
import 'package:frontend/core/movil/consumer_design.dart';
import 'package:frontend/screens/movil/home/home_tab.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.current,
    required this.onSelected,
  });
  final HomeTab current;
  final ValueChanged<HomeTab> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: ConsumerColors.card,
      border: Border(top: BorderSide(color: ConsumerColors.line)),
    ),
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 62,
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
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    label: tab.label,
    child: InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 3,
            decoration: BoxDecoration(
              color: selected ? ConsumerColors.wine : Colors.transparent,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 8),
          Icon(
            tab.icon,
            size: 21,
            color: selected ? ConsumerColors.wine : ConsumerColors.inkSoft,
          ),
          const SizedBox(height: 3),
          Text(
            tab.label,
            style: TextStyle(
              fontFamily: 'InstrumentSans',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: selected ? ConsumerColors.wine : ConsumerColors.inkSoft,
            ),
          ),
        ],
      ),
    ),
  );
}
