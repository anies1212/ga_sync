/// GA event definition model
class EventDefinition {
  final String eventName;
  final List<EventParameter> parameters;
  final String? description;
  final String? category;

  const EventDefinition({
    required this.eventName,
    required this.parameters,
    this.description,
    this.category,
  });

  /// Convert snake_case to PascalCase
  String get className {
    return eventName
        .split('_')
        .map((word) => word.isEmpty
            ? ''
            : '${word[0].toUpperCase()}${word.substring(1)}')
        .join('');
  }

  /// Convert snake_case to camelCase
  String get enumValue {
    final parts = eventName.split('_');
    if (parts.isEmpty) return eventName;
    return parts.first +
        parts
            .skip(1)
            .map((word) => word.isEmpty
                ? ''
                : '${word[0].toUpperCase()}${word.substring(1)}')
            .join('');
  }

  factory EventDefinition.fromRow(List<String> row) {
    if (row.length < 3) {
      throw FormatException('Invalid row format: expected at least 3 columns');
    }

    final eventName = row[0].trim();
    final parametersStr = row[1].trim();
    final paramTypesStr = row[2].trim();
    final description = row.length > 3 ? row[3].trim() : null;
    final category = row.length > 4 ? row[4].trim() : null;

    final paramNames = parametersStr.isEmpty
        ? <String>[]
        : parametersStr.split(',').map((e) => e.trim()).toList();
    final paramTypes = paramTypesStr.isEmpty
        ? <String>[]
        : paramTypesStr.split(',').map((e) => e.trim()).toList();

    if (paramNames.length != paramTypes.length) {
      throw FormatException(
        'Parameter count mismatch for $eventName: '
        '${paramNames.length} names vs ${paramTypes.length} types',
      );
    }

    final parameters = <EventParameter>[];
    for (var i = 0; i < paramNames.length; i++) {
      parameters.add(EventParameter(
        name: paramNames[i],
        type: paramTypes[i],
      ));
    }

    return EventDefinition(
      eventName: eventName,
      parameters: parameters,
      description: description,
      category: category,
    );
  }
}

/// Event parameter model
class EventParameter {
  final String name;
  final String type;
  final bool isRequired;

  const EventParameter({
    required this.name,
    required this.type,
    this.isRequired = true,
  });

  /// Convert snake_case to camelCase
  String get fieldName {
    final parts = name.split('_');
    if (parts.isEmpty) return name;
    return parts.first +
        parts
            .skip(1)
            .map((word) => word.isEmpty
                ? ''
                : '${word[0].toUpperCase()}${word.substring(1)}')
            .join('');
  }

  /// Convert to Dart type
  String get dartType {
    return switch (type.toLowerCase()) {
      'string' => 'String',
      'int' || 'integer' => 'int',
      'double' || 'float' || 'number' => 'double',
      'bool' || 'boolean' => 'bool',
      'map' => 'Map<String, dynamic>',
      'list' => 'List<dynamic>',
      _ => 'dynamic',
    };
  }
}
