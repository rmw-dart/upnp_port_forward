<!-- 本文件由 ./readme.make.md 自动生成，请不要直接修改此文件 -->

# upnp_port_forward

UPNP Port Forward

## use

```dart
import 'package:upnp_port_forward/init.dart' show UpnpPortForwardDaemon;

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

```
