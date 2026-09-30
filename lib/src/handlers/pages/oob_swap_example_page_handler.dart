import "package:absurd_starter/src/ui/pages/oob_swap_example_page.dart";
import "package:absurd_starter/src/utils/htmx.dart";
import "package:relic/relic.dart";

Response handleOobSwapExamplePage(Request request) => htmlPage(pageOobSwapExample());
