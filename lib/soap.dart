import 'package:xml/xml.dart';
import 'http.dart';
import 'dart:io';
import 'package:await_sleep/init.dart';
import 'dart:async';
import 'dart:typed_data';

final http = Http(timeout: 6);

final mSearch = '''M-SEARCH * HTTP/1.1
HOST:239.255.255.250:1900
MAN:'ssdp:discover'
MX:3
ST:urn:schemas-upnp-org:device:InternetGatewayDevice:1'''
    .replaceAll('\n', '\r\n')
    .codeUnits;

Future<Soap> findSoap() async {
  final udp = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  Soap? url;
  udp.listen((RawSocketEvent e) async {
    final d = udp.receive();
    if (d == null) return;

    final msg =
        String.fromCharCodes(d.data).replaceAll('\r\n', '\n').split('\n');

    if (msg.isNotEmpty) {
      final pos = msg.indexWhere((i) => i.contains('200 OK'));
      if (pos >= 0) {
        for (var i in msg.sublist(pos)) {
          i = i.trim();
          const location = 'LOCATION';
          if (i.startsWith(location)) {
            final pos = i.indexOf(':', location.length);
            if (pos > 0) {
              url = await controlUrl(i.substring(pos + 1).trim());
              break;
            }
          }
        }
      }
    }
    //callback(false);
    //udp.send(message.codeUnits, d.address, d.port);
  });

  while (true) {
    print('try find udp router');
    udp.send(mSearch, InternetAddress('239.255.255.250'), 1900);
    await sleep(1);
    if (url != null) {
      break;
    }
    await sleep(59);
  }

  udp.close();
  return url!;
}

Future<Soap?> controlUrl(String url) async {
  final uri = Uri.parse(url);
  final response = await http.get(uri);
  if (response.statusCode == 200) {
    final doc = XmlDocument.parse(await response.text());

    for (var service in doc.findAllElements('service')) {
      final serviceType = service.getElement('serviceType');
      if (serviceType != null) {
        final type = serviceType.text;
        if ([
          "urn:schemas-upnp-org:service:WANIPConnection:1",
          "urn:schemas-upnp-org:service:WANPPPConnection:1"
        ].contains(type)) {
          final controlUrl = service.getElement('controlURL');
          if (controlUrl != null) {
            final _urlbase = doc.getElement('URLBase');
            final urlbase = _urlbase != null ? _urlbase.text : uri.origin;
            return Soap(Uri.parse(urlbase + controlUrl.text), type);
          }
        }
      }
    }
  }
}

class Soap {
  final String serviceType;
  final Uri url;
  Soap(this.url, this.serviceType);
  FutureOr<String?> get(String action, String body) async {
    final xml =
        """<?xml version="1.0"?>\n<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:$action xmlns:u="$serviceType">$body</u:$action></s:Body></s:Envelope>""";
    final r = await http.post(url,
        headers: {
          "Content-Type": "text/xml",
          "SOAPAction": "$serviceType#$action"
        },
        body: xml);
    return await r.text();
  }

  Future<void> mapped() async {
    var n = 0;
    print(await get('GetGenericPortMappingEntry',
        "<NewPortMappingIndex>${n++}</NewPortMappingIndex>"));
  }
}

enum Protocol { tcp, udp }
