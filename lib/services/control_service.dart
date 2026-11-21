import 'dart:io';
import 'package:flutter/foundation.dart';

class ControlService {
  Future<String> controlServiceHelper(String state) async {
    debugPrint('[ControlService] controlServiceHelper called with state="$state"');

    String systemctlCmd;
    String successMessage;

    switch (state) {
      case 'shutdown':
        systemctlCmd = 'poweroff';
        successMessage = 'shutdown requested';
        break;
      case 'restart':
        systemctlCmd = 'reboot';
        successMessage = 'restart requested';
        break;
      case 'sleep':
        systemctlCmd = 'suspend';
        successMessage = 'sleep requested';
        break;
      case 'hibernate':
        systemctlCmd = 'hibernate';
        successMessage = 'hibernate requested';
        break;
      default:
        debugPrint('[ControlService] Unknown state: "$state"');
        return 'unknown state.';
    }

    final result = await _commandRunnerHelper(systemctlCmd);
    if (result == 'success') {
      return successMessage;
    }
    return 'unable to perform action';
  }

  Future<String> _commandRunnerHelper(String command) async {
    debugPrint('[ControlService] Running: systemctl $command');
    debugPrint(
      '[ControlService] Env check -> USER=${Platform.environment['USER']} '
      'XDG_RUNTIME_DIR=${Platform.environment['XDG_RUNTIME_DIR']} '
      'DBUS_SESSION_BUS_ADDRESS=${Platform.environment['DBUS_SESSION_BUS_ADDRESS']}',
    );

    try {
      final result = await Process.run('systemctl', [command]);
      debugPrint('[ControlService] systemctl $command -> exitCode=${result.exitCode}');
      debugPrint('[ControlService] stdout: ${result.stdout}');
      debugPrint('[ControlService] stderr: ${result.stderr}');

      if (result.exitCode == 0) {
        return 'success';
      }
      return 'Unable to $command. Is the permission set correctly?';
    } catch (e, stackTrace) {
      debugPrint('[ControlService] Exception running systemctl $command: $e');
      debugPrint('[ControlService] StackTrace: $stackTrace');
      return 'unable to process the $command command \n $e';
    }
  }
}