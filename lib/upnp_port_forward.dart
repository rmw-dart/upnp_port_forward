library upnp_port_forward;

import 'dart:io';
import 'package:await_sleep/init.dart';
import 'package:intranet_ip/intranet_ip.dart';

final mSearch = '''M-SEARCH * HTTP/1.1
HOST:239.255.255.250:1900
MAN:'ssdp:discover'
MX:3
ST:urn:schemas-upnp-org:device:InternetGatewayDevice:1'''
    .replaceAll('\n', '\r\n')
    .codeUnits;

Future<void> upnpMap(RawDatagramSocket udp, int port) async {
  final ip = await intranetIpv4();

  print("$ip $port");
  udp.send(mSearch, InternetAddress('239.255.255.250'), 1900);
}

class UpnpPortForwardDaemon {
  bool loop = true;
  bool done = false;
  int fail = 0;
  late final Function(bool) callback;

  UpnpPortForwardDaemon(this.callback);

  Future<void> map(int port) async {
    final udp = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

    udp.listen((RawSocketEvent e) {
      final d = udp.receive();
      if (d == null) return;

      String message = String.fromCharCodes(d.data);
      print('Datagram from ${d.address.address}:${d.port}: ${message.trim()}');

      ++fail;

      callback(false);
      //udp.send(message.codeUnits, d.address, d.port);
    });

    while (loop) {
      await upnpMap(udp, port);
      await sleep(60);
    }
  }
}
