import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:csv/csv.dart';
import 'package:process_run/shell.dart';
import 'package:pub_semver/pub_semver.dart';

import 'string_literal_visitor.dart';

Set<String> result = {};
var argResults;

/// 需要翻译的工程文件目录
String trProjectFileDir = '${Directory.current.parent.path}/social/lib';

/// 该csv文件包含了已经翻译和未翻译的内容(翻译人员需要对没有翻译的进行翻译即可)
String csvFilePathName =
    '${Directory.current.path}/bin/string-literal-list.csv';

/// 已经翻译的内容保存在该文件(是后期用来对比工程中那些文件已经翻译 和 未翻译的)
String csvDoneTrFilePathName = '${Directory.current.path}/done.csv';

bool isGenerateTrCode = false;

/// 是否自定义目录
bool isCustomDirectory() {
  stdout.writeln('推荐: 使用默认路径(选择 N)');
  stdout.writeln('您是否需要自定义翻译的输入输出目录(Y/N)');
  final isCustom = stdin.readLineSync();
  if (isCustom.toUpperCase() == 'Y') {
    return true;
  }
  // else if (isCustom.toUpperCase() == 'N') {
  //   return false;
  // } else {
  //   return isCustomDirectory();
  // }
  return false;
}

/// 是否自定义目录
bool isGenerateTr() {
  stdout.writeln('是否在代码中生成.tr对应的代码(Y/N)');

  final isGenerate = stdin.readLineSync();
  if (isGenerate.toUpperCase() == 'Y') {
    return true;
  }
  // else if (isGenerate.toUpperCase() == 'N') {
  //   return false;
  // } else {
  //   return isGenerateTr();
  // }
  return false;
}

// 编译可执行文件命令
// dart2native extract_chinese_strings.dart -o ../bin/extract_chinese_strings

Future<void> main(List<String> arguments) async {
  stdout.writeln(
      '*******************************************************************************************');
  stdout.writeln('默认需要扫描翻译的dart文件目录(递归扫描): $trProjectFileDir');
  stdout.writeln('默认导出工程需要翻译后的csv文件的目录: $csvFilePathName');
  stdout.writeln('默认已经翻译内容的目录: $csvDoneTrFilePathName');
  stdout.writeln(
      '*******************************************************************************************');
  stdout.writeln('');

  if (isCustomDirectory()) {
    stdout.writeln('请参考默认路径');

    stdout.writeln('请输入你需要扫描翻译的dart文件目录');
    String tempPath = stdin.readLineSync();
    if (tempPath.isNotEmpty) trProjectFileDir = tempPath;

    if (!Directory(trProjectFileDir).existsSync()) {
      stdout.writeln('No dictionary found.');
      return;
    }

    stdout.writeln('$trProjectFileDir');

    stdout.writeln('请输入你导出工程需要翻译后的csv文件的目录');
    tempPath = stdin.readLineSync();
    if (tempPath.isNotEmpty) csvFilePathName = tempPath;
    stdout.writeln('$csvFilePathName');

    stdout.writeln('默认已经翻译内容的目录');
    tempPath = stdin.readLineSync();
    if (tempPath.isNotEmpty) csvDoneTrFilePathName = tempPath;
    stdout.writeln('$csvDoneTrFilePathName');
  }

  isGenerateTrCode = isGenerateTr();
  exitCode = 0;

  /// 测试调试代码
  // exit(exitCode);

  /// 读取项目中的dart文件,把对应的字符串会add 到 result集合里
  readProjectString();

  if (result == null || result.isEmpty) return;

  await generateFile();
}

/// 生产csv文件及对应工程json文件
Future<void> generateFile() async {
  /// 读取已经翻译过的内容
  final translatedList = await readTranslatedCSV();

  var dir = Directory(trProjectFileDir);
  if (dir.existsSync()) {
    /// 用来存储项目中的string内容及对应翻译内容
    /// 注意: csv文件被导入飞书的时候,部分文本内容前后空格会被去掉
    var file = File(csvFilePathName);

    /// 默认内容
    var data = <List>[
      ['遇到文中无法翻译的字符，比如特殊符号，请翻译后保留，如果遇到占位符号 {}，也请在翻译后的文本中对应位置保留', ''],
      ['中文 / 英文', 'Chinese / English'],
    ];

    /// 遍历项目中的string内容 及合并已经翻译的内容
    for (var e in result) {
      var tempValueString = '';
      translatedList.forEach((element) {
        String translatedKey = element.first
            .toString()
            .replaceAll(RegExp(r'\r'), '')
            .replaceAll(r"\r", "");
        if (e == translatedKey) {
          tempValueString = element.last
              .toString()
              .replaceAll(RegExp(r'\r'), '')
              .replaceAll(r"\r", "");
          return;
        }
      });
      data.add([e, tempValueString]);
    }

    /// 把内容写入csv文件
    file.writeAsString(const ListToCsvConverter().convert(data));

    final jsonEnMap = {};
    translatedList.forEach((element) {
      if (element.last == null || element.last.toString().isEmpty) {
        jsonEnMap[element.first] =
            element.first.replaceAll(RegExp(r'\r'), '').replaceAll(r"\r", "");
        return;
      }
      jsonEnMap[element.first] =
          element.last.replaceAll(RegExp(r'\r'), '').replaceAll(r"\r", "");
    });

    var jsonEnString = jsonEncode(jsonEnMap);
    jsonEnString =
        jsonEnString.replaceAll(RegExp(r'\r'), '').replaceAll(r"\r", "");

    /// 英文
    // var fileEnJson = File('${argResults['output'] ?? "."}/string-en.json');
    var fileEnJson = File('${dir.path}/locale/translation/translation_en.dart');
    var fileEnContent = await fileEnJson.readAsString(encoding: utf8);
    fileEnContent = fileEnContent.replaceAll(
        RegExp(r'(return \{)([\s\S]*) (\};)'), 'return $jsonEnString;');
    fileEnJson.writeAsString(fileEnContent);
    var shell = Shell();
    print('格式化文件: ${fileEnJson.path}');
    await shell.run('flutter format ${fileEnJson.path}');

    /// 中文
    final jsonZhMap = {};
    data.forEach((element) {
      jsonZhMap[element.first] = element.first;
    });

    var jsonZhString = jsonEncode(jsonZhMap);
    jsonZhString =
        jsonZhString.replaceAll(RegExp(r'\r'), '').replaceAll(r"\r", "");
    // var fileZhJson = File('${argResults['output'] ?? "."}/string-zh.json');
    var fileZhJson = File('${dir.path}/locale/translation/translation_zh.dart');

    var fileZhContent = await fileZhJson.readAsString(encoding: utf8);
    fileZhContent = fileZhContent.replaceAll(
        RegExp(r'(return \{)([\s\S]*) (\};)'), 'return $jsonZhString;');

    fileZhJson.writeAsString(fileZhContent);

    print('格式化文件: ${fileZhJson.path}');
    await shell.run('flutter format ${fileZhJson.path}');

    /// 是否需要对代码生成.tr代码
    if (isGenerateTrCode) await generateTrCode(jsonZhMap);
  } else {
    stdout.writeln('No dictionary found.');
  }
}

/// 读取翻译过的内容
Future<List> readTranslatedCSV() async {
  /// 已经翻译过的文件( 这里需要注意done.csv文件只能保留两列,多出来的进行隐藏)
  var translatedFile = File(csvDoneTrFilePathName);

  if (!translatedFile.existsSync()) return [];

  /// 获取已经翻译过的内容
  final translatedList = await translatedFile
      .openRead()
      .transform(utf8.decoder)
      .transform(CsvToListConverter())
      .toList();

  return translatedList;
}

Future<void> generateTrCode(Map jsonMap) async {
  var dir = Directory(trProjectFileDir);

  // var shell = Shell();
  if (dir.existsSync()) {
    final files = dir.listSync(recursive: true).whereType<File>();
    for (final fileItem in files) {
      // if (fileItem.path.contains('translation_en') ||
      //     fileItem.path.contains('translation_zh')) {
      //   await shell.run('flutter format ${fileItem.path}');
      //   print('格式化文件: ${fileItem.path}');
      // }
      if (fileItem.path.contains('.DS_Store') ||
          fileItem.path.contains('translation_en') ||
          fileItem.path.contains('translation_zh')) continue;

      /// 直播暂不添加翻译
      if (fileItem.path.contains('social/lib/live')) continue;
      var fileContent = await fileItem.readAsString(encoding: utf8);
      final filePath = fileItem.path;

      bool isImportGetX = false;
      for (final key in jsonMap.keys) {
        if (key.contains('%s') || key == null || key.isEmpty) {
          continue;
        }

        /// 是用来准确匹配字符串前后是否为 ' 或者 "的
        for (final item in ['\"', '\'']) {
          final findKey = "$item$key$item";
          int index = fileContent.indexOf(findKey);
          if (index == -1) continue;
          String targetString =
              fileContent.substring(index, index + findKey.length);
          index = fileContent.indexOf(targetString);
          if (index == -1) continue;

          if (!fileContent.contains('$targetString.tr')) {
            fileContent =
                fileContent.replaceAll(targetString, '$targetString.tr');

            // 防止重复替换
            fileContent = fileContent.replaceAll('.tr.tr', '.tr');

            /// 处理有换行的.tr重复处理
            fileContent = fileContent.replaceAll(
                RegExp(r'(\.tr)(\s|[\r\n])*(\.tr)'), '.tr');
            fileContent = fileContent.replaceAll(
                RegExp(r'(\.tr)(\s|[\r\n])*(\.tr)'), '.tr');
            isImportGetX = true;
          }
        }
      }
      if (isImportGetX) {
        /// 先清除所有导入过GetX的
        fileContent =
            fileContent.replaceAll('import \'package:get/get.dart\';\n', '');
        fileContent = 'import \'package:get/get.dart\';\n' + fileContent;
      }
      print('fileContent : $fileContent \n filePath : $filePath');
      fileItem.writeAsStringSync(fileContent);
    }
    stdout.writeln(
        '*******************************************************************************************');
    stdout.writeln('注意事项:');
    stdout.writeln('1.解决 const / final / 重复.tr调用 / 函数参数默认值等 对应错误');
    stdout.writeln('2.有对应的动态参数 %s 占位符的字符串, 需要调用 .trArgs([xxx]来处理');
    stdout.writeln('  举例: "发给 %s".trArgs([name])');
    stdout.writeln(
        '*******************************************************************************************');
  } else {
    stdout.writeln('No dictionary found.');
  }
}

/// 读取工程中的字符串
void readProjectString() {
  var dir = Directory(trProjectFileDir);
  if (dir.existsSync()) {
    dir.listSync(recursive: true).whereType<File>().forEach((element) {
      if (!element.path.contains('.DS_Store') && element.path.contains('.dart'))
        generate(element);
    });
  } else {
    stdout.writeln('No dictionary found.');
  }
}

//生成AST
void generate(File file) {
  try {
    stdout.writeln('Process file ${file.path}');
    var parseResult = parseFile(
        path: file.path,
        featureSet: FeatureSet.fromEnableFlags2(
            sdkLanguageVersion: Version.parse('2.12.2'), flags: []));
    var compilationUnit = parseResult.unit;
    var visitor = StringLiteralVisitor();
    compilationUnit.accept(visitor);
    result.addAll(visitor.result);
  } catch (e) {
    stderr.writeln('Parse file error: ${e.toString()}');
  }
}
