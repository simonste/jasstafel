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
