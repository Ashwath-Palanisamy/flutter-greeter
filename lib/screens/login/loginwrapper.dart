import 'package:flutter_greetd/screens/login/centerpanel.dart';
import 'package:flutter_greetd/screens/login/leftpanel.dart';
import 'package:flutter_greetd/screens/login/rightpanel.dart';
import 'package:material_ui/material_ui.dart';

class Loginscreen extends StatefulWidget {
  const new({super.key});

  @override
  State<Loginscreen> createState() => _LoginscreenState();
}

class _LoginscreenState extends State<Loginscreen> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth * 0.65,
          height: constraints.maxHeight * 0.52,
          decoration: BoxDecoration(
            color: Color(0xFF2E2B44),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: .start,
            crossAxisAlignment: .center,
            children: [
              // Left side Elements
              Leftpanel(),
              

              VerticalDivider(),
              // Center Elements
              Centerpanel(),
              VerticalDivider(),
              Rightpanel(),
              
            ],
          ),
        );
      },
    );
  }
}
