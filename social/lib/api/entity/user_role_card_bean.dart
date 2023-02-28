/// title : {"img":"https://fb-cdn.fanbook.mobi/fanbook/app/files/third_part/aow/rank/ic_soldier1.png"}
/// slots : [[{"label":"玩家昵称","value":"加里埃莉卡"}],[{"label":"区服名","value":"许昕"}],[{"img":"https://fb-cdn.fanbook.mobi/fanbook/app/files/third_part/aow/rank/ic_soldier1.png","value":"新兵"},{"img":"https://fb-cdn.fanbook.mobi/fanbook/app/files/third_part/aow/mvp-120x120.png","value":"MVP0场"},{"img":"https://fb-cdn.fanbook.mobi/fanbook/app/files/third_part/aow/win_ratio-120x120.png","value":"排位胜率50%"}]]

class GuildCardBean {
  TitleBean title;
  Authority authority;
  List<List<SlotsBean>> slots;

  GuildCardBean.fromMap(map) {
    if (map == null) return;
    title = TitleBean.fromMap(map['title'] ?? {});
    authority = Authority.fromMap(map['authority'] ?? {});
    slots = [
      ...(map['slots'] as List ?? [])
          .map((o) => [...(o as List ?? []).map((oo) => SlotsBean.fromMap(oo))])
    ];
  }

  Map toJson() => {
        "title": title.toJson(),
        "slots": slots.map((o) => o.map((e) => e.toJson()).toList()).toList(),
        "authority": authority.toJson(),
      };
}

/// label : "玩家昵称"
/// value : "加里埃莉卡"

class SlotsBean {
  String label;
  String value;
  String img;

  SlotsBean.fromMap(map) {
    label = map['label'];
    value = map['value'];
    img = map['img'];
  }

  Map toJson() => {
        "label": label,
        "value": value,
        "img": img,
      };
}

/// img : "https://fb-cdn.fanbook.mobi/fanbook/app/files/third_part/aow/rank/ic_soldier1.png"

class TitleBean {
  String img;

  TitleBean.fromMap(map) {
    img = map['img'];
  }

  Map toJson() => {
        "img": img,
      };
}

class Authority {
  String icon;
  String name;

  Authority.fromMap(map) {
    icon = map['icon'];
    name = map['name'];
  }

  Map toJson() => {"icon": icon, "name": name};
}
