library upnp_port_forward;

// 参考资料: [UPNP自动端口映射的实现](https://blog.csdn.net/zfrong/article/details/3305738)

import 'dart:async';
import 'dart:io';
import 'package:await_sleep/init.dart';
import 'package:http/http.dart' as http;
import 'package:intranet_ip/intranet_ip.dart';
import 'package:try_catch/async.dart';
import 'package:xml/xml.dart';

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

Future<void> upnpMap(RawDatagramSocket udp, int port) async {
  final ip = await intranetIpv4();

  print("$ip $port");
}

Future<Soap?> controlUrl(String url) async {
  final uri = Uri.parse(url);
  final response = await http.get(uri).timeout(
    Duration(seconds: 6),
    onTimeout: () {
      return http.Response('Error', 500);
    },
  );
  if (response.statusCode == 200) {
    final doc = XmlDocument.parse(response.body);

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
            return Soap(urlbase + controlUrl.text, type);
          }
        }
      }
    }
  }
}

class Soap {
  final String serviceType;
  final String url;
  Soap(this.url, this.serviceType);
}

enum Protocol { tcp, udp }

class UpnpPortForwardDaemon {
  Soap? soap;
  InternetAddress? ip;
  List<Map<int, bool>> map = [{}, {}];
  late final Function(int, int, bool) callback;

  UpnpPortForwardDaemon(this.callback);

  void _add(Protocol protocol, int port) {
    final m = map[protocol.index];
    if (!m.containsKey(port)) {
      m[port] = false;
    }
  }

  void udp(int port) {
    _add(Protocol.udp, port);
  }

  void tcp(int port) {
    _add(Protocol.tcp, port);
  }

  Future<void> _map() async {
    final _ip = await tryCatch(() => intranetIpv4());
    if (_ip != ip) {
      ip = _ip;
      this.soap = null;
      map.asMap().forEach((protocol, li) {
        for (var i in li.entries) {
          if (i.value) {
            final port = i.key;
            li[port] = false;
            callback(protocol, port, false);
          }
        }
      });
    }
    if (ip == null) {
      return;
    }
    final soap = this.soap ??= await findSoap();
    print(soap.url);
    print(soap.serviceType);
  }

  Future<void> run() async {
    while (true) {
      await tryCatch(() => _map());
      await sleep(60);
    }
  }
}
