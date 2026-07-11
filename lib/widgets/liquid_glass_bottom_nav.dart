import 'package:flutter/material.dart';
import 'package:sbg_profesores/theme/app_colors.dart';
import 'package:sbg_profesores/widgets/liquid_glass_panel.dart';

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
  @override
  Widget build(BuildContext context) {
    final usableWidth = MediaQuery.sizeOf(context).width > 24
        ? MediaQuery.sizeOf(context).width - 24
        : MediaQuery.sizeOf(context).width;
    final expandedWidth = usableWidth > 540 ? 540.0 : usableWidth;
    const barHeight = 78.0;
    const radius = BorderRadius.all(Radius.circular(32));

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
          child: LiquidGlassPanel(
            width: expandedWidth,
            height: barHeight,
            borderRadius: radius,
            opacity: 0.78,
            blurSigma: 22,
            borderColor: Colors.white.withValues(alpha: 0.16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
            child: Stack(
              children: [
                Material(
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 7,
                    ),
                    child: Row(
                      children: [
                        for (final action in actions)
                          Expanded(
                            child: _LiquidNavButton(
                              action: action,
                              expanded: true,
                            ),
                          ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                ),
                _AnimatedIndicator(
                  selectedIndex: widget.currentIndex,
                  itemCount: actions.length,
                  barHeight: barHeight,
                ),
              ],
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
    final iconColor = action.selected
        ? kPrimary
        : action.isLogout
        ? Colors.white
        : Colors.white;
    final labelColor = action.selected
        ? Colors.white
        : action.isLogout
        ? Colors.white
        : Colors.white;

    return Tooltip(
      message: action.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: action.onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: action.selected
                    ? _alpha(Colors.white, 0.15)
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: action.selected
                      ? Colors.white.withValues(alpha: 0.4)
                      : Colors.transparent,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(action.icon, color: iconColor, size: 20),
            ),
            Padding(
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
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedIndicator extends StatelessWidget {
  const _AnimatedIndicator({
    required this.selectedIndex,
    required this.itemCount,
    required this.barHeight,
  });

  final int selectedIndex;
  final int itemCount;
  final double barHeight;

  @override
  Widget build(BuildContext context) {
    final itemWidth = 1.0 / itemCount;
    final selectedPosition = selectedIndex * itemWidth;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: 3,
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            left: selectedPosition * MediaQuery.sizeOf(context).width * 0.95,
            right:
                (1 - selectedPosition - itemWidth) *
                MediaQuery.sizeOf(context).width *
                0.95,
            bottom: 6,
            height: 3,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1.5),
                color: kPrimary,
                boxShadow: [
                  BoxShadow(
                    color: kPrimary.withValues(alpha: 0.6),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ],
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
