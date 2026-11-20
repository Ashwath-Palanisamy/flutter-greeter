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
                Container(
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 74, 68, 114),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: IconButton(
                    onPressed: () {},
                    tooltip: 'switch user',
                    enableFeedback: true,
                    style: IconButton.styleFrom(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    icon: Icon(Icons.arrow_left),
                    iconSize: 20,
                    color: Colors.white,
                  ),
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
                Container(
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 74, 68, 114),
                    borderRadius: BorderRadius.circular(4),
                  ),

                  child: IconButton(
                    onPressed: () {},
                    tooltip: 'switch user',
                    enableFeedback: true,
                    style: IconButton.styleFrom(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    icon: Icon(Icons.arrow_right),
                    iconSize: 20,
                    color: Colors.white,
                  ),
                ),
              ],
            ), 
            SizedBox(height: 16),

            // Password field
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: TextField(
                    decoration: InputDecoration(border: OutlineInputBorder(),),
                    obscureText: true,
                    style: TextStyle(color: Colors.white),
                  ),
                ),

              ],
            ),
          ],
        ),
      ),
    );
  }
}
