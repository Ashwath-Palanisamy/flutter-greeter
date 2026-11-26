import 'dart:io';
import 'package:flutter_greetd/components/arrow_keys.dart';
import 'package:flutter_greetd/services/login_service.dart';
import 'package:flutter_greetd/services/wayland_session_service.dart';
import 'package:material_ui/material_ui.dart';

typedef WaylandSession = ({String name, List<String> command});

class Centerpanel extends StatefulWidget {
  const new({super.key});

  @override
  State<Centerpanel> createState() => _CenterpanelState();
}

class _CenterpanelState extends State<Centerpanel> {
  final TextEditingController _passwordController = TextEditingController();

  List<String> _usernames = [];
  int _selectedIndex = 0;
  bool _isLoading = true;

  List<WaylandSession> _waylandSessions = [];
  int _waylandSelectedIndex = 0;
  bool _isWaylandLoading = true;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadUsernames();
    _loadWaylandSession();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
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

  void _loadWaylandSession() {
    WaylandSessionService().loadWaylandSessions().then((value) {
      if (!mounted) return;
      setState(() {
        _waylandSessions = value;
        _waylandSelectedIndex = 0;
        _isWaylandLoading = false;
      });
    });
  }

  void _selectPreviousUser() {
    if (_usernames.isEmpty) return;
    setState(() {
      _selectedIndex =
          (_selectedIndex - 1 + _usernames.length) % _usernames.length;
    });
  }

  void _selectNextUser() {
    if (_usernames.isEmpty) return;
    setState(() {
      _selectedIndex = (_selectedIndex + 1) % _usernames.length;
    });
  }

  String get _displayedUsername {
    if (_isLoading) return 'Loading...';
    if (_usernames.isEmpty) return 'No users found';
    if (_selectedIndex < 0 || _selectedIndex >= _usernames.length) {
      return _usernames.first;
    }
    return _usernames[_selectedIndex];
  }

  WaylandSession? get _selectedSession {
    if (_waylandSessions.isEmpty) return null;
    if (_waylandSelectedIndex < 0 ||
        _waylandSelectedIndex >= _waylandSessions.length) {
      return _waylandSessions.first;
    }
    return _waylandSessions[_waylandSelectedIndex];
  }

  Future<void> _submitLogin() async {
    if (_usernames.isEmpty || _isLoading || _isSubmitting) return;

    final int safeIndex =
        (_selectedIndex < 0 || _selectedIndex >= _usernames.length)
        ? 0
        : _selectedIndex;
    final String username = _usernames[safeIndex];
    final String password = _passwordController.text;
    final WaylandSession? session = _selectedSession;

    if (session == null || session.command.isEmpty) {
      debugPrint('No Wayland session selected or available.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final LoginResult result = await LoginService().loginuser(
        username,
        password,
        sessionCmd: session.command,
      );

      if (!mounted) return;

      switch (result) {
        case LoginSuccess():
          debugPrint('Login succeeded for $username');
          exit(0);
        case LoginFailure(:final message):
          _passwordController.clear();
          debugPrint('Login failed: $message');
          setState(() {
            _isSubmitting = false;
          });
        case LoginCancelled():
          _passwordController.clear();
          debugPrint('Login cancelled');
          setState(() {
            _isSubmitting = false;
          });
      }
    } on ArgumentError catch (e) {
      if (!mounted) return;
      _passwordController.clear();
      debugPrint('Invalid login arguments: $e');
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<DropdownMenuItem<int>> sessionItems = [
      for (int i = 0; i < _waylandSessions.length; i++)
        DropdownMenuItem<int>(
          value: i,
          child: Text(
            _waylandSessions[i].name,
            style: const TextStyle(color: Colors.white),
          ),
        ),
    ];

    final int? currentSessionValue =
        sessionItems.isNotEmpty &&
            _waylandSelectedIndex >= 0 &&
            _waylandSelectedIndex < sessionItems.length
        ? _waylandSelectedIndex
        : null;

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
                ArrowKeys(
                  icon: Icons.arrow_left,
                  width: 36,
                  height: 36,
                  toolTip: 'Previous user',
                  onTap: () {
                    if (!_isSubmitting) _selectPreviousUser();
                  },
                ),
                const SizedBox(width: 16),
                Text(
                  _displayedUsername,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(width: 16),
                ArrowKeys(
                  icon: Icons.arrow_right,
                  width: 36,
                  height: 36,
                  toolTip: 'Next user',
                  onTap: () {
                    if (!_isSubmitting) _selectNextUser();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Password field + submit
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Flexible(
                    child: TextField(
                      controller: _passwordController,
                      enabled: !_isSubmitting,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock, color: Colors.white),
                      ),
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      onSubmitted: (_) => _submitLogin(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ArrowKeys(
                    icon: Icons.keyboard_arrow_right,
                    toolTip: 'Enter password',
                    onTap: () {
                      if (!_isSubmitting) _submitLogin();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Wayland session selector
            if (_isWaylandLoading)
              const Text(
                'Loading sessions...',
                style: TextStyle(color: Colors.white70),
              )
            else if (sessionItems.isEmpty)
              const Text(
                'No sessions found',
                style: TextStyle(color: Colors.white70),
              )
            else
              DropdownButton<int>(
                value: currentSessionValue,
                dropdownColor: const Color.fromARGB(255, 40, 38, 56),
                items: sessionItems,
                onChanged: _isSubmitting
                    ? null
                    : (int? newIndex) {
                        if (newIndex == null) return;
                        setState(() {
                          _waylandSelectedIndex = newIndex;
                        });
                      },
              ),
          ],
        ),
      ),
    );
  }
}
