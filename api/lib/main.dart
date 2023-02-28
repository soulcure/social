import 'dart:convert';
import 'dart:io';
import 'package:api/creater/code_creater.dart';
import 'package:api/utils.dart';
import 'package:dart_style/dart_style.dart';
import "package:path/path.dart" show dirname, join, normalize;
import './config.dart';

const listUrl =
    "$host/api/interface/list?token=$token&page=1&limit=1000&project_id=$projectId";
const apiUrl = "$host/api/interface/get?token=$token&id=";

/// 获得当前目录
_scriptPath() {
  var script = Platform.script.toString();
  if (script.startsWith("file://")) {
    script = script.substring(7);
  } else {
    final idx = script.indexOf("file:/");
    script = script.substring(idx + 5);
  }
  if (Platform.isWindows && script.startsWith("/")) {
    script = script.substring(1);
  }
  return script;
}

/// 根据地质获得内容
_getDataByUrl(String url) async {
  var request = await HttpClient().getUrl(Uri.parse(url));
  var response = await request.close();
  String responseBody = await response.transform(utf8.decoder).join();
  return responseBody;
}

/// 根据ID生成dart类
_createCode(int id, [bool format = true]) async {
  // print(apiUrl + id.toString());
  // 获得接口数据
  var data = json.decode(await _getDataByUrl(apiUrl + id.toString()))["data"];
  if (data == null) {
    throw '消息不存在';
  }

  String path = data["path"];
  String code = CodeCreater.create(data);

  // 格式化代码
  final formatter = new DartFormatter();
  code = formatter.format(code);

  // 写入文件
  final currentDirectory = dirname(_scriptPath());
  // 创建文件夹
  Directory(normalize(join(currentDirectory, saveDir))).createSync();
  final filePath = normalize(
    join(currentDirectory, saveDir + getFileName(path) + '.dart'),
  );
  File(filePath).writeAsString(code);
}

main(List<String> args) async {
  print("wait...");
  print("接口网站：$host/project/$projectId/interface/api");

  var startTime = DateTime.now();

  // 支持id传递，用空格隔开
  if (args.length > 0) {
    args.forEach((String id) async {
      await _createCode(int.parse(id));
    });
  } else {
    // 获得接口列表
    var data = json.decode(await _getDataByUrl(listUrl));
    var list = data["data"]["list"];
    list.forEach((item) async {
      var id = item["_id"];
      if (item["status"] == "done") {
        try {
          await _createCode(id);
        } catch (e) {
          print("[Error $id]" + e.toString());
        }
      } else {
        String path = item['path'];
        print("[Warn $id][$path] 接口状态未完成，跳过代码生成");
      }
    });
  }

  print("done!cost " +
      DateTime.now().difference(startTime).inMilliseconds.toString());
}
