import "package:absurd_starter/src/ui/components/htmx_events.dart";
import "package:absurd_starter/src/ui/layout/primary_layout.dart";
import "package:absurd_starter/src/ui/lucide.dart";
import "package:htmleez/htmleez.dart";

HTML pageUserExample() => primaryLayout(
  body([
    $("class")("min-h-screen bg-background text-foreground antialiased"),
    mainTag([
      $("class")("mx-auto grid min-h-screen w-full max-w-xl place-items-center px-6 py-12"),
      div([
        $("class")("w-full space-y-4"),
        userCardFragment(),
      ]),
    ]),
  ]),
  seo: const PageSeo(
    title: "User Example | Absurd Starter",
    description: "Small HTMX delete and restore user fragment example.",
  ),
);

HTML userCardFragment() => article([
  $("id")("user-42"),
  $("class")("rounded-2xl border bg-card p-5 shadow-sm"),
  div([
    $("class")("flex items-start gap-4"),
    div([
      $("class")("grid size-12 place-items-center rounded-full bg-primary/10 text-sm font-bold text-primary"),
      "GG".t,
    ]),
    div([
      $("class")("min-w-0 flex-1"),
      h1([$("class")("text-lg font-semibold tracking-tight"), "Gustavo Guzman".t]),
      p([$("class")("mt-1 text-sm text-muted-foreground"), "Example user card rendered by the Dart backend.".t]),
    ]),
  ]),
  div([
    $("class")("mt-5 flex justify-end"),
    form([
      ...disableFieldsetsOnHtmxRequest(),
      fieldset([
        button([
          $("type")("button"),
          $("class")("btn group"),
          $("data-variant")("destructive"),
          $("hx-delete")("/users/42"),
          $("hx-trigger")("click"),
          $("hx-target")("#user-42"),
          $("hx-swap")("outerHTML"),
          Lucide.loaderCircle([$("class")("loader group-disabled:animate-spin group-enabled:hidden")]),
          Lucide.trash2([$("data-icon")("inline-start"), $("class")("group-disabled:hidden")]),
          "Delete".t,
        ]),
      ]),
    ]),
  ]),
]);

HTML deletedUserFragment() => div([
  $("id")("user-42"),
  $("class")("space-y-4"),
  div([
    $("class")("space-y-4 rounded-2xl border border-destructive/30 bg-destructive/10 p-5 text-sm font-medium text-destructive"),
    $("hx-on:load")("setTimeout(() => this.remove(), 3000)"),
    "User deleted".t,
    div([
      $("class")("h-2 w-72 max-w-full overflow-hidden rounded-full"),
      div([
        $("id")("progress"),
        $("class")("h-full w-full  bg-zinc-800 transition-[width] duration-[3000ms] ease-linear"),
        $("hx-on:load")("setTimeout(() => this.style.width = '0%', 20)"),
      ]),
    ]),
  ]),
  form([
    $("id")("restore-user-42"),
    $("hx-get")("/users/42"),
    $("hx-target")("#user-42"),
    $("hx-swap")("outerHTML"),
    ...disableFieldsetsOnHtmxRequest(),
    fieldset([
      $("class")("grid"),
      button([
        $("type")("submit"),
        $("class")("btn group w-full"),
        $("data-variant")("outline"),
        Lucide.loaderCircle([$("class")("loader group-disabled:animate-spin group-enabled:hidden")]),
        Lucide.rotateCcw([$("data-icon")("inline-start"), $("class")("group-disabled:hidden")]),
        "Restore user".t,
      ]),
    ]),
  ]),
]);
