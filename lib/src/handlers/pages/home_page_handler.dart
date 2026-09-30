import "package:absurd_starter/src/ui/pages/home_page.dart";
import "package:absurd_starter/src/utils/htmx.dart";
import "package:relic/relic.dart";

Response handleHomePage(Request request) => htmlPage(pageHome());
