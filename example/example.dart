import 'package:upnp_port_forward/upnp_port_forward.dart';

void main() async {
  final upnp = UpnpPortForwardDaemon((port, state) {
    print("port $port $state");
  });

  final port = 22222;
  upnp.bind(port);
  print("map port $port");
}
