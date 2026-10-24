import 'dart:convert';

import 'package:archive/archive_io.dart';
import 'package:json_annotation/json_annotation.dart';
part 'profile_data.g.dart';

@JsonSerializable()
class ProfileData {
  String active;
  List<String> list;

  ProfileData(this.active, this.list);

  factory ProfileData.fromJson(Map<String, dynamic> json) =>
      _$ProfileDataFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileDataToJson(this);
}

String encodeProfile(Map<String, dynamic> profile) {
  var bytes = utf8.encode(jsonEncode(profile));
  return base64.encode(GZipEncoder().encode(bytes));
}

Map<String, dynamic> decodeProfile(String encoded) {
  var bytes = GZipDecoder().decodeBytes(base64.decode(encoded));
  var profile = jsonDecode(utf8.decode(bytes));
  return profile;
}
