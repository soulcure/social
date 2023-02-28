// import 'package:flutter_quill/models/documents/document.dart';
import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart' hide Text;

extension OperationExtension on Operation {
  bool get isAt =>
      this != null && attributes != null && attributes['at'] != null;
  bool get isChannel =>
      this != null && attributes != null && attributes['channel'] != null;
  bool get isImage {
    if (!isEmbed) return false;
    // if (value is BlockEmbed) {
    //   return (value as BlockEmbed).type == 'image';
    // }
    final embed = Embeddable.fromJson(value);
    return embed is ImageEmbed;
  }

  bool get isVideo {
    if (!isEmbed) return false;
    // if (value is BlockEmbed) {
    //   return (value as BlockEmbed).type == 'video';
    // }
    // return value['_type'] == 'video';
    final embed = Embeddable.fromJson(value);
    return embed is VideoEmbed;
  }

  bool get isMedia => isImage || isVideo;

  bool get isEmbed {
    final res = value != null && (value is BlockEmbed || value is Map);
    return res;
  }
  // attributes != null &&
  // hasAttribute('embed') &&
  // attributes['embed']['type'] != null;
}

extension DeltaExtension on Delta {
  int get allLen {
    return toJson()
        .fold(0, (previousValue, element) => previousValue += element.length);
  }
}

extension NotusDocumentExtension on Document {
  bool get isContentEmpty {
    return toPlainText().toString().replaceAll(RegExp(r'[\n, ]'), '').trim() ==
        '';
  }

  String encode() {
    return jsonEncode(toDelta());
  }

  List<ImageEmbed> get imageEmbeds {
    final List<ImageEmbed> images = [];
    final oList = toDelta().toList();
    for (final i in oList) {
      if (i.isImage) {
        final image = Embeddable.fromJson(i.value) as ImageEmbed;
        images.add(image);
      }
    }
    return images;
  }

  List<VideoEmbed> get videoEmbeds {
    final List<VideoEmbed> videos = [];
    final oList = toDelta().toList();
    for (final i in oList) {
      if (i.isVideo) {
        final video = Embeddable.fromJson(i.value) as VideoEmbed;
        videos.add(video);
      }
    }
    return videos;
  }

  List<Embeddable> get imageAndVideoEmbeds {
    final List<Embeddable> embeds = [];
    final oList = toDelta().toList();
    for (final i in oList) {
      if (i.isVideo || i.isImage) {
        final embed = Embeddable.fromJson(i.value);
        embeds.add(embed);
      }
    }
    return embeds;
  }

  String toContent() => root.children.map((e) => e.toContent()).join();
}
