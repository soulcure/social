import 'package:flutter/cupertino.dart';
import 'package:im/app/modules/tc_doc_add_group_page/controllers/tc_doc_add_group_page_controller.dart';
import 'package:im/app/modules/tc_doc_add_group_page/entities/tc_doc_group.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/check_square_box.dart';

mixin TcDocGroupMixin {
  List<Widget> buildLeading(TcDocAddGroupPageController controller, String id,
          TcDocGroupType type) =>
      [
        IgnorePointer(
          child: CheckSquareBox(
            value: controller.isSelected(id),
          ),
        ),
        sizeWidth12,
      ];
}
