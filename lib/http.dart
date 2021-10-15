import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

Future<String> read(HttpClientResponse response, Encoding encoding) async {
  final contents = StringBuffer();
  await for (var data in response.transform(encoding.decoder)) {
    contents.write(data);
  }
  return contents.toString();
}

extension HttpClientResponseText on HttpClientResponse {
  Future<String> text({Encoding encoding = utf8}) {
    return read(this, encoding);
  }
}

class Http {
  late final HttpClient http;
  int timeout;

  Http({this.timeout = 60}) : http = HttpClient();

  Future<HttpClientResponse> _req(FutureOr<HttpClientRequest> request) async {
    final req = await request;
    try {
      return await req.close().timeout(Duration(seconds: timeout));
    } on TimeoutException catch (_) {
      req.abort();
      rethrow;
    }
  }

  Future<HttpClientResponse> get(Uri url) => _req(http.getUrl(url));
  Future<HttpClientResponse> post(Uri url,
      {Uint8List? body, Map<String, String>? headers}) async {
    final req = await http.postUrl(url);
    if (headers != null) {
      for (var i in headers.entries) {
        req.headers.set(i.key, i.value);
      }
    }
    if (body != null) {
      req.add(body);
    }
    return _req(req);
  }
}
