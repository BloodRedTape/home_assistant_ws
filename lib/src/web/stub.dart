import 'package:web_socket_channel/web_socket_channel.dart';

Future<WebSocketChannel> createChannel(String url, {bool allowBadCertificates = false}) async {
  throw UnsupportedError('WebSockets not supported on this platform');
}
