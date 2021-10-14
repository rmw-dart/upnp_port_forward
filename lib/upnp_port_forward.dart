library upnp_port_forward;


Future<InternetAddress> intranetIpv4() async {
  const len = 16;
  final token = randomUint8List(len);
  final dgSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  dgSocket.readEventsEnabled = true;
  dgSocket.broadcastEnabled = true;
  final ret = dgSocket.timeout(Duration(milliseconds: 500), onTimeout: (sink) {
    sink.close();
  }).expand<InternetAddress>((event) {
    if (event == RawSocketEvent.read) {
      final dg = dgSocket.receive();
      if (dg != null &&
          dg.data.length == len &&
          ListEquality().equals(dg.data, token)) {
        dgSocket.close();
        return [dg.address];
      }
    }
    return [];
  }).first;

  dgSocket.send(token, InternetAddress("255.255.255.255"), dgSocket.port);
  return ret;
}
