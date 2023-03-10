import 'package:characters/characters.dart';
import 'package:im/core/config.dart';

const String nullChar = '\u{200B}';

extension StringExtension on String {
  bool get hasValue => this != null && isNotEmpty;

  bool get noValue => this == null || isEmpty;

  String get pureValue {
    String value = '';
    value = replaceAll('\r', '');
    value = value.replaceAll('\n', '');
    value = value.replaceAll(' ', '');
    return value;
  }

  String takeCharacter(int count, {bool ellipsis = true}) {
    return characters.length <= count
        ? characters.toString()
        : '${characters.take(count).toString()}...';
  }

  bool get isMessageLink {
    return startsWith("${Config.webLinkPrefix}channels");
  }

  String get breakWord {
    return characters.map((e) => "$e$nullChar").join();
  }

  Future<String> replaceAllMappedAsync(
      Pattern exp, Future<String> Function(Match match) replace) async {
    final StringBuffer replaced = StringBuffer();
    int currentIndex = 0;
    for (final match in exp.allMatches(this)) {
      final prefix = match.input.substring(currentIndex, match.start);
      currentIndex = match.end;
      replaced..write(prefix)..write(await replace(match));
    }
    replaced.write(substring(currentIndex));
    return replaced.toString();
  }

  bool isPureNumber() {
    final reg = RegExp('^-?[0-9]+');
    return reg.hasMatch(this);
  }

  String trimEmptyEnd() => replaceAll(RegExp(r'\n+$'), '');

  String compressLineString() => trim().replaceAll(RegExp("\n{2,}"), "\n");
}
