import 'dart:io';

class WaylandSessionService {
  static const _directories = [
    '/usr/share/wayland-sessions',
    '/usr/local/share/wayland-sessions',
  ];

  Future<List<({String name, List<String> command})>>
      loadWaylandSessions() async {
    final found = <String, ({String name, List<String> command})>{};

    for (final path in _directories) {
      final directory = Directory(path);
      if (!await directory.exists()) continue;

      await for (final entity in directory.list()) {
        if (entity is! File || !entity.path.endsWith('.desktop')) continue;

        try {
          final session = await _readDesktopEntry(entity);
          if (session == null) continue;

          found[entity.uri.pathSegments.last] = session;
        } on FormatException {
          // Skip unsupported or malformed entries.
        } on FileSystemException {
          // Skip entries that cannot be read.
        }
      }
    }

    final sessions = found.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return sessions;
  }

  Future<({String name, List<String> command})?> _readDesktopEntry(
    File file,
  ) async {
    final lines = await file.readAsLines();
    String? name;
    String? exec;
    var hidden = false;
    var inDesktopEntry = false;

    for (final rawLine in lines) {
      final line = rawLine.trim();

      if (line.startsWith('[')) {
        inDesktopEntry = line == '[Desktop Entry]';
        continue;
      }

      if (!inDesktopEntry || line.isEmpty || line.startsWith('#')) continue;

      final separator = line.indexOf('=');
      if (separator < 0) continue;

      final key = line.substring(0, separator);
      final value = line.substring(separator + 1).trim();

      switch (key) {
        case 'Name':
          name = value;
          break;
        case 'Exec':
          exec = value;
          break;
        case 'Hidden':
          hidden = value.toLowerCase() == 'true';
          break;
      }
    }

    if (hidden || name == null || name.isEmpty || exec == null || exec.isEmpty) {
      return null;
    }

    final command = _parseExec(exec);
    if (command.isEmpty) return null;

    return (name: name, command: command);
  }

  List<String> _parseExec(String exec) {
    final args = <String>[];
    final current = StringBuffer();
    var inQuotes = false;
    var escaping = false;
    var tokenStarted = false;

    for (var i = 0; i < exec.length; i++) {
      final char = exec[i];

      if (escaping) {
        current.write(char);
        escaping = false;
        tokenStarted = true;
        continue;
      }

      if (char == r'\') {
        escaping = true;
        tokenStarted = true;
        continue;
      }

      if (char == '"') {
        inQuotes = !inQuotes;
        tokenStarted = true;
        continue;
      }

      if (char == '%' && i + 1 < exec.length && exec[i + 1] == '%') {
        current.write('%');
        tokenStarted = true;
        i++;
        continue;
      }

      if (char == '%') {
        throw const FormatException('Exec contains a field code');
      }

      if (!inQuotes && char.trim().isEmpty) {
        if (tokenStarted) {
          args.add(current.toString());
          current.clear();
          tokenStarted = false;
        }
        continue;
      }

      current.write(char);
      tokenStarted = true;
    }

    if (escaping || inQuotes) {
      throw const FormatException('Exec has unmatched quoting or escaping');
    }

    if (tokenStarted) args.add(current.toString());
    return args;
  }
}
