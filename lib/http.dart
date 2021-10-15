import 'dart:io';
import 'dart:convert';
import 'dart:async';

Future<String> utf8Read(HttpClientResponse response) async {
  final contents = StringBuffer();
  await for (var data in response.transform(utf8.decoder)) {
    contents.write(data);
  }
  return contents.toString();
}

extension HttpClientResponseText on HttpClientResponse {
  Future<String> text() {
    return utf8Read(this);
  }
}

class Http {
  late final HttpClient http;
  int timeout;
  Http(this.timeout) : http = HttpClient();

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
