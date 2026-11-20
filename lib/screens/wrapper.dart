import 'package:flutter_greetd/screens/login/loginwrapper.dart';
import 'package:flutter_greetd/screens/screensaver.dart';
import 'package:material_ui/material_ui.dart';

class Wrapper extends StatefulWidget {
  const new({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  bool isUnlocked = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Stack(children: [
      const Screensaver(),

      isUnlocked ? Center(child: Loginscreen()) : SizedBox.shrink()
    ]));
  }
}
