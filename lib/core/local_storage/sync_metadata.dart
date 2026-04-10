import 'package:hive_flutter/hive_flutter.dart';

part 'sync_metadata.g.dart';

@HiveType(typeId: 1)
class SyncMetadata extends HiveObject {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  DateTime lastSync;

  SyncMetadata({
    required this.userId,
    required this.lastSync,
  });
}
