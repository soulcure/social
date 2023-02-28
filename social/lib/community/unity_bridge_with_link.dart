import 'package:im/community/unity_bridge_controller.dart';
import 'package:im/widgets/flutter_video_link_parser/flutter_video_link_parser.dart';

class UnityBridgeWithLink extends UnityBridgeWithPartial
{
  UnityBridgeWithLink(UnityBridgeController controller) : super(controller);

  @override
  Future<void> destroy() async {

  }

  @override
  bool handleUnityMessage(String messageId, String method,
      Map<String, String> parameters) {
    switch (method) {
      case "MediaLinkParse":
        _mediaLinkParse(messageId, parameters["url"]);
        break;
      default:
        return false;
    }
    return true;
  }

  Future<void> _mediaLinkParse(String messageId, String url) async{
    final videoLinkType = MeidaLinkParser.linkType(url);
    if (videoLinkType == SupportedVideoLink.unsupoorted) {
      unityBridgeController.unityCallback(messageId, {
        "status": "0",
      });
      return;
    }

    final MeidaInfo info = await MeidaLinkParser.parseByType(videoLinkType, url);
    if(info != null){
      unityBridgeController.unityCallback(messageId, {
        "status": "1",
        "url": info.url ?? "",
        "title": info.title ?? "",
        "artist": info.artist ?? "",
        "albumName": info.albumName ?? "",
        "aspectRatio": info.aspectRatio?.toString() ?? "",
        "thumb": info.thumb ?? "",
        "duration": info.duration?.toString() ?? "",
        "siteIcon": info.siteIcon ?? "",
        "siteName": info.siteName ?? "",
        "mediaType": info.mediaType ?? "",
        "canPlay": info.canPlay ? "1" : "0",
      });
    }else{
      unityBridgeController.unityCallback(messageId, {
        "status": "0",
      });
    }
  }
}