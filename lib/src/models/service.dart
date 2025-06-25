import 'package:home_assistant_ws/src/utils.dart';

class ServiceResponse {
  final Map<String, dynamic> serviceResponse;

  ServiceResponse({required this.serviceResponse});

  factory ServiceResponse.fromData(Map<String, dynamic> json) {
    final Map<String, dynamic> serviceResponse = Utils.getOrDefault<Map<String, dynamic>>(json, ['result', 'response'], {});

    return ServiceResponse(serviceResponse: serviceResponse);
  }
}
