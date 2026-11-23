import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:material_ui/material_ui.dart';

sealed class LoginResult {
  const LoginResult();
}

final class LoginSuccess extends LoginResult {
  const LoginSuccess();
}

final class LoginCancelled extends LoginResult {
  const LoginCancelled();
}

final class LoginFailure extends LoginResult {
  final String? errorType;
  final String message;
  final Object? cause;

  const LoginFailure({this.errorType, required this.message, this.cause});
}

class GreetdProtocolException implements Exception {
  final String? errorType;
  final String description;

  const GreetdProtocolException({this.errorType, required this.description});

  @override
  String toString() =>
      'GreetdProtocolException(type: $errorType, description: $description)';
}

class LoginService {
  final int minUID;
  final int maxUID;
  List<String> usernames = [];

  LoginService({this.minUID = 1000, this.maxUID = 65534}) {
    if (minUID < 0) {
      throw ArgumentError.value(minUID, 'minUID', 'must be non-negative');
    }
    if (maxUID <= minUID) {
      throw ArgumentError.value(
        maxUID,
        'maxUID',
        'must be greater than minUID ($minUID)',
      );
    }
  }

  Future<List<String>> loadUsernames() async {
    final result = await Process.run('getent', ['passwd']);

    if (result.exitCode != 0) {
      throw ProcessException(
        'getent',
        ['passwd'],
        'Failed to retrieve account list',
        result.exitCode,
      );
    }

    final found = <String>[];

    for (final line in (result.stdout as String).split('\n')) {
      if (line.isEmpty) continue;

      final fields = line.split(':');
      if (fields.length < 7) continue;

      final uid = int.tryParse(fields[2]);
      if (uid == null || uid < minUID || uid >= maxUID) continue;

      found.add(fields[0]);
    }

    usernames = found;
    return usernames;
  }

  void _validateLoginInputs(
    String username,
    String socketPath,
    List<String> sessionCmd,
    List<String> sessionEnv,
  ) {
    if (socketPath.isEmpty) {
      throw StateError(
        'GREETD_SOCK is not set. Cannot connect to greetd outside an active greetd session.',
      );
    }
    if (username.trim().isEmpty) {
      throw ArgumentError.value(
        username,
        'username',
        'must not be empty or whitespace-only',
      );
    }
    if (sessionCmd.isEmpty) {
      throw ArgumentError.value(sessionCmd, 'sessionCmd', 'must not be empty');
    }
    for (var i = 0; i < sessionCmd.length; i++) {
      if (sessionCmd[i].isEmpty) {
        throw ArgumentError.value(
          sessionCmd[i],
          'sessionCmd[$i]',
          'command argument must not be empty',
        );
      }
    }
    for (var i = 0; i < sessionEnv.length; i++) {
      final entry = sessionEnv[i];
      final eqIndex = entry.indexOf('=');
      if (eqIndex <= 0) {
        throw ArgumentError.value(
          entry,
          'sessionEnv[$i]',
          'must be formatted as KEY=VALUE with a non-empty key',
        );
      }
    }
  }

  Future<void> _sendGreetdMessage(
    Socket socket,
    Map<String, dynamic> payload,
  ) async {
    final String jsonPayload = jsonEncode(payload);
    final Uint8List payloadBytes = utf8.encode(jsonPayload);

    final ByteData headerData = ByteData(4);
    headerData.setUint32(0, payloadBytes.length, Endian.host);
    final Uint8List headerBytes = headerData.buffer.asUint8List();

    final builder = BytesBuilder(copy: false)
      ..add(headerBytes)
      ..add(payloadBytes);

    socket.add(builder.takeBytes());
    await socket.flush();
  }

  Future _readGreetdMessage(
    StreamIterator<Uint8List> streamIterator,
    BytesBuilder buffer,
  ) async {
    int? expectedPayloadLength;

    while (true) {
      if (expectedPayloadLength == null && buffer.length >= 4) {
        final bytes = buffer.takeBytes();
        final headerView = ByteData.sublistView(bytes, 0, 4);
        expectedPayloadLength = headerView.getUint32(0, Endian.host);

        if (bytes.length > 4) {
          buffer.add(bytes.sublist(4));
        }
      }

      if (expectedPayloadLength != null &&
          buffer.length >= expectedPayloadLength) {
        final bytes = buffer.takeBytes();
        final payloadBytes = bytes.sublist(0, expectedPayloadLength);

        if (bytes.length > expectedPayloadLength) {
          buffer.add(bytes.sublist(expectedPayloadLength));
        }

        final jsonString = utf8.decode(payloadBytes);
        final decoded = jsonDecode(jsonString);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        throw GreetdProtocolException(
          description: 'Expected JSON object from greetd, got: $decoded',
        );
      }

      final hasNext = await streamIterator.moveNext();
      if (!hasNext) {
        throw StateError(
          'greetd socket closed before a complete message arrived.',
        );
      }

      buffer.add(streamIterator.current);
    }
  }

  String _requireMessageType(Map<String, dynamic> message, String phase) {
    final rawType = message['type'];
    if (rawType is! String || rawType.isEmpty) {
      throw GreetdProtocolException(
        description:
            'Missing or invalid "type" in greetd $phase reply: $message',
      );
    }
    return rawType;
  }

  GreetdProtocolException _parseErrorReply(
    Map<String, dynamic> message,
    String phase,
  ) {
    final rawErrorType = message['error_type'];
    if (rawErrorType != null && rawErrorType is! String) {
      throw GreetdProtocolException(
        description:
            'Invalid "error_type" field in greetd $phase error reply: $message',
      );
    }

    final rawDescription = message['description'];
    if (rawDescription != null && rawDescription is! String) {
      throw GreetdProtocolException(
        description:
            'Invalid "description" field in greetd $phase error reply: $message',
      );
    }

    final String? errorType = (rawErrorType == null || rawErrorType.isEmpty)
        ? null
        : rawErrorType;
    final String description =
        (rawDescription == null || rawDescription.isEmpty)
        ? 'greetd reported an error during $phase'
        : rawDescription;

    return GreetdProtocolException(
      errorType: errorType,
      description: description,
    );
  }

  Future<void> _tryCancelSession(
    Socket socket,
    StreamIterator<Uint8List> streamIterator,
    BytesBuilder receiveBuffer,
  ) async {
    try {
      await _sendGreetdMessage(socket, {'type': 'cancel_session'});
      final reply = await _readGreetdMessage(streamIterator, receiveBuffer);
      final replyType = _requireMessageType(reply, 'cancel_session');
      if (replyType == 'error') {
        final err = _parseErrorReply(reply, 'cancel_session');
        debugPrint('cancel_session error reply: $err');
      }
    } catch (e) {
      debugPrint('cancel_session cleanup note: $e');
    }
  }

  Future<void> _closeSocketSafely(Socket? socket) async {
    if (socket == null) return;
    try {
      await socket.close();
    } catch (e) {
      debugPrint('socket close error: $e');
      try {
        socket.destroy();
      } catch (_) {}
    }
  }

  Future<LoginResult> loginuser(
    String username,
    String password, {
    required List<String> sessionCmd,
    List<String> sessionEnv = const [],
    Future<String?> Function(String authMessageType, String authMessage)?
    onAuthMessage,
    Future<bool> Function()? isCancelled,
  }) async {
    Socket? socket;
    StreamIterator<Uint8List>? streamIterator;
    BytesBuilder? receiveBuffer;
    bool sessionActive = false;
    bool authSucceeded = false;

    try {
      final socketPath = Platform.environment['GREETD_SOCK'] ?? '';
      _validateLoginInputs(username, socketPath, sessionCmd, sessionEnv);

      final address = InternetAddress(
        socketPath,
        type: InternetAddressType.unix,
      );
      socket = await Socket.connect(address, 0);
      streamIterator = StreamIterator<Uint8List>(socket);
      receiveBuffer = BytesBuilder(copy: false);

      await _sendGreetdMessage(socket, {
        'type': 'create_session',
        'username': username,
      });

      final createReply = await _readGreetdMessage(
        streamIterator,
        receiveBuffer,
      );
      final createType = _requireMessageType(createReply, 'create_session');

      if (createType == 'error') {
        final err = _parseErrorReply(createReply, 'create_session');
        return LoginFailure(
          errorType: err.errorType,
          message: err.description,
          cause: err,
        );
      }

      if (createType != 'auth_message' && createType != 'success') {
        throw GreetdProtocolException(
          description:
              'Unexpected greetd response type for create_session: $createType',
        );
      }

      sessionActive = true;
      int secretPromptsAnswered = 0;
      Map<String, dynamic> currentMessage = createReply;

      while (true) {
        if (isCancelled != null && await isCancelled()) {
          await _tryCancelSession(socket, streamIterator, receiveBuffer);
          sessionActive = false;
          authSucceeded = false;
          return const LoginCancelled();
        }

        final responseType = _requireMessageType(currentMessage, 'auth');

        if (responseType == 'success') {
          authSucceeded = true;
          break;
        }

        if (responseType == 'error') {
          sessionActive = false;
          authSucceeded = false;
          final err = _parseErrorReply(currentMessage, 'auth');
          return LoginFailure(
            errorType: err.errorType,
            message: err.description,
            cause: err,
          );
        }

        if (responseType != 'auth_message') {
          throw GreetdProtocolException(
            description:
                'Unexpected greetd response type during auth: $responseType',
          );
        }

        final rawAuthMsgType = currentMessage['auth_message_type'];
        if (rawAuthMsgType is! String || rawAuthMsgType.isEmpty) {
          throw GreetdProtocolException(
            description:
                'Missing or invalid auth_message_type in greetd payload: $currentMessage',
          );
        }

        final rawAuthMsg = currentMessage['auth_message'];
        if (rawAuthMsg != null && rawAuthMsg is! String) {
          throw GreetdProtocolException(
            description:
                'Invalid auth_message field in greetd payload: $currentMessage',
          );
        }

        final String authMessageType = rawAuthMsgType;
        final String authMessage = rawAuthMsg ?? '';

        String? responseText;
        bool includeResponseField = false;

        switch (authMessageType) {
          case 'secret':
            includeResponseField = true;
            final customReply = onAuthMessage != null
                ? await onAuthMessage(authMessageType, authMessage)
                : null;
            if (customReply != null) {
              responseText = customReply;
            } else if (secretPromptsAnswered == 0) {
              responseText = password;
            } else {
              responseText = '';
            }
            secretPromptsAnswered++;

          case 'visible':
            includeResponseField = true;
            final customReply = onAuthMessage != null
                ? await onAuthMessage(authMessageType, authMessage)
                : null;
            responseText = customReply ?? '';

          case 'info':
          case 'error':
            if (onAuthMessage != null) {
              await onAuthMessage(authMessageType, authMessage);
            }
            includeResponseField = false;
            responseText = null;

          default:
            throw GreetdProtocolException(
              description: 'Unsupported auth_message_type: $authMessageType',
            );
        }

        if (isCancelled != null && await isCancelled()) {
          await _tryCancelSession(socket, streamIterator, receiveBuffer);
          sessionActive = false;
          authSucceeded = false;
          return const LoginCancelled();
        }

        final Map<String, dynamic> authResponsePayload = {
          'type': 'post_auth_message_response',
          if (includeResponseField) 'response': responseText,
        };

        await _sendGreetdMessage(socket, authResponsePayload);

        currentMessage = await _readGreetdMessage(
          streamIterator,
          receiveBuffer,
        );
      }

      if (isCancelled != null && await isCancelled()) {
        await _tryCancelSession(socket, streamIterator, receiveBuffer);
        sessionActive = false;
        authSucceeded = false;
        return const LoginCancelled();
      }

      final Map<String, dynamic> startPayload = {
        'type': 'start_session',
        'cmd': List<String>.from(sessionCmd),
        if (sessionEnv.isNotEmpty) 'env': List<String>.from(sessionEnv),
      };

      await _sendGreetdMessage(socket, startPayload);

      final startReply = await _readGreetdMessage(
        streamIterator,
        receiveBuffer,
      );
      final startType = _requireMessageType(startReply, 'start_session');

      if (startType == 'success') {
        sessionActive = false;
        return const LoginSuccess();
      }

      if (startType == 'error') {
        sessionActive = false;
        authSucceeded = false;
        final err = _parseErrorReply(startReply, 'start_session');
        return LoginFailure(
          errorType: err.errorType,
          message: err.description,
          cause: err,
        );
      }

      throw GreetdProtocolException(
        description:
            'Unexpected greetd response type for start_session: $startType',
      );
    } on ArgumentError {
      rethrow;
    } on GreetdProtocolException catch (e) {
      if (sessionActive &&
          !authSucceeded &&
          socket != null &&
          streamIterator != null &&
          receiveBuffer != null) {
        await _tryCancelSession(socket, streamIterator, receiveBuffer);
        sessionActive = false;
      }
      debugPrint('greetd protocol error: $e');
      return LoginFailure(
        errorType: e.errorType,
        message: e.description,
        cause: e,
      );
    } on SocketException catch (e) {
      debugPrint('socket error: $e');
      return LoginFailure(message: 'Socket connection error', cause: e);
    } on StateError catch (e) {
      debugPrint('state error: $e');
      return LoginFailure(
        message: 'Environment or stream state error',
        cause: e,
      );
    } on FormatException catch (e) {
      if (sessionActive &&
          !authSucceeded &&
          socket != null &&
          streamIterator != null &&
          receiveBuffer != null) {
        await _tryCancelSession(socket, streamIterator, receiveBuffer);
        sessionActive = false;
      }
      debugPrint('protocol format error: $e');
      return LoginFailure(message: 'Invalid response from greetd', cause: e);
    } catch (e) {
      if (sessionActive &&
          !authSucceeded &&
          socket != null &&
          streamIterator != null &&
          receiveBuffer != null) {
        await _tryCancelSession(socket, streamIterator, receiveBuffer);
        sessionActive = false;
      }
      debugPrint('unexpected login error: $e');
      return LoginFailure(message: e.toString(), cause: e);
    } finally {
      if (streamIterator != null) {
        try {
          await streamIterator.cancel();
        } catch (_) {}
      }
      await _closeSocketSafely(socket);
    }
  }
}
