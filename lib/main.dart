import 'package:flutter_greetd/screens/wrapper.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Wrapper(),
    
    );
  }
}
