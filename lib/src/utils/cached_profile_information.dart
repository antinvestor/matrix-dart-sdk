import 'package:matrix/matrix_api_lite.dart';

const localProfileIdPrefix = 'local_id_';

class CachedProfileInformation extends Profile {
  final bool outdated;
  final DateTime updated;

  CachedProfileInformation.fromProfile(
    Profile profile, {
    required this.outdated,
    required this.updated,
  }) : super(
          profileId: profile.profileId,
          contacts: profile.contacts,
          extra: profile.extra,
          avatarUrl: profile.avatarUrl,
          displayName: profile.displayName,
        );

  factory CachedProfileInformation.fromJson(Map<String, Object?> json) =>
      CachedProfileInformation.fromProfile(
        Profile.fromJson(json),
        outdated: json['outdated'] as bool,
        updated: DateTime.fromMillisecondsSinceEpoch(json['updated'] as int),
      );

  @override
  Map<String, Object?> toJson() => {
        ...super.toJson(),
        'outdated': outdated,
        'updated': updated.millisecondsSinceEpoch,
      };
}
