import 'package:flutter/material.dart';
import 'package:pompa_benzina/widgets/animated_title.dart';

class ResponsiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onRefresh;
  final VoidCallback onSettings;

  const ResponsiveAppBar({
    Key? key,
    required this.onRefresh,
    required this.onSettings,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmallScreen = width < 600;

    return AppBar(
      leading: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 8.0 : 12.0),
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.contain,
        ),
      ),
      title: const Expanded(
        child: Center(child: AnimatedTitle()),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          iconSize: isSmallScreen ? 24 : 28,
          padding: EdgeInsets.all(isSmallScreen ? 8.0 : 12.0),
          onPressed: onRefresh,
        ),
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          iconSize: isSmallScreen ? 24 : 28,
          padding: EdgeInsets.all(isSmallScreen ? 8.0 : 12.0),
          onPressed: onSettings,
        ),
        SizedBox(width: isSmallScreen ? 8 : 16),
      ],
      centerTitle: true,
      elevation: 0,
      backgroundColor: Theme.of(context).primaryColor,
    );
  }
}
