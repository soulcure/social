import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/api/invite_api.dart';
import 'package:im/app/routes/spectial_routes.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/config.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/tool/url_handler/invite_link_handler.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/invite_code/invite_code_util.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/button/primary_button.dart';
import 'package:im/widgets/text_field/native_input.dart';
import 'package:pedantic/pedantic.dart';
import 'package:websafe_svg/websafe_svg.dart';

class JoinGuildPage extends StatefulWidget {
  @override
  _JoinGuildPageState createState() => _JoinGuildPageState();
}

class _JoinGuildPageState extends State<JoinGuildPage>
    with WidgetsBindingObserver {
  bool _confirmEnable = false;
  bool _loading = false;
  TextEditingController _linkController;
  TextSelectionControls _selectionControls;
  final _focusNode = FocusNode();

  /// 邀请码长度
  final inviteCodeLength = 8;

  @override
  void initState() {
    _linkController = TextEditingController(text: "");
    _selectionControls = _InviteCodeSelectionController();
    _checkClipboard();
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      /// 每当app回到前台则检测粘贴板中是否包含邀请码
      _checkClipboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final inputDivider = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Divider(
        color: const Color(0xFF8F959E).withOpacity(0.2),
      ),
    );
    return Stack(
      children: [
        Container(
          color: appThemeData.backgroundColor,
          alignment: Alignment.topCenter,
          child: WebsafeSvg.asset(
            'assets/svg/login_page_bg.svg',
            fit: BoxFit.fitWidth,
            width: Get.width,
          ),
        ),
        Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.transparent,
          appBar: const CustomAppbar(backgroundColor: Colors.transparent),
          body: SafeArea(
            child: Column(
              children: <Widget>[
                sizeHeight32,
                Text(
                  '输入服务器邀请码'.tr,
                  style: const TextStyle(
                    color: Color(0xFF363940),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                sizeHeight15,
                Text(
                  '服务器邀请码示例：SVgd7FZ3 或\nhttps://fanbook.mobi/SVgd7FZ3'.tr,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(color: Color(0xFF363940), fontSize: 17),
                ),
                const SizedBox(height: 28),
                inputDivider,
                const SizedBox(height: 4),
                _buildInput(),
                inputDivider,
                const SizedBox(height: 28),
                PrimaryButton(
                  width: 184,
                  height: 40,
                  loading: _loading,
                  textStyle: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.5),
                    height: 1.25,
                  ),
                  borderRadius: 6,
                  enabled: _confirmEnable,
                  onPressed: () => _joinGuild(context),
                  label: '加入服务器'.tr,
                ),
                sizeHeight16,
                FadeButton(
                  width: 184,
                  height: 40,
                  onTap: () => _scannerCodeJoin(context),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: const Color(0xFFF5F5F8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(IconFont.buffScanQr,
                          color: Color(0xFF363940), size: 16),
                      sizeWidth10,
                      Text(
                        "扫码加入".tr,
                        style: const TextStyle(
                          color: Color(0xFF363940),
                          fontSize: 16,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 扫码加入
  void _scannerCodeJoin(BuildContext context) {
    // 解决输入键盘没有pop
    FocusScope.of(context).unfocus();
    SpectialRoutes.openQrScanner();
  }

  /// 邀请码输入框
  Widget _buildInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: NativeInput(
        controller: _linkController,
        selectionControls: _selectionControls,
        focusNode: _focusNode,
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          border: InputBorder.none,
        ),
        style: const TextStyle(
          color: Color(0xFF363940),
          fontSize: 28,
          fontWeight: FontWeight.w500,
        ),
        autofocus: true,
        buildCounter: (
          context, {
          currentLength,
          maxLength,
          isFocused,
        }) {
          return const SizedBox();
        },
        // maxLength: inviteCodeLength,
        onEditingComplete: () {
          if (UniversalPlatform.isIOS) _focusNode.unfocus();
        },
        onChanged: _onInputChange,
      ),
    );
  }

  void toggleLoading(bool loading) {
    if (mounted) {
      setState(() {
        _loading = loading;
      });
    }
  }

  void _onInputChange(String text) {
    _confirmEnable = text.hasValue && text.trim().isNotEmpty;
    setState(() {});
  }

  Future _joinGuild(context) async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    try {
      String code = _linkController.text.trim();

      /// NOTE: 2022/1/18 此处解决\u200b零占位字符
      if (code.contains(nullChar)) {
        code = code.replaceAll(nullChar, '');
      }

      toggleLoading(true);
      final Map inviteInfo =
          await InviteApi.getCodeInfo(code, showDefaultErrorToast: true);

      toggleLoading(false);

      await InviteLinkHandler(inviteInfo: inviteInfo).handleWithCode(code);
    } catch (e) {
      print(e);
      toggleLoading(false);
    }
  }

  /// 检测粘贴板中是否有邀请码
  Future _checkClipboard() async {
    final code = await _parseCode();
    if (code != null && !_linkController.text.hasValue) {
      /// 若检测到粘贴板中的邀请码，当输入框没有输入时才自动填充邀请码
      unawaited(Future.delayed(const Duration(milliseconds: 300)).then((value) {
        _linkController.text = code;
        _linkController.selection = _linkController.selection.copyWith(
          baseOffset: code.length,
          extentOffset: code.length,
        );
      }));
      setState(() {
        _confirmEnable = true;
      });
      unawaited(Clipboard.setData(const ClipboardData(text: '')));
    }
  }
}

Future<String> _getClipboardText() async {
  final data = await Clipboard.getData(Clipboard.kTextPlain);
  return (data?.text ?? '').pureValue;
}

/// 从粘贴板中解析邀请码，如果没有邀请码则返回null
Future<String> _parseCode({String text}) async {
  text ??= await _getClipboardText();

  /// 传入的文本为空
  if (!text.hasValue) return null;

  if (Config.inviteCodePattern.hasMatch(text)) {
    /// 传入的文本就是邀请码
    return text;
  }

  /// 从文本中解析出邀请链接
  final linkStr = filterLinkFromText(text);

  /// 未包含邀请链接
  if (linkStr == null) return null;

  try {
    InviteCodeUtil.setInviteCode(text);

    /// 从邀请链接中解析出邀请码
    return Uri.parse(linkStr).pathSegments.last;
  } catch (e, s) {
    print("parse code failed, $e\n$s");
  }
  return null;
}

/// 处理邀请码输入框的事件
class _InviteCodeSelectionController extends MaterialTextSelectionControls {
  /// 处理输入框粘贴事件
  @override
  Future<void> handlePaste(TextSelectionDelegate delegate) async {
    // 将要被粘贴的文本
    String text = await _getClipboardText();
    // 尝试解析邀请码
    final code = await _parseCode(text: text);
    if (code != null) {
      // 解析到邀请码
      text = code;
    }
    final offset = text?.length ?? 0;
    // 粘贴后光标的位置在文字末尾
    final selection = TextSelection(
      baseOffset: offset,
      extentOffset: offset,
    );
    // 重置要粘贴的文字，如果未解析出邀请码，原样粘贴，否则粘贴解析出的邀请码
    final textEditingValue = delegate.textEditingValue.copyWith(text: text);
    // 重置光标位置
    // ignore: deprecated_member_use
    delegate.textEditingValue = textEditingValue.copyWith(selection: selection);
    return;
  }
}
