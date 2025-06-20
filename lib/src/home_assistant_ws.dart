import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:io';
import 'package:web_socket_channel/io.dart';
import "models/message.dart";
import 'dart:convert';

class HomeAssistantWs {
  final String token;
  final String baseUrl;
  WebSocketChannel? _webSocketChannel;
  Map<dynamic, void Function(Message)> _callbacks = {};
  int _id = 1;

  HomeAssistantWs({required this.token, required this.baseUrl});

  Future<bool> connect() async {
    _webSocketChannel = await createUntrustedWebSocketChannel(baseUrl);

    if (!await ready()) return false;

    var channel = _webSocketChannel;

    if (channel == null) return false;

    channel.stream.listen(onData, onError: onError, onDone: onDone);

    try {
      Message reply = await send('auth', {'access_token': token}, replyType: 'auth_ok');

      print('${reply.type} ${reply.data.toString()}');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> ready() async {
    var channel = _webSocketChannel;

    if (channel == null) return false;

    try {
      await channel.ready;
    } catch (e) {
      return false;
    }
    return true;
  }

  Future<Message> send(String type, Map<String, dynamic> data, {String? replyType, Duration delay = const Duration(seconds: 5)}) {
    Completer<Message> completer = Completer();

    final key = sendCallback(type, data, (message) => completer.complete(message), replyType: replyType);

    Future.delayed(delay).then((value) {
      if (completer.isCompleted) return;

      completer.completeError(TimeoutException('Timeout'));

      removeCallback(key);
    });

    if (key == null) {
      completer.completeError(Error());
    }

    return completer.future;
  }

  dynamic sendCallback(String type, Map<String, dynamic> data, void Function(Message message) callback, {String? replyType}) {
    var channel = _webSocketChannel;

    if (channel == null) return null;

    Message message = Message(type: type, data: data, id: null);

    channel.sink.add(jsonEncode(message.toJson()));

    if (replyType != null) {
      _callbacks.putIfAbsent(replyType, () => callback);

      return replyType;
    } else {
      message.id = _id++;
      _callbacks.putIfAbsent(message.id, () => callback);

      return message.id;
    }
  }

  dynamic findCallback({int? id, String? type}) {
    if (_callbacks.containsKey(id)) {
      return id;
    }

    if (_callbacks.containsKey(type)) {
      return type;
    }

    return null;
  }

  void removeCallback(dynamic key) {
    if (key != null && _callbacks.containsKey(key)) {
      _callbacks.remove(key);
    }
  }

  void onData(dynamic data) {
    Message message = Message.fromJson(jsonDecode(data));
    print('got ${message.id} ${message.type}');

    final key = findCallback(id: message.id, type: message.type);

    if (key != null) {
      _callbacks[key]?.call(message);
      _callbacks.remove(key);
    }
  }

  void onError(dynamic error) {}
  void onDone() {}

  Future<IOWebSocketChannel> createUntrustedWebSocketChannel(String url) async {
    final client = HttpClient()..badCertificateCallback = (X509Certificate cert, String host, int port) => true;

    final socket = await WebSocket.connect(url, customClient: client);

    return IOWebSocketChannel(socket);
  }
}
