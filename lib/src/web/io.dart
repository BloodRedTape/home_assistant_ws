import 'dart:io';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

Future<WebSocketChannel> createChannel(String url, {bool allowBadCertificates = false}) async {
  if (allowBadCertificates) {
    final client = HttpClient()..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    final socket = await WebSocket.connect(url, customClient: client);
    return IOWebSocketChannel(socket);
  } else {
    return IOWebSocketChannel.connect(url);
  }
}
