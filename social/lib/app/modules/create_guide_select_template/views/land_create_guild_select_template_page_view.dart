import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/entity/create_template.dart';
import 'package:im/app/modules/create_guide_select_template/controllers/create_guild_select_template_page_controller.dart';
import 'package:im/app/modules/home/controllers/home_scaffold_controller.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:im/utils/image_operator_collection/image_builder.dart';
import 'package:im/utils/image_operator_collection/image_widget.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/button/more_icon.dart';
import 'package:im/widgets/land_pop_app_bar.dart';
import 'package:pedantic/pedantic.dart';
import 'package:websafe_svg/websafe_svg.dart';

import '../../../../routes.dart';
import '../../../../svg_icons.dart';

class LandCreateGuildSelectTemplatePageView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return popWrap(
      height: 602,
      child: GetBuilder<CreateGuildSelectTemplatePageController>(
          init: CreateGuildSelectTemplatePageController(),
          builder: (ctl) {
            return Column(
              children: [
                LandPopAppBar(
                  title: '创建服务器'.tr,
                ),
                Expanded(
                  child: ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 22, bottom: 4),
                        child: Text(
                          '选择模板快速创建'.tr,
                          style: Get.textTheme.bodyText1.copyWith(fontSize: 14),
                        ),
                      ),
                      ...ctl.templateList
                          .map((e) => _buildItem(e, context))
                          .toList(),
                    ],
                  ),
                ),
              ],
            );
          }),
    );
  }

  Widget _buildItem(CreateTemplate tmp, BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: InkWell(
          onTap: () async {
            Get.back();
            final res = await Routes.pushCreateGuildPage(context,
                batchGuidType: tmp.guildTeam) as GuildTarget;
            if (res != null) {
              // 创建服务器成功插入到官方服务器后面
              final model = ChatTargetsModel.instance;
              //web版本: 创建成功后频道需要排序
              if (res.channels != null && res.channels.isNotEmpty)
                res.sortChannels();
              // 创建完服务器默认选中
              model.addChatTarget(res);
              unawaited(model.selectChatTarget(res));

              unawaited(HomeScaffoldController.to.gotoWindow(1));
            }
          },
          child: Container(
            padding: const EdgeInsets.only(left: 20, right: 20),
            decoration: BoxDecoration(
              color: Get.theme.backgroundColor,
              border: Border.all(
                color: Get.theme.dividerTheme.color,
              ),
              borderRadius: const BorderRadius.all(
                Radius.circular(6),
              ),
            ),
            height: 64,
            child: Row(
              children: [
                _image(tmp.serverIcon),
                sizeWidth16,
                Text(
                  tmp.teamName,
                  // style: Get.theme.textTheme.bodyText2.copyWith(
                  //   fontSize: 16,
                  //   fontWeight: FontWeight.w500,
                  // ),
                  style: Get.textTheme.bodyText2.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                spacer,
                MoreIcon(color: Get.theme.disabledColor)
              ],
            ),
          ),
        ),
      );

  Widget _image(String url) {
    if (url.isEmpty) {
      return WebsafeSvg.asset(SvgIcons.handleCreate, width: 44, height: 44);
    } else {
      return ImageWidget.fromCachedNet(
        CachedImageBuilder(
          width: 44,
          height: 44,
          imageUrl: url,
          cacheManager: CustomCacheManager.instance,
        ),
      );
    }
  }
}
