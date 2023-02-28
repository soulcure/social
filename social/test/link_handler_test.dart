import 'package:flutter_test/flutter_test.dart';
import 'package:im/pages/tool/url_handler/invite_link_handler.dart';
import 'package:im/pages/tool/url_handler/mini_program_link_handler.dart';

void main() {
  test("test invite link", () {
    const h = InviteLinkHandler();
    expect(h.match("https://fanbook.mobi/web"), false);
    expect(h.match("https://fanbook.mobi/hg6+DCFST2"), false);
    expect(h.match("https://fanbook.mobi/hg6DCFT2/a"), false);

    expect(h.match("https://fanbook.mobi/hg6DCFT2?env=newtest"), true);
    expect(h.match("https://fanbook.mobi/hg6DCFT2"), true);
  });

  test("test mini program link", () {
    final h = MiniProgramLinkHandler();
    expect(
        h.matchQueryRule(
            Uri.parse("https://www.baidu.com/?fb_redirect&open_type=mp")),
        true);
    expect(
        h.matchQueryRule(Uri.parse("https://www.baidu.com/mp/ididid")), false);

    expect(h.matchPathRule(Uri.parse("https://fanbook.mobi/mp/ididid")), true);
    expect(h.matchPathRule(Uri.parse("https://fanbook.mobi/mp/ididid/idid")),
        true);
    expect(h.matchPathRule(Uri.parse("https://open.fanbook.mobi/mp/ididid")),
        true);
    expect(
        h.matchPathRule(Uri.parse("https://open.fanbook.mobi/mp/ididid/idid")),
        true);

    expect(
        h.getUrl(Uri.parse("https://www.baidu.com/?fb_redirect&open_type=mp")),
        "https://www.baidu.com/?fb_redirect&open_type=mp");
    expect(h.getUrl(Uri.parse("https://www.baidu.com/mp/ididid")),
        "https://www.baidu.com/mp/ididid");

    expect(
        h.getUrl(Uri.parse(
            "http://fanbook.mobi/mp/aHR0cHM6Ly9iYnMtc2FyLmlkcmVhbXNreS5jb20vcGx1Z2luLnBocD9pZD1obF9jcmVkaXRtYWxsJm1vYmlsZT0y")),
        "https://bbs-sar.idreamsky.com/plugin.php?id=hl_creditmall&mobile=2");
    expect(
        h.getUrl(Uri.parse(
            "https://open.fanbook.mobi/mp/195452636021915648/237779111534133248/manage")),
        "https://open.fanbook.mobi/mp/195452636021915648/237779111534133248/manage");
  });
}
