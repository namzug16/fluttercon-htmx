import "dart:convert";
import "dart:io";

import "package:absurd_starter/src/handlers/shared/developer_hot_takes_state.dart";
import "package:absurd_starter/src/ui/pages/developer_hot_takes_page.dart";
import "package:absurd_starter/src/utils/htmx.dart";
import "package:htmleez/htmleez.dart";
import "package:relic/relic.dart";

Response handleDeveloperHotTakesPage(Request request) {
  final (:sessionId, :isNew) = visitorSession(request);
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
          name: visitorCookie,
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
