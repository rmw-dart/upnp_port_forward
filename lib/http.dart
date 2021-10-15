import 'dart:io';
import 'dart:convert';
import 'dart:async';

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

  Future<HttpClientResponse> get(Uri url) async {
    final req = await http.getUrl(url);
    try {
      return await req.close().timeout(Duration(seconds: timeout));
    } on TimeoutException catch (_) {
      req.abort();
      rethrow;
    }
  }
}
