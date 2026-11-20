import 'package:flutter_greetd/components/action_buttons.dart';
import 'package:material_ui/material_ui.dart';

class Leftpanel extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: 1,
      child: Container(
        decoration: BoxDecoration(border: Border.all(width: 3)),
        padding: EdgeInsets.all(8),
        child: Column(
          spacing: 16,
          mainAxisAlignment: .start,
          crossAxisAlignment: .center,
          mainAxisSize: .max,
          children: [
            // action buttons
            Text(
              'Control Center',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),

            // First row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                spacing: 32,
                children: [
                  ActionButtons(
                    name: 'Shutdown',
                    icon: Icons.power_settings_new,
                    color: Colors.red,
                  ),

                  ActionButtons(
                    name: 'restart',
                    icon: Icons.restart_alt,
                    color: Colors.amber,
                  ),
                ],
              ),
            ),

            // Second row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                spacing: 32,
                children: [
                  ActionButtons(
                    name: 'Sleep',
                    icon: Icons.bedtime_outlined,
                    color: Colors.blueAccent,
                  ),

                  ActionButtons(
                    name: 'Hibernate',
                    icon: Icons.ac_unit,
                    color: Colors.tealAccent,
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
