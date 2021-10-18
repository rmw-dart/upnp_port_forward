library upnp_port_forward;

// 参考资料: [UPNP自动端口映射的实现](https://blog.csdn.net/zfrong/article/details/3305738)

import 'soap.dart' show Soap, Protocol, findSoap;
import 'dart:async';
import 'package:await_sleep/init.dart';
import 'package:try_catch/init.dart';
import 'package:intranet_ip/intranet_ip.dart';

class UpnpPortForwardDaemon {
  Soap? soap;
  String? ip;
  int duration = 120;
  List<Map<int, bool>> map = [{}, {}];
  late final Function(Protocol, int, bool) callback;

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

  void upnpFalse() {
    map.asMap().forEach((protocol, li) {
      for (var i in li.entries) {
        if (i.value) {
          final port = i.key;
          if (li[port] ?? true) {
            li[port] = false;
            callback(Protocol.values[protocol], port, false);
          }
        }
      }
    });
  }

  Future<void> _map() async {
    final _ip = (await tryCatch(() => intranetIpv4()))?.address;
    if (_ip != ip) {
      ip = _ip;
      this.soap = null;
      upnpFalse();
    }

    final soapIsNull = this.soap == null;
    this.soap ??= await findSoap();
    if (this.soap == null) {
      if (!soapIsNull) {
        upnpFalse();
      }
      return;
    }

    final soap = this.soap!;
    // /*
    for (var i in await soap.ls()) {
      final protocol = i[4];
      final externalPort = i[0];
      print("> ${i[3]} $protocol $ip $externalPort");
//          await soap.rm(protocol, externalPort);
    }
    //  */

    if (ip != null) {
      for (var i in Protocol.values) {
        final protocol = i.index;
        final protocolMap = map[protocol];
        late final bool state;
        for (var portState in protocolMap.entries) {
          if (await soap.add(i, ip!, portState.key, duration: duration + 60)) {
            state = true;
          } else {
            state = false;
          }
          if (portState.value != state) {
            protocolMap[portState.key] = state;
            callback(i, portState.key, state);
          }
        }
      }
    }
  }

  Future<void> run() async {
    while (true) {
      await tryCatch(() => _map());
      await sleep(duration);
    }
  }
}
