import 'dart:ui';

import 'package:flutter_greetd/components/clock.dart';
import 'package:material_ui/material_ui.dart';

class Screensaver extends StatefulWidget {
  const new({super.key});

  @override
  State<Screensaver> createState() => _ScreensaverState();
}

class _ScreensaverState extends State<Screensaver> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Transform.scale(
          scaleX: 1.3,
          scaleY: 1.3,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Image.asset('assets/images/bg_image.jpg', fit: BoxFit.cover),
          ),
        ),

        Container(color: Colors.black.withAlpha(2)),

        Center(child: Clock()),
      ],
    );
  }
}
