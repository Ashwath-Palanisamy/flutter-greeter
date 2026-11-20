import 'package:material_ui/material_ui.dart';

class Rightpanel extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Container(
        decoration: BoxDecoration(border: Border.all(width: 3)),
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: .start,
          children: [Text('hello', style: TextStyle(color: Colors.white))],
        ),
      ),
    );
  }
}
