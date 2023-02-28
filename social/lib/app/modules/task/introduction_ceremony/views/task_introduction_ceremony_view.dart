import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/task/introduction_ceremony/views/task_introduction_rules.dart';
import 'package:im/app/modules/task/introduction_ceremony/views/task_introduction_survey.dart';
import 'package:im/app/modules/task/task_util.dart';
import 'package:im/app/modules/task/task_ws_util.dart';
import 'package:im/common/extension/list_extension.dart';

import '../controllers/task_introduction_ceremony_controller.dart';

class TaskIntroductionCeremonyView
    extends GetView<TaskIntroductionCeremonyController> {
  @override
  Widget build(BuildContext context) {
    TaskWsUtil.isOnTaskPage = true;
    if (TaskUtil.instance?.takEntity?.rule != null &&
        TaskUtil.instance.takEntity.rule.hasValue) {
      return const TaskIntroductionRules();
    } else {
      return const TaskIntroductionSurvey();
    }
  }
}
