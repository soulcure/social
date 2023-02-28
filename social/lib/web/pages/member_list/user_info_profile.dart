import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/entity/role_bean.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/global.dart';
import 'package:im/global_methods/goto_direct_message.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/user.dart';
import 'package:im/utils/utils.dart';
import 'package:im/web/extension/widget_extension.dart';
import 'package:im/web/pages/setting/member_manage_page.dart';
import 'package:im/web/utils/show_web_tooltip.dart';
import 'package:im/widgets/super_tooltip.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';

void showUserInfoProfile(
  BuildContext context,
  String userId,
  String guildId, {
  TooltipDirection tooltipDirection = TooltipDirection.leftTop,
  double offsetX = 0,
}) {
  showWebTooltip(
    context,
    offsetX: offsetX,
    maxWidth: null,
    popupDirection: tooltipDirection,
    containsBackgroundOverlay: false,
    builder: (context, done) {
      return UserInfoProfile(guildId, userId, done);
    },
  );
}

class UserInfoProfile extends StatefulWidget {
  final String userId;
  final String guildId;
  final Function hideProfile;
  const UserInfoProfile(this.guildId, this.userId, this.hideProfile);
  @override
  _UserInfoProfileState createState() => _UserInfoProfileState();
}

class _UserInfoProfileState extends State<UserInfoProfile> {
  static const double _horizontalPadding = 16;
  TextEditingController _inputController;
  @override
  void initState() {
    _inputController = TextEditingController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 258,
      child: UserInfo.consume(widget.userId, guildId: widget.guildId,
          builder: (context, user, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserInfo(user),
            _buildUserRoles(),
            _buildPrivateChatInput(context, user),
          ],
        );
      }),
    );
  }

  Widget _buildPrivateChatInput(BuildContext context, UserInfo user) {
    if (user.userId == Global.user.id) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          _horizontalPadding, 0, _horizontalPadding, 24),
      child: TextField(
        controller: _inputController,
        decoration: InputDecoration(
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          border: const OutlineInputBorder(
            borderSide: BorderSide.none,
          ),
          filled: true,
          hintStyle: TextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodyText1.color,
          ),
          hintText: "私信给%s".trArgs([user.showName().toString()]),
          fillColor: Theme.of(context).scaffoldBackgroundColor,
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).textTheme.bodyText2.color,
        ),
        onSubmitted: (val) async {
          unawaited(sendDirectMessage(
            user.userId,
            TextEntity.fromString(val),
            jump: true,
          ));
          widget.hideProfile?.call(null);
        },
      ),
    );
  }

  Widget _buildUserRoles() {
    if (ChatTargetsModel.instance.selectedChatTarget?.id?.noValue ?? true) {
      return sizeHeight16;
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(
          _horizontalPadding, 24, _horizontalPadding, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ValidPermission(
              permissions: const [],
              builder: (_, __) {
                return RoleBean.consume(
                    context: context,
                    userId: widget.userId,
                    guildId: widget.guildId,
                    builder: (context, role, _) {
                      return Text(
                        role.roleIds.isEmpty ? '没有角色'.tr : '角色'.tr,
                        style: Theme.of(context).textTheme.bodyText2.copyWith(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      );
                    });
              }),
          sizeHeight8,
          MemberManagePage.userRoles(
              userId: widget.userId, guildId: widget.guildId, context: context)
        ],
      ),
    );
  }

  Widget _buildUserInfo(UserInfo user) {
    final hasRemark = user.nickname != user.showName();
    return Container(
      width: 258,
      height: 258,
      decoration: BoxDecoration(
          image: DecorationImage(
              image: NetworkImage(user.avatar), fit: BoxFit.cover)),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: const Alignment(0, 0),
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.black.withOpacity(0.3)
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(_horizontalPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            textSelectionTheme: TextSelectionThemeData(
                              selectionColor: primaryColor,
                            ),
                          ),
                          child: _buildSelectedText(
                            content:
                                hasRemark ? user.showName() : user.nickname,
                            style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      sizeWidth4,
                      getGenderIcon(user.gender,
                          radius: 8, size: 12, square: true),
                    ],
                  ),
                  sizeHeight2,
                  if (hasRemark) ...[
                    _buildSelectedText(
                      content: user?.nickname == null
                          ? ''
                          : '昵称:%s'.trArgs([user.nickname]),
                      // overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.69),
                          fontWeight: FontWeight.w400),
                    ),
                    sizeHeight2,
                  ],
                  Row(
                    children: [
                      _buildSelectedText(
                        content: isNotNullAndEmpty(user.username)
                            ? '#${user.username}'
                            : '',
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.69)),
                      ),
                      sizeWidth4,
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: user.username));
                          showToast('复制成功'.tr);
                        },
                        child: Icon(
                          IconFont.buffChatCopy,
                          size: 14,
                          color: Colors.white.withOpacity(0.69),
                        ),
                      ).clickable(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedText({@required String content, TextStyle style}) {
    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: TextSelectionThemeData(
          selectionColor: primaryColor,
        ),
      ),
      child: SelectableText(
        content ?? '',
        // maxLines: 1,
        style: style,
        scrollPhysics: const NeverScrollableScrollPhysics(),
      ),
    );
  }
}
