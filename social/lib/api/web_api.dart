import 'dart:convert';

//import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:im/core/config.dart';
import 'package:im/core/http_middleware/http.dart';

enum RequestMethod {
  get,
  post,
}

class WebApi {
  static Future relocationUrl(String url,
      {RequestMethod method = RequestMethod.get,
      String format = 'json',
      Map param,
      Map header}) async {
    final data = {
      'url': url,
      'method': method == RequestMethod.get ? 'get' : 'post',
      'format': format,
    };
    if (param != null) {
      data['body'] = param != null ? jsonEncode(param) : '';
    }
    if (header != null) {
      data['header'] = header != null ? jsonEncode(header) : '';
    }

    final Map<String, String> _header = {};
    Http.getHeader(data: data).forEach((key, value) {
      _header[key] = '$value';
    });
    final response = await http.post(
        Uri.parse('${Config.host}/api/thirdPart/linkData'),
        headers: _header,
        body: data);
    try {
      if (format == 'json')
        return jsonDecode(response.body);
      else
        return response.body;
    } catch (e) {
      return null;
    }
  }
}
