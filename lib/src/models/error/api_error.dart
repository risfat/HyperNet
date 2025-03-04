import 'package:hyper_net/src/models/error/message.dart';

///Default api error model that can be received from network response.
///can be updated based on the response.
class DefaultApiError {
  int? statusCode;
  String? name;
  String? message;

  DefaultApiError({
    this.statusCode,
    this.name,
    this.message,
  });

  DefaultApiError.fromJson(dynamic json) {
    try {
      final map = json as Map<String, dynamic>;
      if (map.containsKey('statusCode')) {
        statusCode = map['statusCode'] as int?;
      }
      if (map.containsKey('name')) {
        name = map['name'] as String?;
      }

      if (map.containsKey('message')) {
        message = json['message'] as String?;
      } else if (map.containsKey('error')) {
        if (map['error'] is Map<String, dynamic>) {
          final error = map['error'] as Map<String, dynamic>;
          if (error.containsKey('message')) {
            message = error['message'] as String?;
          }
          if (error.containsKey('name')) {
            name = error['name'] as String?;
          }
        }
      } else {
        final apiMessage =
            ApiMessage.fromJson((json['message'] as List).firstOrNull);
        message = apiMessage.messages?.firstOrNull?.message;
      }
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {}
  }
}
