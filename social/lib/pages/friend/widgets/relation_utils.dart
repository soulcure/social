import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:im/db/db.dart';

import '../relation.dart';

class RelationUtils {
  static void update(String userId, RelationType relation) {
    Db.relationBox.put(userId, relation);
  }

  static ValueNotifier<Box<RelationType>> getRelationBox(String userId) {
    return Db.relationBox.listenable(keys: [userId]);
  }

  static RelationType getRelation(String userId) {
    return Db.relationBox.get(
      userId,
      defaultValue: RelationType.none,
    );
  }

  static Widget consumer(String userId,
      {ValueWidgetBuilder<RelationType> builder}) {
    return ValueListenableBuilder<Box<RelationType>>(
        valueListenable: Db.relationBox.listenable(keys: [userId]),
        builder: (context, box, widget) {
          final relation = box.get(userId);
          return builder(context, relation, widget);
        });
  }
}
