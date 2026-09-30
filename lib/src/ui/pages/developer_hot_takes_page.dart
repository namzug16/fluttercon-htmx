import "package:absurd_starter/src/hot_takes/hot_takes_store.dart";
import "package:absurd_starter/src/ui/layout/primary_layout.dart";
import "package:absurd_starter/src/ui/lucide.dart";
import "package:htmleez/htmleez.dart";
import "package:htmleez/htmleez.dart" as tags;

HTML pageDeveloperHotTakes(HotTakesSnapshot snapshot) => primaryLayout(
  body([
    $("class")("min-h-screen bg-background text-foreground antialiased"),
    div([
      $("hx-ws:connect")("/developer-hot-takes/ws"),
      $("hx-target")("#hot-takes-app"),
      $("hx-swap")("outerHTML"),
      $("hx-on:htmx:ws:before:message:outgoing")("this.querySelectorAll('button').forEach((button) => button.disabled = true)"),
      $("hx-on:htmx:ws:after:message:incoming")("this.querySelectorAll('button').forEach((button) => button.disabled = false)"),
      $("hx-on:htmx:ws:error")("this.querySelectorAll('button').forEach((button) => button.disabled = false)"),
      hotTakesApp(snapshot),
    ]),
  ]),
  seo: const PageSeo(
    title: "Developer Hot Takes | Full Stack Dart with HTMX",
    description: "A realtime HTMX and SQLite demo for a Full Stack Dart with HTMX talk.",
  ),
);

HTML hotTakesApp(HotTakesSnapshot snapshot, {String takeValue = "", String? takeError}) => div([
  $("id")("hot-takes-app"),
  newTakeDialog(value: takeValue, error: takeError),
  div([
    $("class")("min-h-screen bg-background text-foreground antialiased"),
    mainTag([
      $("class")("mx-auto flex min-h-screen w-full max-w-6xl flex-col gap-6 px-4 py-5 sm:px-6 lg:px-8"),
      _hotTakesHeader(snapshot.stats),
      section([
        $("class")("space-y-4"),
        statsPanelFragment(snapshot.stats),
        takesListFragment(snapshot.takes),
      ]),
    ]),
  ]),
]);

HTML _hotTakesHeader(HotTakesStats stats) => tags.header([
  $("class")("overflow-hidden rounded-3xl border bg-card p-5 shadow-sm sm:p-6"),
  div([
    $("class")("flex flex-col gap-5 sm:flex-row sm:items-start sm:justify-between"),
    div([
      $("class")("space-y-3"),
      a([
        $("href")("/"),
        $("class")("inline-flex items-center gap-2 text-sm font-medium text-muted-foreground hover:text-foreground"),
        "← Back to examples".t,
      ]),
      h1([
        $("class")("max-w-2xl text-4xl font-bold tracking-tight text-balance sm:text-5xl"),
        "Developer Hot Takes".t,
      ]),
      p([
        $("class")("max-w-2xl text-base leading-7 text-muted-foreground text-pretty"),
        "Post a terrible opinion, vote on the spicy ones, and watch HTMX update several parts of the page from server rendered Dart.".t,
      ]),
    ]),
    button([
      $("type")("button"),
      $("class")("btn w-full bg-orange-600 text-white hover:bg-orange-700 sm:w-auto dark:bg-orange-500 dark:hover:bg-orange-600"),
      $("onclick")("document.getElementById('new-take-dialog').showModal()"),
      Lucide.messageSquarePlus([$("data-icon")("inline-start")]),
      "Add a take".t,
    ]),
  ]),
]);

HTML takesListFragment(List<Take> takes) => div([
  $("id")("takes"),
  $("class")("space-y-3"),
  if (takes.isEmpty)
    div([
      $("class")("rounded-2xl border border-dashed bg-card p-6 text-center text-sm text-muted-foreground"),
      "No takes yet. This is suspiciously reasonable.".t,
    ])
  else
    for (final take in takes) takeCard(take),
]);

HTML takeCard(Take take) => article([
  $("id")("take-${take.id}"),
  $("class")("relative overflow-hidden rounded-2xl border bg-card p-4 shadow-sm transition-all duration-700 ease-[cubic-bezier(0.32,0.72,0,1)] hover:-translate-y-0.5 hover:shadow-md"),
  div([
    $("class")("flex gap-3"),
    div([
      $("class")("button-group"),
      $("role")("group"),
      $("aria-label")("Text alignment"),
      _voteButton(take, delta: 1),
      div([
        $("class")("btn"),
        $("data-variant")("outline"),
        $("disabled")(),
        span([
          $("class")("text-emerald-800"),
          "+${take.upvotes}".t,
        ]),
        span([
          $("class")("text-rose-800"),
          "-${take.downvotes}".t,
        ]),
      ]),
      _voteButton(take, delta: -1),
    ]),
    div([
      $("class")("min-w-0 flex-1 py-1"),
      h3([$("class")("text-lg font-semibold leading-7 text-pretty"), take.text.t]),
    ]),
  ]),
]);

HTML _voteButton(Take take, {required int delta}) => form([
  $("class")("btn"),
  $("hx-ws:send")(),
  if (delta < 0) $("data-variant")("destructive"),
  if (delta > 0) $("data-variant")("outline"),
  input([$("type")("hidden"), $("name")("action"), $("value")("vote")]),
  input([$("type")("hidden"), $("name")("take_id"), $("value")(take.id.toString())]),
  input([$("type")("hidden"), $("name")("delta"), $("value")(delta.toString())]),
  button([
    $("type")("submit"),
    $("aria-label")(delta > 0 ? "Upvote this take" : "Downvote this take"),
    if (delta > 0) Lucide.arrowBigUp([$("class")("size-5")]) else Lucide.arrowBigDown([$("class")("size-5")]),
  ]),
]);

HTML statsPanelFragment(HotTakesStats stats) => section([
  $("id")("hot-takes-stats"),
  $("class")("grid grid-cols-3 gap-2 rounded-2xl border bg-card p-3 shadow-sm"),
  _statItem(Lucide.vote, stats.totalVotes.toString(), "votes cast", "bg-orange-50 text-orange-950 dark:bg-orange-950 dark:text-orange-50"),
  _statItem(Lucide.users, stats.activeVisitors.toString(), "live now", "bg-sky-50 text-sky-950 dark:bg-sky-950 dark:text-sky-50"),
  _statItem(Lucide.activity, stats.totalVisitors.toString(), "visited", "bg-emerald-50 text-emerald-950 dark:bg-emerald-950 dark:text-emerald-50"),
]);

HTML _statItem(HTML Function([List<HTML>]) icon, String value, String label, String classes) => div([
  $classes(["rounded-xl p-3 text-center", classes]),
  icon([$("class")("mx-auto mb-2 size-4 opacity-70")]),
  div([$("class")("text-xl font-bold tabular-nums"), value.t]),
  div([$("class")("text-xs opacity-70"), label.t]),
]);

HTML newTakeDialog({String value = "", String? error}) => tags.dialog([
  $("id")("new-take-dialog"),
  $("class")("dialog"),
  $("aria-labelledby")("new-take-dialog-title"),
  $("aria-describedby")("new-take-dialog-description"),
  $("onclick")("if (event.target === this) this.close()"),
  div([
    $("class")("sm:max-w-lg"),
    tags.header([
      h2([$("id")("new-take-dialog-title"), "Add a developer hot take".t]),
      p([$("id")("new-take-dialog-description"), "Keep it short, spicy, and safe for a conference room.".t]),
    ]),
    section([
      takeDialogContent(value: value, error: error),
    ]),
    button([
      $("type")("button"),
      $("class")("btn"),
      $("data-variant")("ghost"),
      $("data-size")("icon-sm"),
      $("aria-label")("Close dialog"),
      $("onclick")("this.closest('dialog').close()"),
      Lucide.x([Attribute("aria-hidden")("true")]),
    ]),
  ]),
]);

HTML takeDialogContent({String value = "", String? error}) => div([
  $("id")("new-take-dialog-content"),
  form([
    $("class")("space-y-4"),
    $("hx-ws:send")(),
    input([$("type")("hidden"), $("name")("action"), $("value")("create")]),
    div([
      $("class")("space-y-2"),
      label([$("for")("take-text"), $("class")("text-sm font-medium"), "Hot take".t]),
      textarea([
        $("id")("take-text"),
        $("name")("take"),
        $("class")("textarea min-h-28"),
        $("maxlength")("180"),
        $("required")(),
        $("placeholder")("Write a terrible opinion..."),
        if (error != null) $("aria-invalid")("true"),
        if (error != null) $("aria-describedby")("take-error"),
        value.t,
      ]),
      div([
        $("class")("flex items-center justify-between gap-3 text-xs text-muted-foreground"),
        span(["Maximum 180 characters.".t]),
        span(["Server validates this too.".t]),
      ]),
      if (error != null)
        div([
          $("id")("take-error"),
          $("class")("alert mt-3"),
          $("data-variant")("destructive"),
          Lucide.circleAlert(),
          h2(["We could not post that take".t]),
          section([error.t]),
        ]),
    ]),
    div([
      $("class")("flex flex-col-reverse gap-2 sm:flex-row sm:justify-end"),
      button([
        $("type")("button"),
        $("class")("btn"),
        $("data-variant")("outline"),
        $("onclick")("this.closest('dialog').close()"),
        "Cancel".t,
      ]),
      button([
        $("type")("submit"),
        $("class")("btn"),
        Lucide.plus([$("data-icon")("inline-start")]),
        "Post take".t,
      ]),
    ]),
  ]),
]);
