<!-- 本文件由 ./readme.make.md 自动生成，请不要直接修改此文件 -->

# upnp_port_forward

UPNP Port Forward

## use

```dart
import 'package:upnp_port_forward/upnp_port_forward.dart';

void main() async {
  final upnp = UpnpPortForward((mapped) {
    print("$mapped map");
  });

  upnp.map(11111);
  upnp.map(22222);
}

```
