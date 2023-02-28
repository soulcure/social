import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/scan_qr_code/controllers/scan_qr_code_controller.dart';
import 'package:im/app/modules/scan_qr_code/views/components/scan_line.dart';
import 'package:im/app/routes/app_pages.dart';
import 'package:im/pages/home/view/check_permission.dart';
import 'package:im/pages/tool/url_handler/link_handler_preset.dart';
import 'package:im/utils/utils.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:x_picker/x_picker.dart';

class ScanQrCodeView extends StatefulWidget {
  static EventBus scannerPopEvenBus;

  @override
  _ScanQrCodeViewState createState() => _ScanQrCodeViewState();
}

class _ScanQrCodeViewState extends State<ScanQrCodeView> {
  QRViewController controller;
  Key scannerKey = GlobalKey();

  XPicker xPicker = XPicker.fromPlatform();

  /// 是否正在展示解析错误的提示
  bool isShowingErrMessage = false;

  /// 是否正在处理中
  bool isProcessing = false;

  ///添加一个在解析的变量，防止段时间类多次调用解析回调造成多次跳转
  bool isLoadingLink = false;

  ///扫描摄像头是否已被暂停
  bool isPauseCamera = false;

  StreamSubscription _popBus;

  @override
  void initState() {
    ///监听路由，如果从其他界面回到扫一扫并且摄像头关闭了，就继续打开摄像头扫描
    ScanQrCodeView.scannerPopEvenBus = EventBus();
    _popBus = ScanQrCodeView.scannerPopEvenBus.on<String>().listen((i) {
      resumeCamera();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          _buildScannerView(),
          _buildAppBar(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    return Container(
      width: window.physicalSize.width,
      height: 44 + statusBarHeight,
      color: const Color(0x99000000),
      padding: EdgeInsets.only(top: statusBarHeight),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_sharp,
              color: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              "扫一扫".tr,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 17),
            ),
          ),
          TextButton(
            onPressed: _decodeImage,
            child: Text(
              "相册".tr,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  /// 从图片解析二维码
  Future _decodeImage() async {
    /// 检测相册权限
    final hasPermission = await checkSystemPermissions(
      context: context,
      permissions: [
        if (getPlatform() == 'ios') Permission.photos else Permission.storage
      ],
      // rejectedTips: "请允许访问相册",
    );

    /// 未授权
    if (hasPermission != true) return null;

    /// 已授权
    ///
    final file = await xPicker.pickMedia(
      type: MediaType.IMAGE,
    );
    if (Platform.isAndroid) {
      ///处理安卓部分手机选择文件时会关闭摄像头的问题
      reloadCamera();
    }

    if (file == null) return;
    try {
      final qrCode = await QRScanner.decodeImage(file.path);
      unawaited(_processQRCodeContent(qrCode));
    } catch (e, s) {
      print('$e\n$s');
    }
  }

  /// 构建摄像头扫码组件
  Widget _buildScannerView() {
    return Stack(
      children: [
        QRView(
          key: scannerKey,
          onQRViewCreated: (controller) {
            this.controller = controller;
            controller.scannedDataStream.listen(_processQRCodeContent);
          },
        ),

        /// 扫描线
        const ScanLine(from: 100, to: 500),
      ],
    );
  }

  /// 处理二维码中解析出的内容
  Future _processQRCodeContent(Barcode code) async {
    final autoProcess = Get.find<ScanQrCodeController>().autoProcess;
    if (!autoProcess) {
      pauseCamera();
      Get.back(result: code.code);
      return;
    }

    if (isProcessing || code == null || isLoadingLink) return;
    isLoadingLink = true;
    isProcessing = true;
    //跳转前先暂停摄像头
    pauseCamera();
    final canProcess = await LinkHandlerPreset.common.handle(code.code) != null;
    if (!canProcess && !isShowingErrMessage) {
      /// 无法处理的二维码
      isShowingErrMessage = true;
      showToast("链接无效".tr, dismissOtherToast: true, onDismiss: () {
        isShowingErrMessage = false;
      });
      resumeCamera();
    }
    Future.delayed(const Duration(milliseconds: 300), () {
      //两次解析的最小时间间隔为0.3秒
      isLoadingLink = false;
      //如果扫描完成后，超过间隔时间依旧停留在此界面，就恢复摄像头
      if (Get.currentRoute == Routes.SCAN_QR_CODE) {
        resumeCamera();
      }
    });
    isProcessing = false;
  }

  void pauseCamera() {
    isPauseCamera = true;
    controller?.pauseCamera();
  }

  void resumeCamera() {
    if (isPauseCamera) {
      controller?.resumeCamera();
      isPauseCamera = false;
    }
  }

  //重载摄像头
  void reloadCamera() {
    controller?.dispose();
    controller = null;
    scannerKey = GlobalKey();
    setState(() {});
  }

  @override
  void dispose() {
    _popBus?.cancel();
    ScanQrCodeView.scannerPopEvenBus = null;
    super.dispose();
    controller?.dispose();
  }
}
