import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/pages/external_share/external_share_model.dart';
import 'package:im/themes/const.dart';
import 'package:im/web/pages/service/container_image.dart';
import 'package:im/widgets/channel_icon.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:provider/provider.dart';

class ExternalShareSendDialog extends StatelessWidget {
  final ExternalShareModel model;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const ExternalShareSendDialog(this.model, {this.onCancel, this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8))),
      backgroundColor: Colors.white,
      child: SizedBox(
        // decoration: const BoxDecoration(
        //     borderRadius: BorderRadius.all(Radius.circular(8)),
        //     color: Colors.white),
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildShareToWidget(model),
            _buildShareContent(model),
            Divider(
              height: 0.5,
              color: const Color(0xFF8F959E).withOpacity(0.2),
            ),
            _buildButtons(model),
          ],
        ),
      ),
    );
  }

  Widget _buildShareToWidget(ExternalShareModel model) {
    bool isPrivate = false;
    if (!model.isSelectUser) {
      final gp = PermissionModel.getPermission(model.selectedChannel.guildId);
      isPrivate =
          PermissionUtils.isPrivateChannel(gp, model.selectedChannel.id);
    }

    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "发送给：".tr,
            style: const TextStyle(
                fontSize: 17,
                height: 21.0 / 17.0,
                color: Color(0xFF363940),
                fontWeight: FontWeight.w600),
          ),
          sizeHeight12,
          if (model.isSelectUser)
            Row(
              children: [
                RealtimeAvatar(
                  userId: model.selectedUser.userId,
                  size: 40,
                ),
                sizeWidth12,
                Text(
                  model.selectedUser.nickname,
                  style: const TextStyle(
                      fontSize: 17,
                      height: 21.0 / 17.0,
                      color: Color(0xFF363940),
                      fontWeight: FontWeight.w600),
                ),
                sizeWidth20,
              ],
            )
          else
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F8), // 底色
                    shape: BoxShape.circle, // 圆形
                  ),
                  child: ChannelIcon(
                    model.selectedChannel.type,
                    private: isPrivate,
                    size: 20,
                    color: const Color(0xFF8F959E),
                  ),
                ),
                sizeWidth12,
                Text(
                  model.selectedChannel.name,
                  style: const TextStyle(
                      fontSize: 17,
                      height: 21.0 / 17.0,
                      color: Color(0xFF363940),
                      fontWeight: FontWeight.w600),
                ),
              ],
            )
        ],
      ),
    );
  }

  Widget _buildShareContent(ExternalShareModel model) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          if (model.shareContentType == "image") ...[
            Divider(
              indent: 20,
              endIndent: 20,
              height: 0.5,
              thickness: 0.5,
              color: const Color(0xFF8F959E).withOpacity(0.2),
            ),
            sizeHeight16,
            ChangeNotifierProvider.value(
              value: model,
              child: Consumer<ExternalShareModel>(
                builder: (ctx, m, _) {
                  if (m.imageUrl != null && m.imageUrl.isNotEmpty) {
                    return ContainerImage(
                      m.image,
                      height: 160,
                      width: 160,
                      fit: BoxFit.cover,
                    );
                  } else if (m.imageBytes != null && m.imageBytes.isNotEmpty) {
                    return Image.memory(
                      m.imageBytes,
                      height: 160,
                      width: 160,
                      fit: BoxFit.cover,
                    );
                  } else {
                    return const SizedBox(
                      width: 160,
                      height: 160,
                    );
                  }
                },
              ),
            ),
            sizeHeight20,
          ],
          if (model.shareContentType == "link")
            Container(
              padding: const EdgeInsets.only(
                  top: 15, left: 12, right: 12, bottom: 15),
              margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              alignment: Alignment.centerLeft,
              decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                  color: Color(0xFFF5F5F8)),
              height: 48,
              child: Text("[链接]${model.desc ?? ""}",
                  style: const TextStyle(
                      fontSize: 14,
                      height: 18.0 / 14.0,
                      color: Color(0xFF646A73))),
            ),
        ],
      ),
    );
  }

  Widget _buildButtons(ExternalShareModel model) {
    return SizedBox(
      // color: Colors.white,
      height: 56,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
              child: TextButton(
            onPressed: onCancel,
            child: Text(
              "取消".tr,
              style: const TextStyle(
                  fontSize: 17,
                  height: 21.0 / 17.0,
                  color: Color(0xFF363940),
                  fontWeight: FontWeight.w600),
            ),
          )),
          VerticalDivider(
            width: 0.5,
            color: const Color(0xFF8F959E).withOpacity(0.2),
          ),
          Expanded(
            child: TextButton(
              onPressed: onConfirm,
              child: Text("确定".tr,
                  style: const TextStyle(
                      fontSize: 17,
                      height: 21.0 / 17.0,
                      color: Color(0xFF6179F2),
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
