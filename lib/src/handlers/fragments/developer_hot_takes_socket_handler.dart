import "dart:async";
import "dart:convert";

import "package:absurd_starter/src/handlers/shared/developer_hot_takes_state.dart";
import "package:absurd_starter/src/ui/pages/developer_hot_takes_page.dart";
import "package:htmleez/htmleez.dart";
import "package:relic/relic.dart";
import "package:web_socket/web_socket.dart";

final _hotTakesMutations = HotTakesMutationQueue();

Result handleDeveloperHotTakesSocket(Request request) {
  final (:sessionId, isNew: _) = visitorSession(request);
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

Future<void> _handleHotTakesSocketMessage(
  RelicWebSocket socket,
  String message,
) async {
  final payload = jsonDecode(message);
  if (payload is! Map<String, dynamic>) return;

  switch (payload["action"]) {
    case "create":
      await _handleCreateHotTakeSocket(socket, payload);
    case "vote":
      await _handleVoteHotTakeSocket(payload);
  }
}

Future<void> _handleCreateHotTakeSocket(
  RelicWebSocket socket,
  Map<String, dynamic> payload,
) async {
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

  await _hotTakesMutations.run(() {
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
  await _hotTakesMutations.run(() {
    final take = hotTakesStore.vote(id, delta: delta);
    if (take == null) return;
    _broadcastHotTakesState();
  });
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
  final snapshot = hotTakesStore.snapshot(
    activeVisitors: hotTakesHub.activeVisitors,
  );
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
