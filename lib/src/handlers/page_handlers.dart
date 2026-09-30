import "dart:async";
import "dart:convert";
import "dart:io";
import "dart:math";

import "package:absurd_starter/src/hot_takes/hot_takes_store.dart";
import "package:absurd_starter/src/hot_takes/hot_takes_websocket_hub.dart";
import "package:absurd_starter/src/ui/pages/developer_hot_takes_page.dart";
import "package:absurd_starter/src/ui/pages/home_page.dart";
import "package:absurd_starter/src/ui/pages/ui_page.dart";
import "package:absurd_starter/src/ui/pages/user_example_page.dart";
import "package:absurd_starter/src/utils/htmx.dart";
import "package:htmleez/htmleez.dart";
import "package:relic/relic.dart";
import "package:web_socket/web_socket.dart";

const _visitorCookie = "hot_takes_visitor";

final hotTakesStore = HotTakesStore();
final hotTakesHub = HotTakesWebSocketHub();
final hotTakesMutations = HotTakesMutationQueue();

Response handleHomePage(Request request) => htmlPage(pageHome());

Response handleUiPage(Request request) => htmlPage(pageUi());

Response handleUserExamplePage(Request request) => htmlPage(pageUserExample());

Response handleDeveloperHotTakesPage(Request request) {
  final (:sessionId, :isNew) = _visitorSession(request);
  hotTakesStore.registerVisitor(sessionId);

  final page = pageDeveloperHotTakes(
    hotTakesStore.snapshot(activeVisitors: hotTakesHub.activeVisitors),
  );

  if (!isNew) return htmlPage(page);

  return Response(
    HttpStatus.ok,
    body: Body.fromString(page.toHtml(), encoding: utf8, mimeType: MimeType.html),
    headers: Headers.build((h) {
      h.setCookie = SetCookieHeader([
        SetCookie(
          name: _visitorCookie,
          value: sessionId,
          path: "/",
          httpOnly: true,
          sameSite: SameSite.lax,
          maxAge: 60 * 60 * 24 * 365,
        ),
      ]);
    }),
  );
}

Result handleDeveloperHotTakesSocket(Request request) {
  final (:sessionId, isNew: _) = _visitorSession(request);
  hotTakesStore.registerVisitor(sessionId);

  return WebSocketUpgrade((socket) async {
    hotTakesHub.add(socket);
    _broadcastVisitorStats();

    try {
      await for (final event in socket.events) {
        switch (event) {
          case TextDataReceived(text: final message):
            await _handleHotTakesSocketMessage(socket, message);
          case CloseReceived():
            return;
          default:
            break;
        }
      }
    } finally {
      hotTakesHub.remove(socket);
      _broadcastVisitorStats();
    }
  });
}

Future<void> _handleHotTakesSocketMessage(RelicWebSocket socket, String message) async {
  final payload = jsonDecode(message);
  if (payload is! Map<String, dynamic>) return;

  switch (payload["action"]) {
    case "create":
      await _handleCreateHotTakeSocket(socket, payload);
    case "vote":
      await _handleVoteHotTakeSocket(payload);
  }
}

Future<void> _handleCreateHotTakeSocket(RelicWebSocket socket, Map<String, dynamic> payload) async {
  final rawTake = (payload["take"] ?? "").toString();
  final text = _normalizeTake(rawTake);
  final error = _validateTake(text);

  if (error != null) {
    hotTakesHub.sendSwap(
      socket,
      target: "#new-take-dialog-content",
      content: takeDialogContent(value: rawTake, error: error).toHtml(),
    );
    return;
  }

  await hotTakesMutations.run(() {
    hotTakesStore.addTake(text);
    _broadcastHotTakesState();
  });

  hotTakesHub.sendSwap(
    socket,
    target: "#new-take-dialog",
    content: newTakeDialog().toHtml(),
  );
}

Future<void> _handleVoteHotTakeSocket(Map<String, dynamic> payload) async {
  final rawId = payload["take_id"]?.toString();
  final id = int.tryParse(rawId ?? "");
  if (id == null) return;

  final delta = _voteDelta(payload["delta"]?.toString());
  await hotTakesMutations.run(() {
    final take = hotTakesStore.vote(id, delta: delta);
    if (take == null) return;
    _broadcastHotTakesState();
  });
}

Future<Response> handleDeleteUserExample(Request request) async {
  await Future<void>.delayed(const Duration(seconds: 1));

  return htmlFragments([
    deletedUserFragment(),
  ]);
}

Future<Response> handleRestoreUserExample(Request request) async {
  await Future<void>.delayed(const Duration(seconds: 1));

  return htmlFragments([
    userCardFragment(),
  ]);
}

Response handleHealth(Request request) => Response.ok(body: Body.fromString("ok"));

Future<Response> handleCounterIncrement(Request request) async {
  final form = await request.urlEncodedForm();
  final rawCount = form.fields(const StringFormField("count")) ?? "0";
  final count = int.tryParse(rawCount) ?? 0;

  await Future<void>.delayed(const Duration(seconds: 3));

  return htmlFragments([
    counterFragment(count + 1),
  ]);
}

void _broadcastVisitorStats() {
  hotTakesHub.broadcastSwap(
    target: "#hot-takes-stats",
    content: statsPanelFragment(
      hotTakesStore.stats(activeVisitors: hotTakesHub.activeVisitors),
    ).toHtml(),
  );
}

void _broadcastHotTakesState() {
  final snapshot = hotTakesStore.snapshot(activeVisitors: hotTakesHub.activeVisitors);
  hotTakesHub
    ..broadcastSwap(
      target: "#takes",
      content: takesListFragment(snapshot.takes).toHtml(),
    )
    ..broadcastSwap(
      target: "#hot-takes-stats",
      content: statsPanelFragment(snapshot.stats).toHtml(),
    );
}

({String sessionId, bool isNew}) _visitorSession(Request request) {
  final existing = request.headers.cookie?.getCookie(_visitorCookie)?.value;
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

String _normalizeTake(String input) => input.trim().replaceAll(RegExp(r"\s+"), " ");

String? _validateTake(String take) {
  if (take.isEmpty) return "Write the take before posting.";
  if (take.length < 8) return "Make the take at least 8 characters.";
  if (take.length > 180) return "Keep the take under 180 characters.";
  return null;
}

int _voteDelta(String? raw) {
  return raw == "-1" ? -1 : 1;
}

class HotTakesMutationQueue {
  Future<void> _tail = Future.value();

  Future<T> run<T>(FutureOr<T> Function() mutation) {
    final completer = Completer<T>();

    _tail = _tail.catchError((_) {}).then((_) async {
      try {
        completer.complete(await mutation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });

    return completer.future;
  }
}
