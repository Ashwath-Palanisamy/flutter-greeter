import 'package:flutter_greetd/components/arrow_keys.dart';
import 'package:flutter_greetd/services/login_service.dart';
import 'package:material_ui/material_ui.dart';

class Centerpanel extends StatefulWidget {
  const new({super.key});

  @override
  State<Centerpanel> createState() => _CenterpanelState();
}

class _CenterpanelState extends State<Centerpanel> {
  List<String> _usernames = [];
  int _selectedIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsernames();
  }

  void _loadUsernames() {
    LoginService().loadUsernames().then((value) {
      if (!mounted) return;
      setState(() {
        _usernames = value;
        _selectedIndex = 0;
        _isLoading = false;
      });
    });
  }

  String get _displayedUsername {
    if (_isLoading) return 'Loading...';
    if (_usernames.isEmpty) return 'No users found';
    return _usernames[_selectedIndex];
  }

  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Container(
        decoration: BoxDecoration(border: Border.all(width: 3)),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            const CircleAvatar(
              radius: 40,
              backgroundColor: Color.fromARGB(255, 74, 68, 114),
              child: Icon(Icons.person, color: Colors.white, size: 42),
            ),
            const SizedBox(height: 16),

            // Username selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left arrow
                ArrowKeys(
                  icon: Icons.arrow_left,
                  width: 36,
                  height: 36,
                  toolTip: 'switch user',
                  onTap: () {
                    _selectedIndex - 1;
                  },
                ),

                // show Selected username
                const SizedBox(width: 16),
                Text(
                  _displayedUsername,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
                const SizedBox(width: 16),

                // Right arrow
                ArrowKeys(
                  icon: Icons.arrow_right,
                  width: 36,
                  height: 36,
                  toolTip: 'switch user',
                  onTap: () {
                    _selectedIndex + 1;
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Password field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                
                children: [
                  Flexible(
                    child: TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock, color: Colors.white),
                      ),
                      obscureText: true,
                      style: TextStyle(color: Colors.white),
                      onSubmitted: (value) {},
                    ),
                  ),

                  // Password submit button
                  const SizedBox(width: 8),
                  ArrowKeys(
                    icon: Icons.keyboard_arrow_right,
                    toolTip: 'Enter password',
                    onTap: () {
                      
                    },
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
