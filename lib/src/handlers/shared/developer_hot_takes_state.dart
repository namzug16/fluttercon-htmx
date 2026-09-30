import "dart:math";

import "package:absurd_starter/src/hot_takes/hot_takes_store.dart";
import "package:absurd_starter/src/hot_takes/hot_takes_websocket_hub.dart";
import "package:relic/relic.dart";

const visitorCookie = "hot_takes_visitor";

final hotTakesStore = HotTakesStore();
final hotTakesHub = HotTakesWebSocketHub();

({String sessionId, bool isNew}) visitorSession(Request request) {
  final existing = request.headers.cookie?.getCookie(visitorCookie)?.value;
  if (existing != null && RegExp(r"^[a-f0-9]{32}$").hasMatch(existing)) {
    return (sessionId: existing, isNew: false);
  }

  return (sessionId: _randomHex(16), isNew: true);
}

String _randomHex(int bytes) {
  final random = Random.secure();
  final buffer = StringBuffer();
  for (var i = 0; i < bytes; i++) {
    buffer.write(random.nextInt(256).toRadixString(16).padLeft(2, "0"));
  }
  return buffer.toString();
}
