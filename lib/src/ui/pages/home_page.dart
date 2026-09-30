import "package:absurd_starter/src/ui/layout/primary_layout.dart";
import "package:absurd_starter/src/ui/lucide.dart";
import "package:htmleez/htmleez.dart";

HTML pageHome() => primaryLayout(
  body([
    $("class")("min-h-screen bg-background text-foreground antialiased"),
    mainTag([
      $("class")("mx-auto grid min-h-screen w-full max-w-3xl place-items-center px-4 py-10 sm:px-6"),
      section([
        $("class")("w-full rounded-3xl border bg-card p-5 shadow-sm sm:p-8"),
        div([
          $("class")("space-y-5"),
          div([
            $("class")("inline-flex items-center gap-2 rounded-full border bg-card px-3 py-1 text-sm text-muted-foreground shadow-sm"),
            Lucide.sparkles([$("class")("size-4")]),
            "Talk examples".t,
          ]),
          h1([
            $("class")("text-4xl font-bold tracking-tight text-balance sm:text-5xl"),
            "Full Stack Dart with HTMX".t,
          ]),
          p([
            $("class")("max-w-2xl text-base leading-7 text-muted-foreground text-pretty"),
            "This small app is used as an example for a talk about server rendered Dart, HTMX fragments, SQLite, and realtime hypermedia updates.".t,
          ]),
          a([
            $("href")("https://github.com/namzug16/fluttercon-htmx"),
            $("target")("_blank"),
            $("rel")("noreferrer"),
            $("class")("inline-flex items-center gap-2 text-sm font-medium text-primary hover:underline"),
            "github.com/namzug16/fluttercon-htmx".t,
            Lucide.externalLink([$("class")("size-4")]),
          ]),
          div([
            $("class")("grid gap-3 pt-3 sm:grid-cols-3"),
            a([
              $("href")("/user-example"),
              $("class")("btn w-full"),
              $("data-variant")("outline"),
              Lucide.users([$("data-icon")("inline-start")]),
              "User example".t,
            ]),
            a([
              $("href")("/developer-hot-takes"),
              $("class")("btn w-full"),
              Lucide.flame([$("data-icon")("inline-start")]),
              "Developer Hot Takes".t,
            ]),
            a([
              $("href")("/ui"),
              $("class")("btn w-full"),
              $("data-variant")("outline"),
              Lucide.palette([$("data-icon")("inline-start")]),
              "UI".t,
            ]),
          ]),
        ]),
      ]),
    ]),
  ]),
  seo: const PageSeo(
    title: "Full Stack Dart with HTMX",
    description: "Demo app for a talk about full stack Dart with HTMX.",
  ),
);

HTML counterFragment(int count) => div([
  $("id")("counter-result"),
  $("class")("mb-4 rounded-xl bg-muted p-5 text-center"),
  p([$("class")("text-sm text-muted-foreground"), "Counter".t]),
  p([$("class")("text-4xl font-bold"), count.toString().t]),
  input([$("type")("hidden"), $("name")("count"), $("value")(count.toString()), $("form")("counter-form")]),
]);
