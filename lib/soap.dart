import 'package:xml/xml.dart';
import 'package:req/init.dart';
import 'dart:io';
import 'package:await_sleep/init.dart';
import 'dart:async';

// https://attacker.cc/index.php/archives/116/

final req = Req(timeout: 6);

final mSearch = '''M-SEARCH * HTTP/1.1
HOST:239.255.255.250:1900
MAN:'ssdp:discover'
MX:3
ST:urn:schemas-upnp-org:device:InternetGatewayDevice:1'''
    .replaceAll('\n', '\r\n')
    .codeUnits;

Future<Soap?> findSoap() async {
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

  var n = 3;
  do {
    udp.send(mSearch, InternetAddress('239.255.255.250'), 1900);
    await sleep(1);
    if (url != null) {
      break;
    }
  } while (n-- > 0 && url == null);

  udp.close();
  return url;
}

Future<Soap?> controlUrl(String url) async {
  final uri = Uri.parse(url);
  final response = await req.getUri(uri);
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

  FutureOr<HttpClientResponse> get(String action, String body) async {
    final xml =
        """<?xml version="1.0"?>\n<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:$action xmlns:u="$serviceType">$body</u:$action></s:Body></s:Envelope>""";
    final r = await req.postUri(url,
        headers: {
          "Content-Type": "text/xml",
          "SOAPAction": "$serviceType#$action"
        },
        body: xml);
    return r;
  }

  FutureOr<HttpClientResponse> rm(Protocol protocol, int externalPort) {
    return get('DeletePortMapping',
        """<NewRemoteHost></NewRemoteHost><NewExternalPort>$externalPort</NewExternalPort><NewProtocol>${protocol.name}</NewProtocol>""");
  }

  Future<bool> add(Protocol protocol, String ip, int port,
      {bool autoRm = true,
      int duration = 0,
      int? externalPort,
      String description = ''}) async {
    externalPort ??= port;
    final r = await get('AddPortMapping',
        """<NewRemoteHost></NewRemoteHost><NewExternalPort>$externalPort</NewExternalPort><NewProtocol>${protocol.name}</NewProtocol><NewInternalPort>$port</NewInternalPort><NewInternalClient>$ip</NewInternalClient><NewEnabled>1</NewEnabled><NewPortMappingDescription>$description</NewPortMappingDescription><NewLeaseDuration>$duration</NewLeaseDuration>""");

    final statusCode = r.statusCode;
    if (statusCode == 200) {
      return true;
    } else {
      final xml = XmlDocument.parse(await r.text());
      if (xml.findAllElements('errorCode').first.text == '718'
          // ConflictInMappingEntry
          ) {
        await rm(protocol, externalPort);
        return await add(protocol, ip, port,
            autoRm: false,
            duration: duration,
            externalPort: externalPort,
            description: description);
      }
      stderr.write("❌ $statusCode : ${xml.findAllElements('s:Body').first}");
    }
    return false;
  }

  Future<List> ls() async {
    var n = 0;
    List li = [];
    while (true) {
      final r = await get('GetGenericPortMappingEntry',
          "<NewPortMappingIndex>${n++}</NewPortMappingIndex>");
      final statusCode = r.statusCode;
      if (500 == statusCode || 200 == statusCode) {
        final xml = XmlDocument.parse(await r.text());
        if (200 == statusCode) {
          final meta = xml
              .getElement('s:Envelope')
              ?.getElement('s:Body')
              ?.getElement('u:GetGenericPortMappingEntryResponse');
          if (meta != null) {
            final map = [];
            for (var i in [
              "NewExternalPort",
              "NewInternalPort",
              "NewEnabled",
              "NewLeaseDuration",
            ]) {
              map.add(int.parse(meta.getElement(i)!.text));
            }
            for (var i in [
              "NewProtocol",
              "NewRemoteHost",
              "NewInternalClient",
              "NewPortMappingDescription",
            ]) {
              map.add(meta.getElement(i)?.text ?? '');
            }
            li.add(map);
          }
          continue;
        } else {
          if (xml.findAllElements('errorCode').first.text == '713') {
            break;
          }
        }
      }

      stderr.write("\n⚠️ $statusCode\n${await r.text()}\n");
    }
    return li;
  }
}

enum Protocol { tcp, udp }
