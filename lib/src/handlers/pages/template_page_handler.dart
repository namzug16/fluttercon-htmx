import "package:absurd_starter/src/ui/pages/template_page.dart";
import "package:absurd_starter/src/utils/htmx.dart";
import "package:relic/relic.dart";

Response handleTemplatePage(Request request) => htmlPage(pageAbsurdStarter());
