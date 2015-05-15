library platform.io;

import "platform.dart";

import "dart:io";
import "dart:convert";

class IOPlatformAdapter extends PlatformAdapter {
  @override
  String decodeUriComponent(String input) {
    return Uri.decodeComponent(input);
  }

  @override
  String encodeJSON(input) {
    return JSON.encode(input);
  }

  @override
  String encodeUriComponent(String input) {
    return Uri.encodeComponent(input);
  }

  @override
  void fetchBytes(String method, String url, void handler(int statusCode, List<int> content, Map<String, String> headers), {List<int> body, Map<String, String> headers}) {
    var client = new HttpClient();
    client.getUrl(Uri.parse(url)).then((HttpClientRequest request) {
      if (headers != null) {
        for (var c in headers.keys) {
          request.headers.set(c, headers[c]);
        }
      }

      if (body != null) {
        request.add(body);
      }
      return request.close();
    }).then((HttpClientResponse response) {
      response.reduce((a, b) => []..addAll(a)..addAll(b)).then((data) {
        var map = {};
        response.headers.forEach((x, y) => map[x] = y.first);
        client.close();
        handler(response.statusCode, data, map);
      });
    });
  }

  @override
  void fetchString(String method, String url, void handler(int statusCode, String content, Map<String, String> headers), {String body, Map<String, String> headers}) {
    var client = new HttpClient();
    client.getUrl(Uri.parse(url)).then((HttpClientRequest request) {
      if (headers != null) {
        for (var c in headers.keys) {
          request.headers.set(c, headers[c]);
        }
      }

      if (body != null) {
        request.write(body);
      }
      return request.close();
    }).then((HttpClientResponse response) {
      response.reduce((a, b) => []..addAll(a)..addAll(b)).then((data) {
        var map = {};
        response.headers.forEach((x, y) => map[x] = y.first);
        client.close();
        handler(response.statusCode, UTF8.decode(data), map);
      });
    });
  }

  @override
  parseJSON(String input) {
    return JSON.decode(input);
  }
}
