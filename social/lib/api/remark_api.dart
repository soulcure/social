import 'package:dio/dio.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:pedantic/pedantic.dart';

import 'entity/remark_bean.dart';

class RemarkApi {
  static Future postRemarkUser(String userId, String friendId, String name,
      {CancelToken token, String description = ''}) async {
    try {
      final res = await Http.request(remarkUserUrl,
          data: {
            'user_id': userId,
            'friend_user_id': friendId,
            'name': name,
            'description': description
          },
          cancelToken: token,
          showDefaultErrorToast: true);
      final bean = Global.user.remarkListBean ?? Db.remarkListBox.get(userId);

      if (name.isEmpty) {
        //删除备注
        bean.remarks.remove(friendId);
        unawaited(Db.remarkBox.delete(friendId));
      } else {
        //添加备注
        bean.remarks[friendId] = RemarkBean(friendId, name, '');
        unawaited(Db.remarkBox.put(friendId, bean.remarks[friendId]));
      }

      Global.user.remarkListBean = bean;
      unawaited(Db.remarkListBox.put(userId, bean));

      return res;
    } catch (e) {
      return null;
    }
  }

  static Future<RemarkListBean> getRemarkList(String userId,
      {CancelToken token}) async {
    final localBean = Db.remarkListBox.get(userId);
    try {
      ///不传分页参数，获取所有的备注名
      final res = await Http.request(remarkListUrl,
          data: {'user_id': userId}, cancelToken: token);

      ///先清理remarkBox，在fromJson中再保存
      await Db.remarkBox.clear();
      final resultBean = RemarkListBean.fromJson(res);
      unawaited(Db.remarkListBox.put(userId, resultBean));
      Global.user.remarkListBean = resultBean;
      return resultBean;
    } catch (e) {
      Global.user.remarkListBean = localBean;
      return null;
    }
  }
}

const String remarkUserUrl = '/api/user/remark';
const String remarkListUrl = '/api/user/remarkList';
