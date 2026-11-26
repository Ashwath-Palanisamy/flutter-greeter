import 'package:material_ui/material_ui.dart';

class ActionButtons extends StatefulWidget {
  final String name;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const new({
    super.key,
    required this.name,
    required this.icon,
    required this.color, required this.onTap,
  });

  @override
  State<ActionButtons> createState() => _ActionButtonsState();
}

class _ActionButtonsState extends State<ActionButtons> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      // Pop animation
      duration: Duration(milliseconds: 150),
      curve: Curves.easeOut,
      scale: isHovered ? 1.06 : 1.0,
      child: Container(
        // outer box decoration
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: widget.color,
        ),

        child: Tooltip(
          // Tooltip to show on hover
          message: widget.name,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onHover: (value) {
              setState(() {
                isHovered = value;
              });
            },
            onTap: widget.onTap,

            child: Icon(widget.icon, size: 32),
          ),
        ),
      ),
    );
  }
}
