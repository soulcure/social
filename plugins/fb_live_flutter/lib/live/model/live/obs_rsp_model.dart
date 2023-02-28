/// **************************************************************************
/// 来自Q1Json转Dart工具
/// ignore_for_file: non_constant_identifier_names,library_prefixes
/// **************************************************************************

class ObsRspModel {
  final String? url;
  final String? secret;

  ObsRspModel({
    this.url,
    this.secret,
  });

  factory ObsRspModel.fromJson(Map<String, dynamic> json) =>
      _$ObsRspModelFromJson(json);

  ObsRspModel from(Map<String, dynamic> json) => _$ObsRspModelFromJson(json);

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['url'] = url;
    data['secret'] = secret;
    return data;
  }
}

ObsRspModel _$ObsRspModelFromJson(Map<String, dynamic> json) {
  return ObsRspModel(
    url: json['url'],
    secret: json['secret'],
  );
}
