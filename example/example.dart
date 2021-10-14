import 'package:upnp_port_forward/upnp_port_forward.dart';

void main() async {
  final upnp = UpnpPortForward();

  upnp.map(11111);
  upnp.map(22222);
}
