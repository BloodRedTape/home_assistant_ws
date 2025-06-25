import 'package:home_assistant_ws/home_assistant_ws.dart';
import 'package:home_assistant_ws/src/home_assistant_ws_api.dart';
import 'package:home_assistant_ws/src/models/service.dart';

export "models/message.dart";

class HomeAssistantWs {
  final HomeAssistantWsApi _api;
  final String token;

  HomeAssistantWs({required this.token, required String baseUrl, void Function()? onDone, void Function(dynamic)? onError})
    : _api = HomeAssistantWsApi(baseUrl: baseUrl, onDone: onDone, onError: onError);

  Future<bool> connect() async {
    if (!await _api.connect()) return false;

    try {
      Message reply = await _api.send('auth', {'access_token': token}, replyTypes: ['auth_ok', 'auth_invalid']);

      return reply.type == 'auth_ok';
    } catch (e) {
      return false;
    }
  }

  Future<void> disconnect() {
    return _api.close();
  }

  Future<bool> isConnected() {
    return _api.ready();
  }

  Future<ServiceResponse?> executeService({
    required String domain,
    required String service,
    Map<String, dynamic> serviceData = const {},
    bool returnResponse = false,
  }) async {
    Message message = await _api.send('call_service', {'domain': domain, 'service': service, 'return_response': returnResponse, 'service_data': serviceData});

    return returnResponse ? ServiceResponse.fromJson(message.data) : null;
  }

  Future<void> executeServiceForEntity(String entityId, String service, {Map<String, dynamic> additionalData = const {}}) async {
    Map<String, dynamic> data = Map.from(additionalData);
    data["entity_id"] = entityId;

    String domain = entityId.split('.').first;

    await executeService(domain: domain, service: service, serviceData: data, returnResponse: false);
  }

  CallbackHandle? subscribeEntities(void Function(EventMessage) callback) {
    return _api.sendCallback('subscribe_entities', {}, (Message message) {
      if (message.type == 'event') callback(EventMessage.fromEventMessage(message));
    }, once: false);
  }

  Future<Message> getConfig() async {
    return await _api.send('get_config', {});
  }

  Future<bool> ping() async {
    Message message = await _api.send('ping', {});

    return message.type == 'pong';
  }
}
