import 'package:flutter_greetd/components/arrow_keys.dart';
import 'package:material_ui/material_ui.dart';

class Centerpanel extends StatefulWidget {
  const new({super.key});

  @override
  State<Centerpanel> createState() => _CenterpanelState();
}

class _CenterpanelState extends State<Centerpanel> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Container(
        decoration: BoxDecoration(border: Border.all(width: 3)),
        padding: EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: .start,
          crossAxisAlignment: .center,

          children: [
            SizedBox(height: 16),
            CircleAvatar(
              radius: 40,
              backgroundColor: Color.fromARGB(255, 74, 68, 114),
              child: Icon(Icons.person, color: Colors.white, size: 42),
            ),
            SizedBox(height: 16),

            // Username selector
            Row(
              mainAxisAlignment: .center,
              crossAxisAlignment: .center,
              children: [
                // Left arrow
                ArrowKeys(
                  icon: Icons.arrow_left,
                  width: 36,
                  height: 36,
                  toolTip: 'switch user',
                ),

                // Selected username

                // will be passed from the wrapper or called via function to get usename of the profile
                SizedBox(width: 16),
                Text(
                  'username',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                SizedBox(width: 16),

                // right arrow
                ArrowKeys(
                  icon: Icons.arrow_right,
                  width: 36,
                  height: 36,
                  toolTip: 'switch user',
                ),
              ],
            ),
            SizedBox(height: 16),

            // Password field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Flexible(
                    child: TextField(
                      decoration: InputDecoration(border: OutlineInputBorder()),
                      obscureText: true,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),

                  // Password submit button
                  SizedBox(width: 8),
                  ArrowKeys(
                    icon: Icons.keyboard_arrow_right,
                    toolTip: 'Enter password',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
