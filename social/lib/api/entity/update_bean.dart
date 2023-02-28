/// status : true
/// message : "1000"
/// data : {"upgrade":{"is_upgrade":"1","version":"1.1.0","download":"https://www.apple.com.cn/ios/app-store/","is_enforce":"0","content":"我更新了"},"h5_url":{"terms":"https://huaming.idreamsky.com/terms","privacy":"https://huaming.idreamsky.com/privacy","complaint":"https://192.168.88.117:9000/Complaint.html#/","suggestion":"https://192.168.88.117:9000/Complaint.html#/"}}

class UpdateBean {
  DataBean data;

  UpdateBean.fromMap(Map<String, dynamic> map) {
    data = DataBean.fromMap(map);
  }

  Map toJson() => {
        "data": data,
      };
}

/// upgrade : {"is_upgrade":"1","version":"1.1.0","download":"https://www.apple.com.cn/ios/app-store/","is_enforce":"0","content":"我更新了"}
/// h5_url : {"terms":"https://huaming.idreamsky.com/terms","privacy":"https://huaming.idreamsky.com/privacy","complaint":"https://192.168.88.117:9000/Complaint.html#/","suggestion":"https://192.168.88.117:9000/Complaint.html#/"}

class DataBean {
  UpgradeBean upgrade;
  String imageAudit;
  String textAudit;

  DataBean.fromMap(Map<String, dynamic> map) {
    upgrade = UpgradeBean.fromMap(map['upgrade']);
    imageAudit = map['image_audit'];
    textAudit = map['text_audit'];
  }

  Map toJson() => {"upgrade": upgrade, 'text_audit': textAudit, 'image_audit': imageAudit};
}

/// is_upgrade : "1"
/// version : "1.1.0"
/// download : "https://www.apple.com.cn/ios/app-store/"
/// is_enforce : "0"
/// content : "我更新了"

class UpgradeBean {
  String isUpgrade;
  String version;
  String download;
  String isEnforce;
  String content;

  UpgradeBean.fromMap(Map<String, dynamic> map) {
    isUpgrade = map['is_upgrade'];
    version = map['version'];
    download = map['download'];
    isEnforce = map['is_enforce'];
    content = map['content'];
  }

  Map toJson() => {
        "is_upgrade": isUpgrade,
        "version": version,
        "download": download,
        "is_enforce": isEnforce,
        "content": content,
      };
}
