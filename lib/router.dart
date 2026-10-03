import "dart:io";

import "package:absurd_starter/src/handlers/page_handlers.dart";
import "package:absurd_starter/src/handlers/pages/template_page_handler.dart";
import "package:relic/relic.dart";

enum Pages {
  home("/"),
  ui("/ui"),
  template("/template"),
  userExample("/user-example"),
  oobSwapExample("/oob-swap-example"),
  developerHotTakes("/developer-hot-takes"),
  health("/health");

  final String path;

  const Pages(this.path);
}

void router(RelicApp app) {
  app
    ..use("/", logRequests())
    ..anyOf(
      {Method.get, Method.head},
      "/**",
      StaticHandler.directory(
        Directory("public"),
        cacheControl: (_, _) => null,
      ).asHandler,
    )
    ..get(Pages.home.path, handleHomePage)
    ..get(Pages.ui.path, handleUiPage)
    ..get(Pages.template.path, handleTemplatePage)
    ..get(Pages.userExample.path, handleUserExamplePage)
    ..get(Pages.oobSwapExample.path, handleOobSwapExamplePage)
    ..get(Pages.developerHotTakes.path, handleDeveloperHotTakesPage)
    ..get("${Pages.developerHotTakes.path}/ws", handleDeveloperHotTakesSocket)
    ..get(Pages.health.path, handleHealth)
    ..delete("/users/42", handleDeleteUserExample)
    ..get("/users/42", handleRestoreUserExample)
    ..post("${Pages.oobSwapExample.path}/tickets", handleOobSwapTickets)
    ..post("/api/counter/increment", handleCounterIncrement);
}
