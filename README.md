<!-- 本文件由 ./readme.make.md 自动生成，请不要直接修改此文件 -->

# upnp_port_forward

UPNP Port Forward

## use

```dart
import 'package:upnp_port_forward/upnp_port_forward.dart';

void main() async {
  final upnp = UpnpPortForwardDaemon((mapped) {
    print("$mapped map");
  });

  final port = 22222;
  upnp.map(port);
  print("map port $port");
}

```
