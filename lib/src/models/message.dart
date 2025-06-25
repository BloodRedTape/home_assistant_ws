import 'package:home_assistant_ws/src/models/entity.dart';
import 'package:home_assistant_ws/src/utils.dart';

class Message {
  String type;
  int? id;
  Map<String, dynamic> data = {};

  Message({required this.type, this.id, required this.data});

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      type: Utils.getOrDefault<String>(json, ['type'], '<untyped>'),
      id: Utils.get<int>(json, ['id']),
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

class EventChange {
  List<EntityChange> changes;
  EventChange({required this.changes});

  static List<EntityChange> parse(Map<String, dynamic> data) {
    return data.entries.toList().map((e) => EntityChange.fromChangeEvent((e.key, e.value))).toList();
  }

  factory EventChange.fromData(Map<String, dynamic> data) {
    List<EntityChange> entities = Utils.getAndConvert<Map<String, dynamic>, List<EntityChange>>(data, ['c'], parse) ?? [];

    return EventChange(changes: entities);
  }
}

class EventAvailable {
  List<Entity> entities = [];

  EventAvailable({required this.entities});

  static List<Entity> parse(Map<String, dynamic> data) {
    return data.entries.toList().map((e) => Entity.fromAvailableEvent((e.key, e.value))).toList();
  }

  factory EventAvailable.fromData(Map<String, dynamic> data) {
    List<Entity> entities = Utils.getAndConvert<Map<String, dynamic>, List<Entity>>(data, ['a'], parse) ?? [];

    return EventAvailable(entities: entities);
  }
}

class EventMessage extends Message {
  EventAvailable? available;
  EventChange? change;
  EventMessage({required super.type, required super.data, this.available, this.change});

  factory EventMessage.fromEventMessage(Message message) {
    return EventMessage(
      type: message.type,
      data: message.data,
      available: EventAvailable.fromData(message.data['event']),
      change: EventChange.fromData(message.data['event']),
    );
  }
}
