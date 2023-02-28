import 'dart:io';
import 'dart:typed_data';

import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/api/fblive_provider.dart';
import 'package:fb_live_flutter/live/bloc/create_room_bloc.dart';
import 'package:fb_live_flutter/live/net/api.dart';
import 'package:fb_live_flutter/live/utils/file/file_util.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/ui.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';
import 'package:fb_live_flutter/live/widget_common/image/sw_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

typedef ImageCallBlock = void Function(String? text);

class RoomInfoCard extends StatefulWidget {
  final ImageCallBlock imageCallBlock;
  final CreateRoomBloc? createRoomBloc;

  const RoomInfoCard(
      {Key? key, required this.imageCallBlock, this.createRoomBloc})
      : super(key: key);

  @override
  _RoomInfoCardState createState() => _RoomInfoCardState();
}

class _RoomInfoCardState extends State<RoomInfoCard> {
  String? imageUrl;
  String? imagePath;

  bool isEditTitle = false;

  FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _getUserImage();
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        isEditTitle = false;
        setState(() {});
      }
    });
  }

  Future _getUserImage() async {
    /// 权限检测
    PermissionStatus storageStatus = await Permission.storage.status;
    if (storageStatus != PermissionStatus.granted) {
      storageStatus = await Permission.storage.request();
    }
    final FBUserInfo? userInfo = await fbApi.getUserInfo(
      fbApi.getUserId()!,
      guildId: fbApi.getCurrentChannel()!.guildId,
    );
    setState(() {
      imageUrl = userInfo!.avatar;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff000000).withOpacity(0.25),
        borderRadius: const BorderRadius.all(Radius.circular(6)),
      ),
      padding: EdgeInsets.all(12.px),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClickEvent(
            onTap: () async {
              if (kIsWeb) {
                await fbApi.webPickImage().then((_file) {
                  if (_file != null) {
                    _webUploadRoomLogo(_file);
                  }
                });
              } else {
                await fbApi
                    .pickImage(context,
                        cropRatio:
                            const CropAspectRatio(ratioX: 100, ratioY: 148))
                    .then((value) {
                  if (value != null) {
                    _appUploadRoomLogo(value);
                  }
                });
              }
            },
            child: ClipRRect(
              /// 【APP】更换封面透明框没有覆盖全
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  SwImage(
                    imagePath ?? imageUrl,
                    width: 62.5.px,
                    height: 93.px,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    width: 62.5.px,
                    height: 16.px,
                    decoration: BoxDecoration(
                      color: const Color(0xff200000).withOpacity(0.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '更换封面',
                      style: TextStyle(color: Colors.white, fontSize: 8.px),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Space(width: 11.px),
          Expanded(
            child: SizedBox(
              height: 93.px,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Space(height: 8.px),
                  InkWell(
                    onTap: () {
                      isEditTitle = true;
                      setState(() {});
                      focusNode.requestFocus();
                    },
                    child: Stack(
                      children: [
                        SizedBox(
                          height: 20.px,
                          child: TitleField(
                              widget.createRoomBloc!.titleTextFiledCtr,
                              focusNode: focusNode, onTap: () {
                            isEditTitle = true;
                            setState(() {});
                          }),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SizedBox(
                              width: () {
                                final String text = widget
                                    .createRoomBloc!.titleTextFiledCtr.text;
                                if (text.isEmpty) {
                                  return 0.0;
                                }
                                final TextPainter textPainter = TextPainter(
                                    textDirection: TextDirection.ltr,
                                    text: TextSpan(text: text, style: style),
                                    maxLines: 1)
                                  ..layout(maxWidth: FrameSize.winWidth() - 40);
                                return textPainter.size.width;
                              }(),
                            ),
                            Space(width: 6.px),
                            if (isEditTitle ||
                                !strNoEmpty(widget
                                    .createRoomBloc?.titleTextFiledCtr.text))
                              Container()
                            else
                              Container(
                                height: 20.px,
                                alignment: Alignment.bottomCenter,
                                child: SwImage(
                                  'assets/live/main/v2_create_edit.png',
                                  width: 16.px,
                                  height: 16.px,
                                ),
                              )
                          ],
                        )
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    widget.createRoomBloc?.channelTextFiledCtr.text ?? "请选择频道",
                    style: TextStyle(
                      color: const Color(0xffFFFFFF).withOpacity(0.35),
                      fontSize: 12.px,
                    ),
                  ),
                  Space(height: 8.px),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Future _webUploadRoomLogo(Map _file) async {
    final Map map = await Api.webUploadImage(_file);
    _formatUploadData(map);
  }

  Future _appUploadRoomLogo(File _file) async {
    final Uint8List uList =
        Uint8List.fromList((await FileUtil.compressFile(_file))!);
    final tempDir = await getTemporaryDirectory();
    final File newFile = await File(
            '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg')
        .create();
    newFile.writeAsBytesSync(uList);
    final Map map = await Api.uploadImage(newFile.path);
    _formatUploadData(map);
  }

  void _formatUploadData(Map map) {
    if (map["code"] == 200) {
      setState(() {
        final String? imageString = map["data"]["url"];
        imagePath = imageString;
        widget.imageCallBlock(imageString);
      });
    } else {
      try {
        myFailToast("图片上传失败:${map["msg"]}");
      } catch (e) {
        myFailToast('当前上传图片过大,请重新上传！！');
      }
    }
  }
}

final style = TextStyle(
  color: Colors.white,
  fontWeight: FontWeight.w500,
  fontSize: 16.px,
);

class TitleField extends TextField {
  TitleField(
    TextEditingController controller, {
    bool? enabled = true,
    FocusNode? focusNode,
    GestureTapCallback? onTap,
  }) : super(
          controller: controller,
          enabled: enabled ?? true,
          focusNode: focusNode,
          cursorHeight: 20.px,
          cursorColor: const Color(0xFF198CFE),
          onTap: onTap,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: ' 输入标题更吸引小伙伴',
            hintStyle: TextStyle(
                color: const Color(0xffFFFFFF).withOpacity(0.2),
                fontSize: 16.px,
                fontWeight: FontWeight.w500),
            contentPadding: const EdgeInsets.all(0),
            isDense: true,
            counterText: "",
          ),

          /// 【APP】直播间标题输入框最多只能输入13个字
          maxLength: 13,
          style: style,
        );
}
