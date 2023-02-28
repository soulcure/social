import 'dart:convert';

import 'package:dynamic_view/dynamic_view.dart';
import 'package:dynamic_view/widgets/config.dart';
import 'package:dynamic_view/widgets/models/advance_widgets.dart';
import 'package:dynamic_view/widgets/models/base_widgets.dart';
import 'package:dynamic_view/widgets/models/layouts.dart';
import 'package:dynamic_view/widgets/models/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:get/get.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/home/view/text_chat/items/rich_text_item.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/components/embed_builder_io.dart';
import 'package:im/widgets/poly_text/poly_text.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:markdown/markdown.dart' as md hide Text;
import 'package:markdown_quill/markdown_quill.dart';

import '../message_card_item.dart';

/// Markdown 的 @、# 解析器
class MdMentionSyntax extends md.InlineSyntax {
  MdMentionSyntax()
      : super(r'\$\{[@#][!&]?\d+\}', startCharacter: r'$'.codeUnitAt(0));

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final ele = md.Element.text("@", "");
    ele.attributes["at"] = match[0];
    parser.addNode(ele);
    return true;
  }
}

final _mdDocument = md.Document(encodeHtml: false, inlineSyntaxes: [
  MdMentionSyntax(),
]);

final _mdToDelta =
    MarkdownToDelta(markdownDocument: _mdDocument, customElementToEmbeddable: {
  "@": (attributes) {
    return MentionEmbed(
        denotationChar: "", id: attributes["at"], value: "", prefixChar: "@");
  }
});

final _keyCountPattern = RegExp(r"\$\{keyCount\((\d+)\)\}");

class DynamicViewHrefNotification extends Notification {
  final String href;

  const DynamicViewHrefNotification(this.href);
}

class FbDynamicViewConfig implements DynamicViewConfig {
  FbDynamicViewConfig() {
    DynamicView.registerTag(WidgetTag.text.name,
        builder: (_data) {
          final data = _data as TextData;
          var text = data.data;
          return Builder(builder: (context) {
            final injector = DynamicViewWidgetDataInjector.of(context);
            if (injector != null) {
              text = text.replaceAllMapped(_keyCountPattern, (match) {
                final key = match.group(1);
                return injector.data.getKeyCount(key).toString();
              });
            }

            return Text(
              text,
              style: data.style?.toTextStyle(),
              textAlign: data.textAlign,
              softWrap: data.softWrap,
              overflow: data.overflow,
              maxLines: data.maxLines,
            );
          });
        },
        parser: (e) => TextData.fromJson(e));

    DynamicView.registerTag(
      FanbookWidgetTag.userAvatar.name,
      builder: (data) {
        if (data is UserAvatarData) {
          return Builder(builder: (context) {
            final gid = DynamicViewWidgetDataInjector.of(context)?.guildId;

            return _EvalId(
                expr: data.id,
                builder: (id) {
                  if (id == null) return const SizedBox();

                  return RealtimeAvatar(
                    userId: id,
                    guildId: gid,
                    size: data.size ?? 30,
                  );
                });
          });
        } else {
          throw Exception('impossible: data must be UserAvatarData');
        }
      },
      parser: (data) => UserAvatarData.fromJson(data),
    );

    DynamicView.registerTag(
      FanbookWidgetTag.userName.name,
      builder: (data) {
        if (data is UserNameData) {
          return _EvalId(
              expr: data.id,
              builder: (id) {
                if (id == null) return const SizedBox();
                return RealtimeNickname(
                  userId: id,
                  style: data.style?.toTextStyle(),
                );
              });
        } else {
          throw Exception('impossible: data must be UserNameData');
        }
      },
      parser: (data) => UserNameData.fromJson(data),
    );
    DynamicView.registerTag(
      FanbookWidgetTag.channelName.name,
      builder: (data) {
        if (data is ChannelNameData) {
          return RealtimeChannelName(
            data.id,
            style: data.style?.toTextStyle(),
          );
        } else {
          throw Exception('impossible: data must be ChannelNameData');
        }
      },
      parser: (data) => ChannelNameData.fromJson(data),
    );
    DynamicView.registerTag(
      FanbookWidgetTag.markdown.name,
      builder: (data) {
        if (data is MarkdownData) {
          Object delta;
          try {
            delta = _mdToDelta.convert(data.data);
          } catch (m, e) {
            logger.severe(m, e);
          }
          // 这个 Builder 是用来降低出错时的影响范围
          return Builder(builder: (context) {
            final gid = DynamicViewWidgetDataInjector.of(context)?.guildId;

            Document doc;
            try {
              doc = Document.fromDelta(delta);
            } catch (e) {
              logger.severe("消息卡片无法解析 markdown $delta");
            }
            if (doc == null) return const SizedBox();

            /// TODO 让 PolyText 自身支持 flexible
            return IntrinsicWidth(
              child: PolyText(
                document: doc,
                baseStyle: Get.textTheme.bodyText2,
                quoteVerticalSpacing: 8,
                codeVerticalSpacing: 8,
                embedBuilder: embedBuilder,
                mentionBuilder: (embed) => RichTextItemState.mentionBuilder(
                    embed,
                    guildId: gid,
                    widgetSpanAlignment: PlaceholderAlignment.middle),
              ),
            );
          });
        } else {
          throw Exception('impossible: data must be MarkdownData');
        }
      },
      parser: (data) => MarkdownData.fromJson(data),
    );
    DynamicView.registerTag(
      WidgetTag.image.name,
      builder: (widgetData) {
        final data = widgetData as ImageData;
        Widget widget = Image.network(FileObjectId(data.src).getUrl(),
            width: data.width,
            height: data.height,
            fit: data.fit,
            alignment: data.alignment ?? Alignment.center,
            repeat: data.repeat ?? ImageRepeat.noRepeat,
            centerSlice: data.centerSlice);
        if (data.radius != null && data.radius != 0) {
          widget = ClipRRect(
            borderRadius: BorderRadius.circular(data.radius),
            child: widget,
          );
        }
        return widget;
      },
      parser: (data) => ImageData.fromJson(data),
    );

    DynamicView.registerTag(
      FanbookWidgetTag.keySet.name,
      parser: (data) => KeySetData.fromJson(data),
      builder: (widgetData) {
        final data = widgetData as KeySetData;
        return Builder(
          builder: (context) {
            final injector = DynamicViewWidgetDataInjector.of(context);
            bool yes = false;
            if (data.key == null) {
              yes = injector.data.hasAnyKeyMySelf() != null;
            } else {
              yes = injector.data.hasKeyMyself(data.key);
            }

            return DynamicView.fromData(yes ? data.yes : data.no);
          },
        );
      },
    );
  }

  @override
  void onClick(BuildContext context, String event) {
    DynamicViewHrefNotification(event).dispatch(context);
  }
}

/// 消息卡片的图片来源于 Fanbook COS 服务，不允许使用外部图片
/// FileObjectId 将被用于解析出图片的 URL
///
/// 事实上有方式可以使用外部图片，即使用如下格式：
/// 1::00::0::ayNDY1LDM2NDQwNzMyNjkmZm09MTkzJmY9R0lG
/// 最后一段字符串是第三方图片地址的 base64 编码字符串
///
/// TODO 当前版本 OpenAPI 不支持，待支持后完善
class FileObjectId {
  final String originId;

  FileObjectId(this.originId);

  String getUrl() {
    final ss = originId.split("::");
    if (ss.length < 4) {
      throw Exception("invalid file object id: $originId");
    }
    return const Utf8Decoder().convert(base64Decode(ss[3]));
  }
}

/// 用来计算 UI 数据中的用户 id，例如它可以将数据 `${userId(key)}` 解析为用户 id
class _EvalId extends StatelessWidget {
  static RegExp pattern = RegExp(r"\$\{userId\((\w+)\)\}");
  final String expr;
  final Widget Function(String) builder;

  const _EvalId({this.expr, this.builder});

  @override
  Widget build(BuildContext context) {
    if (expr[0] == r'$') {
      final injector = DynamicViewWidgetDataInjector.of(context);
      if (injector == null) {
        return builder(null);
      }
      final match = pattern.firstMatch(expr);
      if (match != null) {
        final key = match.group(1);

        final keyUserId = injector.data.getKeyUser(key);
        if (keyUserId != null) {
          return builder(keyUserId);
        }
      }
    }
    return builder(expr);
  }
}
