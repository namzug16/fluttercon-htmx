import "package:absurd_starter/src/ui/pages/oob_swap_example_page.dart";
import "package:absurd_starter/src/utils/htmx.dart";
import "package:relic/relic.dart";

Future<Response> handleOobSwapTickets(Request request) async {
  await Future<void>.delayed(const Duration(milliseconds: 650));

  final form = await request.urlEncodedForm();
  final current = SupportQueueState(
    open: _intField(form, "open", initialSupportQueueState.open),
    urgent: _intField(form, "urgent", initialSupportQueueState.urgent),
    closed: _intField(form, "closed", initialSupportQueueState.closed),
    seed: _intField(form, "seed", initialSupportQueueState.seed),
  );

  return htmlFragments(supportQueueOobFragments(nextSupportQueueState(current)));
}

int _intField(UrlEncodedFormData form, String name, int fallback) =>
    int.tryParse(form.fields(StringFormField(name)) ?? "") ?? fallback;
