import 'package:upnp_port_forward/upnp_port_forward.dart';

void main() async {
  final ip = await intranetIpv4();
  print(ip);
  print(ip.rawAddress);
}
