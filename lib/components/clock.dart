import 'dart:async';

import 'package:material_ui/material_ui.dart';

class Clock extends StatefulWidget {
  const new({super.key});

  @override
  State<Clock> createState() => _ClockState();
}

class _ClockState extends State<Clock> {
  late Timer _timer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final hours = _currentTime.hour.toString().padLeft(2,'0');
    final minutes = _currentTime.minute.toString().padLeft(2,'0');
    return Column(
      mainAxisAlignment: .center,
      crossAxisAlignment: .center,
      children: [
        Text(
          '$hours:$minutes',
          style: TextStyle(
            fontSize: 200,
            fontWeight: FontWeight.w300,
            color: Colors.white,
            letterSpacing: 4.0,
            fontFamily: 'Sigmatone',
          ),
        ),
      ],
    );
  }
}
