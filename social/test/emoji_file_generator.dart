import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:im/utils/emo_util.dart';
import 'package:path/path.dart' as p;

void main() {
  test('生成emoji对应json文件', () {
    final Directory curDir = Directory.current;
    final emoPath = p.join(curDir.path, getEmoDir());

    final emoDir = Directory(emoPath);
    if (!emoDir.existsSync()) return;

    final tempEmoDir = p.join(emoPath, tempEmo);
    final reactionEmoDir = p.join(emoPath, reactionEmo);

    final Map<String, Map<String, String>> emoList = {};

    createJsonWithDir(Directory(tempEmoDir), emoList);
    createJsonWithDir(Directory(reactionEmoDir), emoList);

    final Map<String, String> allEmoList = {};

    ///遍历收集到的列表，生成对应的json文件
    emoList.forEach((key, value) {
      final emoJsonFile = File(p.join(emoPath, '$key.json'));
      allEmoList[key] = p.join(getEmoDir(), '$key.json');
      if (emoJsonFile.existsSync()) {
        emoJsonFile.deleteSync();
      }
      emoJsonFile.createSync();
      emoJsonFile.writeAsStringSync(jsonEncode(value));
      debugPrint('文件:${p.basename(emoJsonFile.path)} 生成成功');
    });

    ///生成emoji文件集合
    final allEmoJsonFile = File(p.join(emoPath, allEmoFile));
    if (allEmoJsonFile.existsSync()) {
      allEmoJsonFile.deleteSync();
    }
    allEmoJsonFile.createSync();
    allEmoJsonFile.writeAsStringSync(jsonEncode(allEmoList));
  });

  test('读取emoji测试', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final emoData = await readEmoList();
    print(emoData);
  });

  test('截取测试', () {
    const name = '38-吐-Puke.png';
    final list = name.substring(0, name.indexOf(".")).split('-');
    print(list);
  });
}

void createJsonWithDir(
    Directory dir, Map<String, Map<String, String>> emoList) {
  if (!dir.existsSync()) return;
  final dirName = p.basename(dir.path);
  final files = dir.listSync();
  final LinkedHashMap<String, String> emoEntityList = LinkedHashMap();
  final LinkedHashMap<String, String> enEmoEntityList = LinkedHashMap();
  final LinkedHashMap<String, String> reactionEntityList = LinkedHashMap();
  final LinkedHashMap<String, String> enReactionEntityList = LinkedHashMap();

  ///文件读取后，进行排序
  files.sort((a, b) {
    if (a.path.contains('DS_Store') || b.path.contains('DS_Store')) return 1;
    final nameA = p.basename(a.path);
    final nameB = p.basename(b.path);
    final namesA = nameA.substring(0, nameA.lastIndexOf(".")).split('-');
    final namesB = nameB.substring(0, nameB.lastIndexOf(".")).split('-');
    return int.parse(namesA[0]) - int.parse(namesB[0]);
  });
  for (final file in files) {
    if (file.path.contains('DS_Store')) continue;
    final name = p.basename(file.path);
    final names = name.substring(0, name.lastIndexOf(".")).split('-');
    if (names.length < 3) continue;
    final newFileName = name.substring(name.lastIndexOf("-") + 1, name.length);
    emoEntityList[names[1]] = p.join(getEmoDir(), allEmo, newFileName);
    enEmoEntityList[names[2]] = p.join(getEmoDir(), allEmo, newFileName);
    reactionEntityList[names[1]] = p.join(getEmoDir(), allEmo, newFileName);
    enReactionEntityList[names[2]] = p.join(getEmoDir(), allEmo, newFileName);
    final newFilePath = p.join(getEmoDir(), allEmo, newFileName);
    final newFile = File(newFilePath);
    if (!newFile.existsSync()) file.renameSync(newFilePath);
  }

  if (dirName == tempEmo) {
    emoList['emoji_zh'] = emoEntityList;
    emoList['emoji_en'] = enEmoEntityList;
  } else {
    emoList['emoji_reaction_zh'] = reactionEntityList;
    emoList['emoji_reaction_en'] = enReactionEntityList;
  }
}

const String tempEmo = 'temp_emoji';
const String reactionEmo = 'reaction_emoji';
const String allEmo = 'all_emoji';

class EmoInfo {
  List<String> names;
  String assets;

  EmoInfo(this.names, this.assets);
}
