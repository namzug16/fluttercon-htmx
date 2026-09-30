import "package:absurd_starter/src/ui/pages/user_example_page.dart";
import "package:absurd_starter/src/utils/htmx.dart";
import "package:relic/relic.dart";

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
