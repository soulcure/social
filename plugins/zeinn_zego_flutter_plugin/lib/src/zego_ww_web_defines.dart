class ZegoWebVideoConfig {
  /// 本地视频流
  dynamic localStream;

  /// 视频约束
  ZegoWebVideoOptions? constraints;

  ZegoWebVideoConfig({this.localStream, this.constraints});
}

class ZegoWebVideoOptions {
  int? width;
  int? height;
  int? frameRate;
  int? maxBitrate;

  ZegoWebVideoOptions({
    this.width,
    this.height,
    this.frameRate,
    this.maxBitrate,
  });
}

class ZegoWebPublishOption {
  String? streamParams;
  String? extraInfo;
  int? audioBitRate;
  String? cdnUrl;

  ZegoWebPublishOption({
    this.streamParams,
    this.extraInfo,
    this.audioBitRate,
    this.cdnUrl,
  });
}
