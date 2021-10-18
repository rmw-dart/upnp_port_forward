import 'package:upnp_port_forward/init.dart' show UpnpPortForwardDaemon;
import 'dart:io';

void main() async {
  final udp = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  final port = udp.port;
  final upnp = UpnpPortForwardDaemon((protocol, port, state) {
    print("upnp port mapped : $protocol $port $state");
  });

  upnp
    ..udp(port)
    ..run();
  print("try map port $port");
}
