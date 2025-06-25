class Message {
  String type;
  int? id;
  Map<String, dynamic> data = {};

  Message({required this.type, this.id, required this.data});

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      type: json['type'],
      id: json.containsKey('id') ? json['id'] : null,
      data:
          json
            ..remove('type')
            ..remove('id'),
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};

    if (id != null) result.addEntries(<String, dynamic>{'id': id}.entries);

    result.addAll(data);

    result.addEntries(<String, dynamic>{'type': type}.entries);

    return result;
  }
}
