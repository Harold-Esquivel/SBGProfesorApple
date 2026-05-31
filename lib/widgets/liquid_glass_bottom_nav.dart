import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sbg_profesores/theme/app_colors.dart';
import 'package:sbg_profesores/theme/app_theme.dart';

Color _alpha(Color color, double value) => color.withValues(alpha: value);

class LiquidGlassNavDestination {
  const LiquidGlassNavDestination({
    required this.icon,
    required this.label,
    required this.index,
  });

  final IconData icon;
  final String label;
  final int index;
}

class LiquidGlassBottomNav extends StatefulWidget {
  const LiquidGlassBottomNav({
    super.key,
    required this.destinations,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.onLogoutPressed,
    this.logoutLabel = 'Salir',
  });

  final List<LiquidGlassNavDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final Future<void> Function() onLogoutPressed;
  final String logoutLabel;

  @override
  State<LiquidGlassBottomNav> createState() => _LiquidGlassBottomNavState();
}

class _LiquidGlassBottomNavState extends State<LiquidGlassBottomNav> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final usableWidth = MediaQuery.sizeOf(context).width > 24
        ? MediaQuery.sizeOf(context).width - 24
        : MediaQuery.sizeOf(context).width;
    final expandedWidth = usableWidth > 540 ? 540.0 : usableWidth;
    final actionCount = widget.destinations.length + 1;
    final collapsedTargetWidth = actionCount * 48.0 + 52.0;
    final collapsedWidth = collapsedTargetWidth > usableWidth
        ? usableWidth
        : collapsedTargetWidth;
    final barWidth = _expanded ? expandedWidth : collapsedWidth;
    final barHeight = _expanded ? 78.0 : 58.0;
    final radius = BorderRadius.circular(_expanded ? 34 : 29);
    final borderColor = _alpha(Colors.white, context.isDarkMode ? 0.18 : 0.42);
    final topGlass = _alpha(Colors.white, context.isDarkMode ? 0.16 : 0.36);
    final bottomGlass = _alpha(Colors.white, context.isDarkMode ? 0.08 : 0.18);

    final actions = <_LiquidNavAction>[
      for (final destination in widget.destinations)
        _LiquidNavAction(
          icon: destination.icon,
          label: destination.label,
          selected: widget.currentIndex == destination.index,
          onTap: () => widget.onDestinationSelected(destination.index),
        ),
      _LiquidNavAction(
        icon: Icons.logout_rounded,
        label: widget.logoutLabel,
        selected: false,
        isLogout: true,
        onTap: () async => widget.onLogoutPressed(),
      ),
    ];

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: SizedBox(
        height: barHeight,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            width: barWidth,
            height: barHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                boxShadow: [
                  BoxShadow(
                    color: _alpha(
                      Colors.black,
                      context.isDarkMode ? 0.34 : 0.22,
                    ),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: radius,
                            border: Border.all(color: borderColor),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [topGlass, bottomGlass],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 1,
                        left: 22,
                        right: 22,
                        child: Container(
                          height: 1.2,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: LinearGradient(
                              colors: [
                                _alpha(Colors.white, 0),
                                _alpha(Colors.white, 0.82),
                                _alpha(Colors.white, 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: _expanded ? 8 : 6,
                          vertical: 7,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: Row(
                            children: [
                              for (final action in actions)
                                Expanded(
                                  child: _LiquidNavButton(
                                    action: action,
                                    expanded: _expanded,
                                  ),
                                ),
                              const SizedBox(width: 4),
                              _FoldButton(
                                expanded: _expanded,
                                onTap: () {
                                  setState(() => _expanded = !_expanded);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LiquidNavButton extends StatelessWidget {
  const _LiquidNavButton({required this.action, required this.expanded});

  final _LiquidNavAction action;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final selectedFill = _alpha(Colors.white, context.isDarkMode ? 0.22 : 0.82);
    final iconColor = action.selected
        ? kPrimary
        : action.isLogout
        ? _alpha(Colors.white, 0.88)
        : _alpha(Colors.white, 0.94);
    final labelColor = action.selected
        ? Colors.white
        : action.isLogout
        ? _alpha(Colors.white, 0.82)
        : _alpha(Colors.white, 0.84);

    return Tooltip(
      message: action.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: action.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(horizontal: expanded ? 3 : 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: expanded ? 34 : 40,
                height: expanded ? 34 : 40,
                decoration: BoxDecoration(
                  color: action.selected ? selectedFill : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: action.selected
                        ? _alpha(Colors.white, 0.62)
                        : _alpha(Colors.white, 0.08),
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  action.icon,
                  color: iconColor,
                  size: expanded ? 20 : 21,
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: expanded
                    ? Padding(
                        key: const ValueKey('label'),
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          action.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: labelColor,
                            fontSize: 10,
                            height: 1,
                            fontWeight: action.selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('compact')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FoldButton extends StatelessWidget {
  const _FoldButton({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: expanded ? 'Plegar barra' : 'Expandir barra',
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _alpha(Colors.white, context.isDarkMode ? 0.12 : 0.24),
            shape: BoxShape.circle,
            border: Border.all(color: _alpha(Colors.white, 0.22)),
          ),
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: Icon(
              expanded
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.keyboard_arrow_up_rounded,
              key: ValueKey(expanded),
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class _LiquidNavAction {
  const _LiquidNavAction({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.isLogout = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isLogout;
}
