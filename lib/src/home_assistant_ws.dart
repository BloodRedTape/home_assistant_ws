import 'dart:async';

import 'package:home_assistant_ws/src/models/service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:io';
import 'package:web_socket_channel/io.dart';
import "models/message.dart";
import 'dart:convert';

export "models/message.dart";

class CallbackInfo {
  final void Function(Message) callback;
  final bool once;

  const CallbackInfo({required this.callback, required this.once});
}

class HomeAssistantWs {
  final String token;
  final String baseUrl;
  WebSocketChannel? _webSocketChannel;
  final Map<dynamic, CallbackInfo> _callbacks = {};
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

  Future<Message> send(String type, Map<String, dynamic> data, {String? replyType, Duration timeout = const Duration(seconds: 20)}) {
    Completer<Message> completer = Completer();

    final key = sendCallback(type, data, (message) => completer.complete(message), replyType: replyType);

    Future.delayed(timeout).then((value) {
      if (completer.isCompleted) return;

      completer.completeError(TimeoutException('Timeout'));

      removeCallback(key);
    });

    if (key == null) {
      completer.completeError(Error());
    }

    return completer.future;
  }

  dynamic sendCallback(String type, Map<String, dynamic> data, void Function(Message message) callback, {String? replyType, bool once = true}) {
    var channel = _webSocketChannel;

    if (channel == null) return null;

    Message message = Message(type: type, data: data, id: replyType == null ? _id++ : null);

    final messageString = jsonEncode(message.toJson());
    print('sent $messageString');
    channel.sink.add(messageString);

    dynamic key = replyType ?? message.id;

    _callbacks.putIfAbsent(key, () => CallbackInfo(callback: callback, once: once));

    return key;
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
    final json = jsonDecode(data);
    if (json is List<Map<String, dynamic>>) {
      for (final jsonMessage in json) {
        onMessage(Message.fromJson(jsonMessage));
      }
    }
    if (json is Map<String, dynamic>) {
      onMessage(Message.fromJson(json));
    }
  }

  void onMessage(Message message) {
    final key = findCallback(id: message.id, type: message.type);
    final info = _callbacks[key];

    if (info != null) {
      info.callback.call(message);

      if (info.once) _callbacks.remove(key);
    }
  }

  void onError(dynamic error) {}

  void onDone() {}

  Future<IOWebSocketChannel> createUntrustedWebSocketChannel(String url) async {
    final client = HttpClient()..badCertificateCallback = (X509Certificate cert, String host, int port) => true;

    final socket = await WebSocket.connect(url, customClient: client);

    return IOWebSocketChannel(socket);
  }

  Future<ServiceResponse?> executeService({
    required String domain,
    required String service,
    Map<String, dynamic> serviceData = const {},
    bool returnResponse = false,
  }) async {
    Message message = await send('call_service', {'domain': domain, 'service': service, 'return_response': returnResponse, 'service_data': serviceData});

    return returnResponse ? ServiceResponse.fromJson(message.data) : null;
  }

  Future<void> executeServiceForEntity(String entityId, String service, {Map<String, dynamic> additionalData = const {}}) async {
    Map<String, dynamic> data = Map.from(additionalData);
    data["entity_id"] = entityId;

    String domain = entityId.split('.').first;

    await executeService(domain: domain, service: service, serviceData: data, returnResponse: false);
  }
}
