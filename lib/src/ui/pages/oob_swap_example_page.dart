import "dart:convert";

import "package:absurd_starter/src/ui/components/htmx_events.dart";
import "package:absurd_starter/src/ui/layout/primary_layout.dart";
import "package:absurd_starter/src/ui/lucide.dart";
import "package:htmleez/htmleez.dart";
import "package:htmleez/htmleez.dart" as tags;

const hxPartial = Tag("hx-partial");

const initialSupportQueueState = SupportQueueState(open: 3, urgent: 1, closed: 7, seed: 3);

const _customers = ["Acme Finance", "Northwind Labs", "Cobalt Studio", "BrightDesk", "Orbit School", "Papertrail Co.", "Delta Clinic", "Mason Retail"];
const _subjects = ["Cannot access billing", "Export job is stuck", "Invite email never arrived", "Webhook retries failing", "Dashboard numbers look wrong", "Need invoice for renewal", "SSO login loops", "API rate limit question"];
const _owners = ["Mika", "Nova", "Sol", "Iris"];
const _priorities = ["Normal", "High", "Urgent", "Normal", "High", "Normal"];

class SupportQueueState {
  const SupportQueueState({required this.open, required this.urgent, required this.closed, required this.seed});

  final int open;
  final int urgent;
  final int closed;
  final int seed;

  int get total => open + closed;
  int get avgWait => (open * 3 + urgent * 7 + 8).clamp(4, 90);
  int get load => (open * 14 + urgent * 18).clamp(0, 100);

  String get hxVals => jsonEncode({"open": open, "urgent": urgent, "closed": closed, "seed": seed});
}

class SupportTicket {
  const SupportTicket({required this.id, required this.customer, required this.subject, required this.priority, required this.status, required this.owner, required this.minutesAgo});

  final String id;
  final String customer;
  final String subject;
  final String priority;
  final String status;
  final String owner;
  final int minutesAgo;
}

SupportQueueState nextSupportQueueState(SupportQueueState current) {
  final nextSeed = current.seed + 1;
  final priority = _priorityFor(nextSeed);
  final closesExistingTicket = nextSeed % 4 == 0 && current.open > 0;

  final nextUrgent = current.urgent + (priority == "Urgent" ? 1 : 0);

  return SupportQueueState(
    open: current.open + 1 - (closesExistingTicket ? 1 : 0),
    urgent: nextUrgent.clamp(0, 999),
    closed: current.closed + (closesExistingTicket ? 1 : 0),
    seed: nextSeed,
  );
}

HTML pageOobSwapExample() => primaryLayout(
  body([
    $("class")("min-h-screen bg-background text-foreground antialiased"),
    mainTag([
      $("class")("mx-auto flex min-h-screen w-full max-w-6xl flex-col gap-6 px-4 py-5 sm:px-6 lg:px-8"),
      supportStatsFragment(initialSupportQueueState),
      newTicketCommandFragment(initialSupportQueueState),
      section([
        $("class")("grid gap-4 lg:grid-cols-[1fr_22rem]"),
        div([$("class")("min-w-0 space-y-4"), ticketsTableFragment(initialSupportQueueState)]),
        div([
          $("class")("space-y-4"),
          queueHealthFragment(initialSupportQueueState),
          activityFeedFragment(initialSupportQueueState),
        ]),
      ]),
    ]),
  ]),
  seo: const PageSeo(
    title: "Support Queue OOB Swap | Full Stack Dart with HTMX",
    description: "A realistic HTMX out-of-band swap demo powered by server rendered Dart fragments and hx-vals.",
  ),
);

List<HTML> supportQueueOobFragments(SupportQueueState state) {
  final newestTicket = _ticketFor(state.seed, newest: true);

  return [
    supportStatsFragment(state).add($("hx-swap-oob")("outerHTML transition:true")),
    //NOTE: hx-partial -> explicit control over targeting and swap strategy
    hxPartial([
      $("hx-target")("#ticket-rows"),
      $("hx-swap")("beforeend show:top transition:true"),
      _ticketRow(newestTicket),
    ]),
    ticketsTotalBadgeFragment(state).add($("hx-swap-oob")("textContent transition:true")),
    newTicketCommandFragment(state).add($("hx-swap-oob")("outerHTML transition:true")),
    queueHealthFragment(state).add($("hx-swap-oob")("outerHTML transition:true")),
    div([
      $("hx-swap-oob")("afterbegin transition:true target:#activity-feed-items"),
      _activityItem(newestTicket),
    ]),
  ];
}

HTML supportStatsFragment(SupportQueueState state) => section([
  $("id")("support-stats"),
  $("class")("grid gap-3 sm:grid-cols-2 lg:grid-cols-4"),
  _statCard(Lucide.inbox, "Open", state.open.toString(), "Tickets waiting for an agent."),
  _statCard(Lucide.triangleAlert, "Urgent", state.urgent.toString(), "Needs a fast response.", variant: state.urgent > 2 ? "destructive" : "secondary"),
  _statCard(Lucide.circleCheck, "Closed", state.closed.toString(), "Resolved during this session."),
  _statCard(Lucide.clock, "Avg wait", "${state.avgWait}m", "Estimated first response time."),
]);

HTML _statCard(HTML Function([List<HTML>]) icon, String title, String value, String description, {String? variant}) => div([
  $("class")("card"),
  $("data-size")("sm"),
  tags.header([
    h2([title.t]),
    div([
      $("class")("card-action text-muted-foreground"),
      icon([$("class")("size-4")]),
    ]),
  ]),
  section([
    div([$("class")("text-3xl font-bold tabular-nums"), value.t]),
    p([$("class")("mt-1 text-sm text-muted-foreground"), description.t]),
  ]),
  if (variant != null)
    footer([
      span([$("class")("badge"), $("data-variant")(variant), title.t]),
    ]),
]);

HTML ticketsTableFragment(SupportQueueState state) => div([
  $("id")("tickets-table"),
  $("class")("card min-w-0"),
  tags.header([
    div([
      h2(["Recent tickets".t]),
      p(["The newest row appears from the same OOB response that updates the rest of the dashboard.".t]),
    ]),
    div([
      $("class")("card-action"),
      ticketsTotalBadgeFragment(state),
    ]),
  ]),
  section([
    div([
      $("class")("table-container w-full max-w-full overflow-x-auto"),
      table([
        $("id")("support-tickets"),
        $("class")("table min-w-3xl"),
        thead([
          tr([
            th(["Ticket".t]),
            th(["Customer".t]),
            th(["Subject".t]),
            th(["Priority".t]),
            th(["Status".t]),
            th(["Owner".t]),
          ]),
        ]),
        tbody([
          $("id")("ticket-rows"),
          for (final ticket in _recentTickets(state)) _ticketRow(ticket),
        ]),
      ]),
    ]),
  ]),
]);

HTML ticketsTotalBadgeFragment(SupportQueueState state) => span([
  $("id")("support-ticket-total"),
  $("class")("badge"),
  $("data-variant")("outline"),
  "${state.total} total".t,
]);

HTML _ticketRow(SupportTicket ticket) => tr([
  td([$("class")("font-mono"), ticket.id.t]),
  td([ticket.customer.t]),
  td([$("class")("max-w-64 truncate"), ticket.subject.t]),
  td([_priorityBadge(ticket.priority)]),
  td([_statusBadge(ticket.status)]),
  td([ticket.owner.t]),
]);

HTML newTicketCommandFragment(SupportQueueState state) => form([
  $("id")("new-ticket-command"),
  $("hx-post")("/oob-swap-example/tickets"),
  $("hx-swap")("none"),
  $("hx-vals")(state.hxVals),
  ...disableFieldsetsOnHtmxRequest(),
  fieldset([
    $("class")("grid"),
    button([
      $("type")("submit"),
      $("class")("btn group w-full"),
      Lucide.loaderCircle([$("class")("loader group-disabled:animate-spin group-enabled:hidden")]),
      Lucide.plus([$("data-icon")("inline-start"), $("class")("group-disabled:hidden")]),
      "New support ticket".t,
    ]),
  ]),
]);

HTML queueHealthFragment(SupportQueueState state) => div([
  $("id")("queue-health"),
  $("class")("card"),
  $("data-size")("sm"),
  tags.header([
    h2(["Queue health".t]),
    p([_queueHealthText(state).t]),
  ]),
  section([
    $("class")("space-y-4"),
    div([
      div([
        $("class")("mb-2 flex justify-between text-sm"),
        span(["SLA pressure".t]),
        span([$("class")("font-mono text-muted-foreground"), "${state.load}%".t]),
      ]),
      div([
        $("class")("progress"),
        $("role")("progressbar"),
        $("aria-label")("SLA pressure"),
        $("aria-valuenow")(state.load.toString()),
        $("aria-valuemin")("0"),
        $("aria-valuemax")("100"),
        span([$("style")("width: ${state.load}%")]),
      ]),
    ]),
    div([
      $("class")("item-group grid gap-2"),
      $("role")("list"),
      _healthItem(Lucide.users, "Agents online", "${2 + state.seed % 3} handling queue"),
      _healthItem(Lucide.timer, "Next review", "in ${6 + state.seed % 8} minutes"),
    ]),
  ]),
]);

HTML _healthItem(HTML Function([List<HTML>]) icon, String title, String description) => article([
  $("class")("item"),
  $("role")("listitem"),
  $("data-size")("sm"),
  figure([icon()]),
  section([
    h3([title.t]),
    p([description.t]),
  ]),
]);

HTML activityFeedFragment(SupportQueueState state) => div([
  $("id")("activity-feed"),
  $("class")("card"),
  $("data-size")("sm"),
  tags.header([
    h2(["Activity".t]),
    p(["Latest queue events.".t]),
  ]),
  section([
    $("class")("item-group grid gap-2"),
    $("id")("activity-feed-items"),
    $("role")("list"),
    for (final ticket in _recentTickets(state).take(4)) _activityItem(ticket),
  ]),
]);

HTML _activityItem(SupportTicket ticket) => article([
  $("class")("item"),
  $("role")("listitem"),
  $("data-size")("sm"),
  figure([Lucide.messageSquarePlus()]),
  section([
    h3(["${ticket.id} · ${ticket.customer}".t]),
    p(["${ticket.priority.toLowerCase()} priority · ${ticket.minutesAgo}m ago".t]),
  ]),
  aside([_statusBadge(ticket.status)]),
]);

HTML _priorityBadge(String priority) => span([
  $("class")("badge"),
  $("data-variant")(
    priority == "Urgent"
        ? "destructive"
        : priority == "High"
        ? "secondary"
        : "outline",
  ),
  priority.t,
]);

HTML _statusBadge(String status) => span([
  $("class")("badge"),
  $("data-variant")(status == "Closed" ? "secondary" : "outline"),
  status.t,
]);

List<SupportTicket> _recentTickets(SupportQueueState state) {
  final start = state.seed <= 0 ? 1 : state.seed;
  final tickets = <SupportTicket>[];

  for (var offset = 0; offset < 7 && start - offset > 0; offset++) {
    final ticketSeed = start - offset;
    tickets.add(_ticketFor(ticketSeed, newest: offset == 0));
  }

  return tickets;
}

SupportTicket _ticketFor(int seed, {required bool newest}) {
  final priority = _priorityFor(seed);
  return SupportTicket(
    id: "SUP-${(1000 + seed).toString()}",
    customer: _customers[seed % _customers.length],
    subject: _subjects[(seed * 3) % _subjects.length],
    priority: priority,
    status: newest || seed % 4 != 0 ? "Open" : "Closed",
    owner: _owners[(seed * 2) % _owners.length],
    minutesAgo: newest ? 0 : seed % 9 + 2,
  );
}

String _priorityFor(int seed) => _priorities[seed % _priorities.length];

String _queueHealthText(SupportQueueState state) {
  if (state.urgent >= 3) return "Urgent tickets are piling up. Pull another agent in.";
  if (state.open >= 7) return "Queue is getting busy, but still under control.";
  return "Queue is healthy. Keep first response time low.";
}
