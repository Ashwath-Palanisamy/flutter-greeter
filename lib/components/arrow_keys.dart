import 'package:material_ui/material_ui.dart';

class ArrowKeys extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final Color bgcolor;
  final double height;
  final double width;
  final String toolTip;
  final VoidCallback onTap;

  const new({
    super.key,
    required this.icon,
    this.iconSize = 20,
    this.bgcolor = const Color.fromARGB(255, 74, 68, 114),
    this.height = 50,
    this.width = 50,
    this.toolTip = '', required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: bgcolor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon),
        color: Colors.white,
        iconSize: iconSize,
        style: IconButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        
        tooltip: toolTip,
      ),
    );
  }
}
