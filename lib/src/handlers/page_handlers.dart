import "package:absurd_starter/src/ui/pages/home_page.dart";
import "package:absurd_starter/src/ui/pages/ui_page.dart";
import "package:absurd_starter/src/ui/pages/user_example_page.dart";
import "package:absurd_starter/src/utils/htmx.dart";
import "package:relic/relic.dart";

Response handleHomePage(Request request) => htmlPage(pageHome());

Response handleUiPage(Request request) => htmlPage(pageUi());

Response handleUserExamplePage(Request request) => htmlPage(pageUserExample());

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
