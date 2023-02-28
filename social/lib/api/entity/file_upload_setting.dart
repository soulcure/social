/// "size": 200, //MB单位
/// "upload_number": 4,//每次有多少次上传线程 -1 是客户端计算
/// "download_number": 4//每次有多少下载线程 -1 是客户端计算

class FileUploadSetting {
  int size;
  int uploadNumber;
  int downloadNumber;
  int downloadLastDay;

  FileUploadSetting({
    this.size,
    this.uploadNumber,
    this.downloadNumber,
    this.downloadLastDay,
  });

  FileUploadSetting.fromJson(Map<String, dynamic> json) {
    size = json['size'];
    uploadNumber = json['upload_number'];
    downloadNumber = json['download_number'];
    downloadLastDay = json['download_last_day'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['size'] = size;
    data['upload_number'] = uploadNumber;
    data['download_number'] = downloadNumber;
    data['download_last_day'] = downloadLastDay;
    return data;
  }
}
