import "package:absurd_starter/src/ui/pages/ui_page.dart";
import "package:absurd_starter/src/utils/htmx.dart";
import "package:relic/relic.dart";

Response handleUiPage(Request request) => htmlPage(pageUi());
