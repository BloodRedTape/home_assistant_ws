import 'package:home_assistant_ws/src/utils.dart';

class EntityAttributes {
  bool? editable;
  String? id;
  String? userId;
  List<String> deviceTrackers;
  String? friendlyName;

  // Light
  List<String>? options, supportedColorModes;
  double? brightness;
  List<int>? rgbColor;

  // Climate
  List<String>? hvacModes;
  int? minTemp, maxTemp;
  double? currentTemperature, temperature, targetTempLow, targetTempHigh;
  String? presetMode, hvacAction, fanMode;

  // Camera
  String? videoUrl, entityPicture;

  // Media Player
  String? mediaTitle, mediaArtist;

  // Cover
  double? currentPosition;

  EntityAttributes({
    required this.deviceTrackers,
    this.userId,
    this.friendlyName,
    this.editable,
    this.id,
    this.options,

    // Light
    this.supportedColorModes,
    this.brightness,
    this.rgbColor,

    // Climate
    this.hvacModes,
    this.minTemp,
    this.maxTemp,
    this.currentTemperature,
    this.temperature,
    this.targetTempLow,
    this.targetTempHigh,
    this.presetMode,
    this.hvacAction,
    this.fanMode,

    // Camera
    this.videoUrl,
    this.entityPicture,

    // Media Player
    this.mediaTitle,
    this.mediaArtist,

    //Cover
    this.currentPosition,
  });

  factory EntityAttributes.fromData(Map<String, dynamic> json) {
    bool containsKeyAndValue(Map<String, dynamic> json, String key) {
      return json.containsKey(key) && json[key] != null;
    }

    return EntityAttributes(
      editable: json['editable'],
      id: json['id'],
      userId: json['user_id'],
      deviceTrackers: containsKeyAndValue(json, 'device_trackers') ? List<String>.from(json['device_trackers']) : [],
      friendlyName: containsKeyAndValue(json, 'friendly_name') ? json['friendly_name'] : null,
      options: containsKeyAndValue(json, 'options') ? List<String>.from(json['options']) : [],

      // Light
      supportedColorModes: containsKeyAndValue(json, 'supported_color_modes') ? List<String>.from(json['supported_color_modes']) : [],
      brightness: containsKeyAndValue(json, 'brightness') ? json['brightness'].toDouble() : null,
      rgbColor: containsKeyAndValue(json, 'rgb_color') ? List<int>.from(json['rgb_color']) : null,

      // Climate
      hvacModes: containsKeyAndValue(json, 'hvac_modes') ? List<String>.from(json['hvac_modes']) : null,
      minTemp: containsKeyAndValue(json, 'min_temp') ? json['min_temp'] : null,
      maxTemp: containsKeyAndValue(json, 'max_temp') ? json['max_temp'] : null,
      currentTemperature: containsKeyAndValue(json, 'current_temperature') ? json['current_temperature'].toDouble() : null,
      temperature: containsKeyAndValue(json, 'temperature') ? json['temperature'].toDouble() : null,
      targetTempLow: containsKeyAndValue(json, 'target_temp_low') ? json['target_temp_low'].toDouble() : null,
      targetTempHigh: containsKeyAndValue(json, 'target_temp_high') ? json['target_temp_high'].toDouble() : null,
      presetMode: containsKeyAndValue(json, 'preset_mode') ? json['preset_mode'] : null,
      hvacAction: containsKeyAndValue(json, 'hvac_action') ? json['hvac_action'] : null,
      fanMode: containsKeyAndValue(json, 'fan_mode') ? json['fan_mode'] : null,

      // Camera
      videoUrl: containsKeyAndValue(json, 'video_url') ? json['video_url'] : null,
      entityPicture: containsKeyAndValue(json, 'entity_picture') ? json['entity_picture'] : null,

      // Media Player
      mediaTitle: containsKeyAndValue(json, 'media_title') ? json['media_title'] : null,
      mediaArtist: containsKeyAndValue(json, 'media_artist') ? json['media_artist'] : null,

      currentPosition: containsKeyAndValue(json, 'current_position') ? json['current_position'].toDouble() : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'editable': editable,
      'id': id,
      'user_id': userId,
      'device_trackers': deviceTrackers,
      'friendly_name': friendlyName,

      // Light
      'brightness': brightness,
      'supported_color_modes': supportedColorModes,
      'rgb_color': rgbColor,

      // Climate
      'hvac_modes': hvacModes,
      'min_temp': minTemp,
      'max_temp': maxTemp,
      'current_temperature': currentTemperature,
      'temperature': temperature,
      'target_temp_low': targetTempLow,
      'target_temp_high': targetTempHigh,
      'preset_mode': presetMode,
      'hvac_action': hvacAction,
      'fan_mode': fanMode,

      // Camera
      'video_url': videoUrl,
      'entity_picture': entityPicture,

      // Media Player
      'media_title': mediaTitle,
      'media_artist': mediaArtist,
      'current_position': currentPosition,
    };
  }
}

class Entity {
  String entityId;
  String? state;
  EntityAttributes? attributes;

  Entity({required this.entityId, required this.state, this.attributes});

  factory Entity.fromAvailableEventMapEntry(MapEntry<String, Map<String, dynamic>> entry) {
    return Entity.fromAvailableEvent((entry.key, entry.value));
  }

  factory Entity.fromAvailableEvent((String, Map<String, dynamic>) data) {
    final attributes = Utils.getAndConvert<Map<String, dynamic>, EntityAttributes>(data.$2, ['a'], EntityAttributes.fromData);
    final state = Utils.get<String>(data.$2, ['s']);

    return Entity(entityId: data.$1, state: state, attributes: attributes);
  }
}

class EntityValueChange {
  dynamic newValue;

  EntityValueChange({required this.newValue});
}

class EntityChange {
  String entityId;
  EntityValueChange? stateChange;
  Map<String, EntityValueChange> attributesChange;

  EntityChange({required this.entityId, required this.stateChange, required this.attributesChange});

  factory EntityChange.fromChangeEvent((String, Map<String, dynamic>) data) {
    EntityValueChange? stateChange = Utils.has(data.$2, ['+', 's']) ? EntityValueChange(newValue: Utils.get<String>(data.$2, ['+', 's'])) : null;

    final attributes = Utils.get<Map<String, dynamic>>(data.$2, ['+', 'a']);

    Map<String, EntityValueChange> attributesChange = {};

    for (MapEntry<String, dynamic> attribute in attributes?.entries ?? {}) {
      attributesChange.putIfAbsent(attribute.key, () => EntityValueChange(newValue: attribute.value));
    }

    return EntityChange(entityId: data.$1, stateChange: stateChange, attributesChange: attributesChange);
  }
}
