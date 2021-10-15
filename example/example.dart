import 'package:upnp_port_forward/upnp_port_forward.dart';

void main() async {
  final upnp = UpnpPortForwardDaemon((mapped) {
    print("$mapped map");
  });

  final port = 22222;
  upnp.map(port);
  print("map port $port");
}
