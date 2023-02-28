import 'package:flutter/material.dart';
import 'package:im/utils/cos_file_download.dart';
import 'package:im/utils/cos_file_upload.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:pedantic/pedantic.dart';
import 'package:x_picker/x_picker.dart';

class LinDebugPage extends StatefulWidget {
  @override
  _LinDebugPageState createState() => _LinDebugPageState();
}

class _LinDebugPageState extends State<LinDebugPage> {
  XPicker xPicker = XPicker.fromPlatform();
  CosFileUpload upload = CosFileUpload();
  List<CosPutObject> putObjectList = [];

  final download = CosFileDownload();

  @override
  void initState() {
    // TODO: implement initState
    upload.onError = (fileId, e) {
      print('错误: $fileId; $e');
    };
    upload.onFinish = (fileId, donwloadurl) {
      print('上传完成 :$fileId; $donwloadurl');
    };
    upload.onSendProgress = (fileId, progress) {
      // print("进度： $fileId --- $progress");
      // setState(() {});
    };
    upload.onStatus = (fileId, status) {
      print('状态改变： $status');
    };

    CosFileUploadQueue.instance.registCallback(onSendProgress: (fileId, p) {
      print('进度：$fileId; $p');
      setState(() {});
    }, onFinish: (fileId, u) {
      print('完成：$fileId; $u');
    }, onError: (fileId, e) {
      print('错误：$fileId; $e');
    }, onStatus: (fileId, s) {
      print('状态改变：$fileId; $s');
      setState(() {});
    });

    download.onDownProgress = (f, p) {
      print('下载 progress :$f - $p  ');
    };
    download.onFinish = (f, u) {
      print('下载 完成 :$f - $u  ');
    };
    download.onError = (f, e) {
      print('下载error :$f - $e  ');
    };

    super.initState();
  }

  Future<void> _pickMutilFile() async {
    final result = await MultiImagePicker.pickImages(
      maxImages: 19,
      defaultAsset: null,
      selectedAssets: null,
      doneButtonText: "上传",
      cupertinoOptions: const CupertinoOptions(
          takePhotoIcon: "chat",
          selectionStrokeColor: "#ff6179f2",
          selectionFillColor: "#ff6179f2"),
      materialOptions: const MaterialOptions(
          allViewTitle: "All Photos", selectCircleStrokeColor: "#ff6179f2"),
    );
    final List<String> identifers = [];
    result['identifiers']
        .forEach((element) => identifers.add(element.toString()));
    final assets = await MultiImagePicker.requestMediaData(
        selectedAssets: identifers, thumb: result['thumb']);
    for (final item in assets) {
      final obj = await CosPutObject.create(
          item.filePath,
          item.fileType.contains("mp4")
              ? CosUploadFileType.video
              : CosUploadFileType.image,
          fileId: item.filePath,
          forceAudit: true);
      setState(() {
        putObjectList.add(obj);
      });

      unawaited(_addTask(obj));
    }
  }

  Future<void> _addTask(CosPutObject obj) async {
    print('开始上传：${obj.filePath}');
    final xxx = await CosFileUploadQueue.instance.executeCompeterTask(obj);
    print('结果: 本地地址:${obj.filePath} \n 下载地址 $xxx');
  }

  Future<void> pickImageFile() async {
    final pickedFile = await xPicker.pickMedia(type: MediaType.IMAGE);
    print('sel file: ${pickedFile.path}');
    final obj = await CosPutObject.create(
        pickedFile.path, CosUploadFileType.image,
        fileId: pickedFile.path);
    putObjectList.add(obj);
    final downUrl = await upload.cosFileUpload(obj);
    print('image downUrl: $downUrl');
  }

  Future<void> _pickVideoFile() async {
    final pickedFile = await xPicker.pickMedia(type: MediaType.VIDEO);
    print('sel file: ${pickedFile.path}');
    final obj = await CosPutObject.create(
        pickedFile.path, CosUploadFileType.video,
        fileId: pickedFile.path);
    putObjectList.add(obj);
    final downUrl = await upload.cosFileUpload(obj);
    print('video downUrl: $downUrl');
  }

  Future<void> _pickVideoFileQueue() async {
    final pickedFile = await xPicker.pickMedia(type: MediaType.VIDEO);
    print('sel file: ${pickedFile.path}');

    final obj = await CosPutObject.create(
        pickedFile.path, CosUploadFileType.video,
        fileId: pickedFile.path);
    putObjectList.add(obj);
    unawaited(CosFileUploadQueue.instance.addQueue(obj));
  }

  Future<void> _cancelUploadQueue() async {
    await CosFileUploadQueue.instance.cancelAll();
    putObjectList.clear();
    setState(() {});
  }

  void _cancelFirstUpload() {
    CosFileUploadQueue.instance.cancelFirst();
  }

  Future<void> _cancelUploadObj(CosPutObject obj) async {
    await upload.abortMultippartUpload(obj);
    putObjectList.remove(obj);
    setState(() {});
  }

  CosDownObject obj;
  Future<void> _downloadTest() async {
    try {
      // const url = "https://fb-cdn-video.fanbook.mobi/fanbook/app/files/chatroom/video/l6uDJvO0812mfunreHbIwg==.mp4";
      const url =
          "https://fb-cdn-video.fanbook.mobi/fanbook/app/files/chatroom/video/1b7bEnPnhx2Gi2txehWcxQ==.mp4";
      obj = await CosDownObject.create(url);
      final res = await download.cosFileDownload(obj);
      print('下载完成: $res');
      if (res.isNotEmpty) {
        final result = await ImageGallerySaver.saveFile(res);
        print("保存到相册：$result");
      }
    } catch (e) {
      print('下载失败：$e');
    }
  }

  void _cancelDownloadTest() {
    download.cancelDownload(obj);
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> uploadItems() {
      return putObjectList.map((e) {
        return Container(
          decoration: const BoxDecoration(border: Border(bottom: BorderSide())),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                height: 80,
                child: Text(
                  e.fileId,
                  style: const TextStyle(fontSize: 9),
                ),
              ),
              Expanded(
                child: LinearProgressIndicator(
                  backgroundColor: Colors.blue,
                  value: e.sendProgress,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                ),
              ),
              SizedBox(
                width: 100,
                child: Column(
                  children: [
                    Text(
                      '${e.status}',
                      style: const TextStyle(fontSize: 10),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _cancelUploadObj(e);
                      },
                      child: const Text("取消上传"),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      }).toList();
    }

    return Scaffold(
      appBar: CustomAppbar(
        title: 'cos file upload test',
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SingleChildScrollView(
          child: Column(
        children: <Widget>[
          Row(
            children: [
              CircularProgressIndicator(
                backgroundColor: Colors.orange[100],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
              CircularProgressIndicator(
                backgroundColor: Colors.yellow[100],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.yellow),
              ),
              CircularProgressIndicator(
                backgroundColor: Colors.blue[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // ElevatedButton(
                //   onPressed: _pickImageFile,
                //   child: const Text("选择图片"),
                // ),
                ElevatedButton(
                  onPressed: _pickMutilFile,
                  child: const Text("选择文件"),
                ),
                ElevatedButton(
                  onPressed: _pickVideoFile,
                  child: const Text("选择视频"),
                ),
                ElevatedButton(
                  onPressed: _pickVideoFileQueue,
                  child: const Text("选择视频(队列)"),
                ),
              ],
            ),
          ),
          const Divider(
            color: Colors.red,
          ),
          ...uploadItems(),
          const Divider(
            color: Colors.red,
          ),
          ElevatedButton(
              onPressed: _cancelFirstUpload, child: const Text("取消第一个")),
          ElevatedButton(
              onPressed: _cancelUploadQueue, child: const Text("清空上传队列")),
          Row(
            children: [
              ElevatedButton(
                  onPressed: _downloadTest, child: const Text("文件下载")),
              ElevatedButton(
                  onPressed: _cancelDownloadTest, child: const Text("取消下载")),
            ],
          )
        ],
      )),
    );
  }
}
