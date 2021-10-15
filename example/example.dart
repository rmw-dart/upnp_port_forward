import 'package:upnp_port_forward/upnp_port_forward.dart'
    show UpnpPortForwardDaemon;

void main() async {
  // protocol 0 = tcp 1 = udp
  final upnp = UpnpPortForwardDaemon((protocol, port, state) {
    print("port $protocol $port $state");
  });

  final port = 22222;
  upnp
    ..udp(port)
    ..run();
  print("map port $port");
}
