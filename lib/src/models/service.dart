class ServiceResponse {
  final Map<String, dynamic> serviceResponse;

  ServiceResponse({required this.serviceResponse});

  factory ServiceResponse.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> serviceResponse = Map<String, dynamic>.from(json['service_response']);

    return ServiceResponse(serviceResponse: serviceResponse);
  }
}
