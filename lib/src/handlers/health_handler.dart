import "package:relic/relic.dart";

Response handleHealth(Request request) => Response.ok(body: Body.fromString("ok"));
