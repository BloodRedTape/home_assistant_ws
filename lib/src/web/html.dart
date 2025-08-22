import 'package:web_socket_channel/html.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

Future<WebSocketChannel> createChannel(String url, {bool allowBadCertificates = false}) async {
  // Browsers require valid SSL certs — cannot override
  return HtmlWebSocketChannel.connect(url);
}
