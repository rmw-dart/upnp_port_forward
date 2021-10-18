import 'package:upnp_port_forward/init.dart' show UpnpPortForwardDaemon;
import 'dart:io';

void main() async {
  //final udp = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  //final port = udp.port;

  // protocol 0 = tcp 1 = udp
  final upnp = UpnpPortForwardDaemon((protocol, port, state) {
    print("upnp port map $protocol $port $state");
  });

  final port = 35515;
  upnp
    ..udp(port)
    ..run();
  print("map port $port");
}
/*
try {
  await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
} on SocketException catch (e) {
  print(e.osError);
  print(e.osError?.errorCode);
}
*/
