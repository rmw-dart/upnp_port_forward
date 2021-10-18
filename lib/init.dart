library upnp_port_forward;

// 参考资料: [UPNP自动端口映射的实现](https://blog.csdn.net/zfrong/article/details/3305738)

import 'soap.dart';
import 'dart:async';
import 'package:await_sleep/init.dart';
import 'package:try_catch/init.dart';
import 'package:intranet_ip/intranet_ip.dart';

class UpnpPortForwardDaemon {
  Soap? soap;
  String? ip;
  List<Map<int, bool>> map = [{}, {}];
  late final Function(int, int, bool) callback;

  UpnpPortForwardDaemon(this.callback);

  void _add(Protocol protocol, int port) {
    final m = map[protocol.index];
    if (!m.containsKey(port)) {
      m[port] = false;
    }
  }

  void udp(int port) {
    _add(Protocol.udp, port);
  }

  void tcp(int port) {
    _add(Protocol.tcp, port);
  }

  Future<void> _map() async {
    final _ip = (await tryCatch(() => intranetIpv4()))?.address;
    if (_ip != ip) {
      ip = _ip;
      this.soap = null;
      map.asMap().forEach((protocol, li) {
        for (var i in li.entries) {
          if (i.value) {
            final port = i.key;
            li[port] = false;
            callback(protocol, port, false);
          }
        }
      });
    }
    if (ip == null) {
      return;
    }
    print(map);
    final soap = this.soap ??= await findSoap();
    print(soap.url);
    print(soap.serviceType);
    print(await soap.mapped());
  }

  Future<void> run() async {
    while (true) {
      await tryCatch(() => _map());
      await sleep(60);
    }
  }
}
