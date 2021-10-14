library upnp_port_forward;

import 'dart:io';

final mSearch = '''M-SEARCH * HTTP/1.1
HOST:239.255.255.250:1900
MAN:'ssdp:discover'
MX:3
ST:urn:schemas-upnp-org:device:InternetGatewayDevice:1'''
    .replaceAll('\n', '\r\n')
    .codeUnits;

class UpnpPortForward {
  bool loop = true;
  bool done = false;

  Future<void> map(int port) async {
    final udp = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

    udp.listen((RawSocketEvent e) {
      final d = udp.receive();
      if (d == null) return;

      String message = String.fromCharCodes(d.data);
      print('Datagram from ${d.address.address}:${d.port}: ${message.trim()}');

      //udp.send(message.codeUnits, d.address, d.port);
    });

    while (loop) {
      print("$done $port");
      udp.send(mSearch, InternetAddress('239.255.255.250'), 1900);
      await Future.delayed(Duration(seconds: 20));
    }
  }
}
