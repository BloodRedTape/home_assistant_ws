import 'dart:async';

import 'package:home_assistant_ws/src/models/service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:io';
import 'package:web_socket_channel/io.dart';
import "models/message.dart";
import 'dart:convert';
import 'package:collection/collection.dart';

import 'web/stub.dart' if (dart.library.io) 'web/io.dart' if (dart.library.html) 'web/html.dart';

class CallbackInfo {
  final int? id;
  final List<String>? types;
  final void Function(Message) callback;
  final bool once;

  const CallbackInfo({required this.callback, required this.once, this.id, this.types});
}

typedef CallbackHandle = int;

class HomeAssistantWsApi {
  final String baseUrl;
  WebSocketChannel? _webSocketChannel;
  final Map<CallbackHandle, CallbackInfo> _callbacks = {};
  late CallbackHandle _lastCallbackHandle;
  late int _id;
  void Function()? onDone;
  void Function(dynamic)? onError;

  HomeAssistantWsApi({required this.baseUrl, this.onDone, this.onError}) {
    _reset();
  }

  Future<bool> connect({bool unsafe = false}) async {
    _webSocketChannel = await createWebSocketChannel(baseUrl, allowBadCertificates: unsafe);

    if (!await ready()) return false;

    var channel = _webSocketChannel;

    if (channel == null) return false;

    channel.stream.listen(onData, onError: onError, onDone: onDone);

    return true;
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

  void _reset() {
    _callbacks.clear();
    _id = 1;
    _lastCallbackHandle = 0;
  }

  Future<void> close() async {
    _reset();

    if (_webSocketChannel == null) return;

    await _webSocketChannel?.sink.close(1000);
  }

  int makeNextCallbackHandle() {
    return ++_lastCallbackHandle;
  }

  Future<Message> send(String type, Map<String, dynamic> data, {List<String>? replyTypes, Duration timeout = const Duration(seconds: 20)}) {
    Completer<Message> completer = Completer();

    final handle = sendCallback(type, data, (message) => completer.complete(message), replyTypes: replyTypes);

    if (handle == null) {
      completer.completeError(Error());

      return completer.future;
    }

    Future.delayed(timeout).then((value) {
      if (completer.isCompleted) return;

      completer.completeError(TimeoutException('Timeout'));

      removeCallback(handle);
    });

    return completer.future;
  }

  CallbackHandle? sendCallback(String type, Map<String, dynamic> data, void Function(Message message) callback, {List<String>? replyTypes, bool once = true}) {
    var channel = _webSocketChannel;

    if (channel == null) return null;

    bool isIdMessage = replyTypes == null;
    int? messageId = isIdMessage ? _id++ : null;

    Message message = Message(type: type, data: data, id: messageId);

    final messageString = jsonEncode(message.toJson());

    channel.sink.add(messageString);

    CallbackInfo info = CallbackInfo(callback: callback, once: once, id: messageId, types: replyTypes);

    CallbackHandle handle = makeNextCallbackHandle();

    _callbacks.putIfAbsent(handle, () => info);

    return handle;
  }

  (CallbackHandle?, CallbackInfo?) findCallback({int? id, String? type}) {
    for (final entry in _callbacks.entries) {
      CallbackHandle handle = entry.key;
      CallbackInfo info = entry.value;

      final idMatch = info.id != null && info.id == id;
      final typeMatch = (info.types ?? []).contains(type);

      if (idMatch || typeMatch) {
        return (handle, info);
      }
    }

    return (null, null);
  }

  void removeCallback(CallbackHandle? handle) {
    if (handle != null && _callbacks.containsKey(handle)) {
      _callbacks.remove(handle);
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
    final (handle, info) = findCallback(id: message.id, type: message.type);

    if (info != null) {
      info.callback.call(message);

      if (info.once && handle != null) {
        _callbacks.remove(handle);
      }
    }
  }

  Future<WebSocketChannel> createWebSocketChannel(String url, {bool allowBadCertificates = false}) {
    return createChannel(url, allowBadCertificates: allowBadCertificates);
  }
}
