import "package:absurd_starter/src/ui/pages/user_example_page.dart";
import "package:absurd_starter/src/utils/htmx.dart";
import "package:relic/relic.dart";

Response handleUserExamplePage(Request request) => htmlPage(pageUserExample());
