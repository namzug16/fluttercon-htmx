import "dart:io";

import "package:sqlite3/sqlite3.dart";

class Take {
  const Take({
    required this.id,
    required this.text,
    required this.score,
    required this.upvotes,
    required this.downvotes,
    required this.createdAt,
  });

  final int id;
  final String text;
  final int score;
  final int upvotes;
  final int downvotes;
  final DateTime createdAt;
}

class HotTakesStats {
  const HotTakesStats({
    required this.totalVotes,
    required this.totalVisitors,
    required this.activeVisitors,
  });

  final int totalVotes;
  final int totalVisitors;
  final int activeVisitors;
}

class HotTakesSnapshot {
  const HotTakesSnapshot({
    required this.takes,
    required this.stats,
  });

  final List<Take> takes;
  final HotTakesStats stats;
}

class HotTakesStore {
  HotTakesStore({String path = "data/hot_takes.sqlite"}) {
    final file = File(path);
    file.parent.createSync(recursive: true);
    _db = sqlite3.open(path);
    _migrate();
    _seed();
  }

  late final Database _db;

  HotTakesSnapshot snapshot({required int activeVisitors}) => HotTakesSnapshot(
    takes: listTakes(),
    stats: stats(activeVisitors: activeVisitors),
  );

  List<Take> listTakes({int limit = 30}) {
    final rows = _db.select(
      """
      SELECT id, text, score, upvotes, downvotes, created_at
      FROM takes
      ORDER BY score DESC, created_at DESC, id DESC
      LIMIT ?
      """,
      [limit],
    );

    return [for (final row in rows) _takeFromRow(row)];
  }

  Take? findTake(int id) {
    final rows = _db.select(
      """
      SELECT id, text, score, upvotes, downvotes, created_at
      FROM takes
      WHERE id = ?
      """,
      [id],
    );

    if (rows.isEmpty) return null;
    return _takeFromRow(rows.first);
  }

  Take addTake(String text) {
    final now = DateTime.now().toUtc().toIso8601String();
    _db.execute(
      """
      INSERT INTO takes (text, score, created_at)
      VALUES (?, 0, ?)
      """,
      [text, now],
    );

    return findTake(_db.lastInsertRowId)!;
  }

  Take? vote(int id, {required int delta}) {
    _db.execute(
      """
      UPDATE takes
      SET
        score = score + ?,
        upvotes = upvotes + CASE WHEN ? > 0 THEN 1 ELSE 0 END,
        downvotes = downvotes + CASE WHEN ? < 0 THEN 1 ELSE 0 END
      WHERE id = ?
      """,
      [delta, delta, delta, id],
    );

    if (_db.updatedRows == 0) return null;

    _db.execute(
      """
      INSERT INTO vote_events (take_id, direction, created_at)
      VALUES (?, ?, ?)
      """,
      [id, delta, DateTime.now().toUtc().toIso8601String()],
    );

    return findTake(id);
  }

  void registerVisitor(String sessionId) {
    final now = DateTime.now().toUtc().toIso8601String();
    _db.execute(
      """
      INSERT INTO visitors (session_id, first_seen_at, last_seen_at)
      VALUES (?, ?, ?)
      ON CONFLICT(session_id) DO UPDATE SET last_seen_at = excluded.last_seen_at
      """,
      [sessionId, now, now],
    );
  }

  HotTakesStats stats({required int activeVisitors}) {
    final totalVotes = _db.select("SELECT COUNT(*) AS count FROM vote_events").first["count"] as int;
    final totalVisitors = _db.select("SELECT COUNT(*) AS count FROM visitors").first["count"] as int;

    return HotTakesStats(
      totalVotes: totalVotes,
      totalVisitors: totalVisitors,
      activeVisitors: activeVisitors,
    );
  }

  void close() => _db.close();

  void _migrate() {
    _db.execute("PRAGMA journal_mode = WAL");
    _db.execute("PRAGMA foreign_keys = ON");
    _db.execute("""
      CREATE TABLE IF NOT EXISTS takes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL CHECK(length(text) <= 180),
        score INTEGER NOT NULL DEFAULT 0,
        upvotes INTEGER NOT NULL DEFAULT 0,
        downvotes INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    """);
    try {
      _db.execute("ALTER TABLE takes ADD COLUMN upvotes INTEGER NOT NULL DEFAULT 0");
      _db.execute("UPDATE takes SET upvotes = score WHERE score > 0 AND upvotes = 0");
    } on SqliteException {
      // Local demo database was already migrated.
    }
    try {
      _db.execute("ALTER TABLE takes ADD COLUMN downvotes INTEGER NOT NULL DEFAULT 0");
      _db.execute("UPDATE takes SET downvotes = abs(score) WHERE score < 0 AND downvotes = 0");
    } on SqliteException {
      // Local demo database was already migrated.
    }
    _db.execute("""
      CREATE TABLE IF NOT EXISTS vote_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        take_id INTEGER NOT NULL REFERENCES takes(id) ON DELETE CASCADE,
        direction INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    """);
    try {
      _db.execute("ALTER TABLE vote_events ADD COLUMN direction INTEGER NOT NULL DEFAULT 1");
    } on SqliteException {
      // Older local demo databases already have this column after the first run.
    }
    _db.execute("""
      CREATE TABLE IF NOT EXISTS visitors (
        session_id TEXT PRIMARY KEY,
        first_seen_at TEXT NOT NULL,
        last_seen_at TEXT NOT NULL
      )
    """);
  }

  void _seed() {
    final count = _db.select("SELECT COUNT(*) AS count FROM takes").first["count"] as int;
    if (count > 0) return;

    const takes = [
      "YAML is a programming language.",
      "You do not need Kubernetes.",
      "Types are just tests that run before production.",
      "The best frontend framework is a good form action.",
      "A monolith is a microservice with better boundaries.",
    ];

    for (final take in takes) {
      addTake(take);
    }
  }

  Take _takeFromRow(Row row) => Take(
    id: row["id"] as int,
    text: row["text"] as String,
    score: row["score"] as int,
    upvotes: row["upvotes"] as int,
    downvotes: row["downvotes"] as int,
    createdAt: DateTime.parse(row["created_at"] as String),
  );
}
