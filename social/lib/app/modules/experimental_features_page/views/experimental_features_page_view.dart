import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/icon_font.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';

import '../controllers/experimental_features_page_controller.dart';

class ExperimentalFeaturesPageView
    extends GetView<ExperimentalFeaturesPageController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppbar(
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: Column(
        // crossAxisAlignment: CrossAxisAlignment.,
        children: [
          const SizedBox(height: 32),
          Icon(
            IconFont.buffXingongnengshiyanshi,
            size: 48,
            color: Theme.of(context).iconTheme.color,
          ),
          const SizedBox(height: 32),
          Text(
            "新功能实验室".tr,
            style: TextStyle(
              fontSize: 22,
              color: Theme.of(context).iconTheme.color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "这里有Fanbook正在探索\n的新功能，欢迎体验".tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF646A73),
            ),
          ),
          const SizedBox(height: 48),
          const Divider(indent: 32, endIndent: 32),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildList() {
    final data = controller.data;
    return ListView.separated(
        itemBuilder: (context, index) {
          final item = data[index];
          return Container(
            height: 106.5,
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 17,
                        color: Theme.of(context).iconTheme.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    _buildSwitch(context, item),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  // 至少保证两个换行
                  "${item.desc}\n\n",
                  maxLines: 2,
                  style: const TextStyle(
                    color: Color(0xFF646A73),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const Divider(indent: 32, endIndent: 32),
        itemCount: data.length);
  }

  Widget _buildSwitch(BuildContext context, ExperimentalFeatureItem item) {
    return Transform.scale(
      scale: 0.9,
      alignment: Alignment.centerRight,
      child: Obx(() {
        return CupertinoSwitch(
            activeColor: Theme.of(context).primaryColor,
            value: item.value.value,
            onChanged: (value) {
              controller.changeState(item, value);
            });
      }),
    );
  }
}
