import "dart:convert";

import "package:relic/relic.dart";

class HotTakesWebSocketHub {
  final _clients = <RelicWebSocket>{};

  int get activeVisitors => _clients.length;

  void add(RelicWebSocket socket) {
    _clients.add(socket);
  }

  void remove(RelicWebSocket socket) {
    _clients.remove(socket);
  }

  void broadcastSwap({
    required String target,
    required String content,
    String swap = "outerHTML",
  }) {
    for (final client in List<RelicWebSocket>.from(_clients)) {
      sendSwap(client, target: target, content: content, swap: swap);
    }
  }

  void sendSwap(
    RelicWebSocket socket, {
    required String target,
    required String content,
    String swap = "outerHTML",
  }) {
    try {
      socket.sendText(
        jsonEncode({
          "target": target,
          "swap": swap,
          "content": content,
        }),
      );
    } catch (_) {
      remove(socket);
    }
  }

  Future<void> close() async {
    for (final client in List<RelicWebSocket>.from(_clients)) {
      await client.close(1001, "Server shutting down");
    }
    _clients.clear();
  }
}
