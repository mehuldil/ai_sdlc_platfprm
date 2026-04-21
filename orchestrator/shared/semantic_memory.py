"""Unified semantic long-term memory for all orchestrators.

Features:
- Semantic retrieval ranking (token + trigram cosine score)
- Conflict resolution (reject | last_write_wins | merge_append)
- Lifecycle governance (active/superseded/archived + retention)
"""

from __future__ import annotations

import hashlib
import json
import math
import re
import sqlite3
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any


def _utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _tokenize(text: str) -> list[str]:
    return re.findall(r"[a-z0-9]{2,}", text.lower())


def _char_trigrams(text: str) -> list[str]:
    normalized = re.sub(r"\s+", " ", text.lower())
    if len(normalized) < 3:
        return [normalized] if normalized else []
    return [normalized[i : i + 3] for i in range(0, len(normalized) - 2)]


def _term_freq(tokens: list[str]) -> dict[str, float]:
    out: dict[str, float] = {}
    if not tokens:
        return out
    for t in tokens:
        out[t] = out.get(t, 0.0) + 1.0
    total = float(len(tokens))
    for k in list(out.keys()):
        out[k] = out[k] / total
    return out


def _cosine(a: dict[str, float], b: dict[str, float]) -> float:
    if not a or not b:
        return 0.0
    dot = 0.0
    for k, v in a.items():
        dot += v * b.get(k, 0.0)
    mag_a = math.sqrt(sum(v * v for v in a.values()))
    mag_b = math.sqrt(sum(v * v for v in b.values()))
    if mag_a == 0.0 or mag_b == 0.0:
        return 0.0
    return dot / (mag_a * mag_b)


@dataclass
class UpsertResult:
    status: str
    doc_id: str | None
    version: int | None
    reason: str = ""


class UnifiedSemanticMemory:
    """SQLite-backed semantic memory index for orchestration artifacts."""

    def __init__(self, db_path: str | Path):
        self.db_path = Path(db_path)
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        self.conn = sqlite3.connect(str(self.db_path))
        self.conn.row_factory = sqlite3.Row
        self._init_schema()

    def _init_schema(self) -> None:
        cur = self.conn.cursor()
        cur.execute(
            """
            CREATE TABLE IF NOT EXISTS memory_entries (
              id TEXT PRIMARY KEY,
              orchestrator TEXT NOT NULL,
              namespace TEXT NOT NULL,
              memory_key TEXT NOT NULL,
              content TEXT NOT NULL,
              metadata_json TEXT NOT NULL,
              version INTEGER NOT NULL,
              checksum TEXT NOT NULL,
              status TEXT NOT NULL DEFAULT 'active',
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              supersedes_id TEXT,
              conflict_strategy TEXT NOT NULL DEFAULT 'reject'
            )
            """
        )
        cur.execute(
            """
            CREATE UNIQUE INDEX IF NOT EXISTS idx_memory_unique_version
            ON memory_entries(orchestrator, namespace, memory_key, version)
            """
        )
        cur.execute(
            """
            CREATE INDEX IF NOT EXISTS idx_memory_lookup
            ON memory_entries(orchestrator, namespace, memory_key, status, updated_at)
            """
        )
        cur.execute(
            """
            CREATE TABLE IF NOT EXISTS memory_audit (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              memory_id TEXT,
              action TEXT NOT NULL,
              details_json TEXT NOT NULL,
              created_at TEXT NOT NULL
            )
            """
        )
        self.conn.commit()

    def close(self) -> None:
        self.conn.close()

    def _latest(self, orchestrator: str, namespace: str, memory_key: str) -> sqlite3.Row | None:
        cur = self.conn.cursor()
        cur.execute(
            """
            SELECT *
            FROM memory_entries
            WHERE orchestrator = ? AND namespace = ? AND memory_key = ?
            ORDER BY version DESC
            LIMIT 1
            """,
            (orchestrator, namespace, memory_key),
        )
        return cur.fetchone()

    def _audit(self, memory_id: str | None, action: str, details: dict[str, Any]) -> None:
        self.conn.execute(
            """
            INSERT INTO memory_audit(memory_id, action, details_json, created_at)
            VALUES (?, ?, ?, ?)
            """,
            (memory_id, action, json.dumps(details, default=str), _utc_now()),
        )

    def upsert(
        self,
        orchestrator: str,
        namespace: str,
        memory_key: str,
        content: str,
        metadata: dict[str, Any] | None = None,
        *,
        expected_version: int | None = None,
        conflict_strategy: str = "reject",
    ) -> UpsertResult:
        metadata = metadata or {}
        if conflict_strategy not in {"reject", "last_write_wins", "merge_append"}:
            raise ValueError(f"Invalid conflict_strategy: {conflict_strategy}")

        latest = self._latest(orchestrator, namespace, memory_key)
        created_at = _utc_now()
        checksum = hashlib.sha256(content.encode("utf-8")).hexdigest()

        if latest is None:
            version = 1
            doc_id = hashlib.sha1(f"{orchestrator}:{namespace}:{memory_key}:{version}:{checksum}".encode("utf-8")).hexdigest()
            self.conn.execute(
                """
                INSERT INTO memory_entries
                (id, orchestrator, namespace, memory_key, content, metadata_json, version,
                 checksum, status, created_at, updated_at, supersedes_id, conflict_strategy)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'active', ?, ?, NULL, ?)
                """,
                (
                    doc_id,
                    orchestrator,
                    namespace,
                    memory_key,
                    content,
                    json.dumps(metadata, default=str),
                    version,
                    checksum,
                    created_at,
                    created_at,
                    conflict_strategy,
                ),
            )
            self._audit(doc_id, "CREATE", {"orchestrator": orchestrator, "namespace": namespace, "memory_key": memory_key})
            self.conn.commit()
            return UpsertResult(status="created", doc_id=doc_id, version=version)

        current_version = int(latest["version"])
        if expected_version is not None and expected_version != current_version:
            if conflict_strategy == "reject":
                self._audit(str(latest["id"]), "CONFLICT_REJECTED", {"expected_version": expected_version, "current_version": current_version})
                self.conn.commit()
                return UpsertResult(
                    status="conflict",
                    doc_id=str(latest["id"]),
                    version=current_version,
                    reason=f"expected version {expected_version}, found {current_version}",
                )
            if conflict_strategy == "merge_append":
                content = f"{latest['content']}\n\n---\n[merged-update @ {_utc_now()}]\n{content}"

        version = current_version + 1
        doc_id = hashlib.sha1(f"{orchestrator}:{namespace}:{memory_key}:{version}:{checksum}".encode("utf-8")).hexdigest()

        self.conn.execute("UPDATE memory_entries SET status = 'superseded', updated_at = ? WHERE id = ?", (_utc_now(), str(latest["id"])))
        self.conn.execute(
            """
            INSERT INTO memory_entries
            (id, orchestrator, namespace, memory_key, content, metadata_json, version,
             checksum, status, created_at, updated_at, supersedes_id, conflict_strategy)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'active', ?, ?, ?, ?)
            """,
            (
                doc_id,
                orchestrator,
                namespace,
                memory_key,
                content,
                json.dumps(metadata, default=str),
                version,
                checksum,
                created_at,
                created_at,
                str(latest["id"]),
                conflict_strategy,
            ),
        )
        self._audit(doc_id, "UPSERT", {"supersedes": str(latest["id"]), "strategy": conflict_strategy})
        self.conn.commit()
        return UpsertResult(status="updated", doc_id=doc_id, version=version)

    def query(
        self,
        query_text: str,
        *,
        orchestrator: str | None = None,
        namespace: str | None = None,
        limit: int = 10,
        include_archived: bool = False,
    ) -> list[dict[str, Any]]:
        if not query_text.strip():
            return []
        params: list[Any] = []
        where = []
        if not include_archived:
            where.append("status != 'archived'")
        if orchestrator:
            where.append("orchestrator = ?")
            params.append(orchestrator)
        if namespace:
            where.append("namespace = ?")
            params.append(namespace)
        where_sql = f"WHERE {' AND '.join(where)}" if where else ""

        cur = self.conn.cursor()
        cur.execute(
            f"""
            SELECT id, orchestrator, namespace, memory_key, content, metadata_json, version, status, updated_at
            FROM memory_entries
            {where_sql}
            """,
            tuple(params),
        )
        rows = cur.fetchall()
        if not rows:
            return []

        query_terms = _tokenize(query_text) + _char_trigrams(query_text)
        q_tf = _term_freq(query_terms)

        # Build global idf from selected corpus.
        doc_terms: list[set[str]] = []
        for row in rows:
            tokens = set(_tokenize(str(row["content"])) + _char_trigrams(str(row["content"])))
            doc_terms.append(tokens)
        n_docs = len(doc_terms)
        df: dict[str, int] = {}
        for terms in doc_terms:
            for t in terms:
                df[t] = df.get(t, 0) + 1

        idf: dict[str, float] = {}
        for term, count in df.items():
            idf[term] = math.log((1 + n_docs) / (1 + count)) + 1.0

        q_vec = {t: v * idf.get(t, 1.0) for t, v in q_tf.items()}
        scored: list[dict[str, Any]] = []
        for row in rows:
            tokens = _tokenize(str(row["content"])) + _char_trigrams(str(row["content"]))
            d_tf = _term_freq(tokens)
            d_vec = {t: v * idf.get(t, 1.0) for t, v in d_tf.items()}
            lexical = _cosine(q_vec, d_vec)
            # Freshness bonus (small): up to +5% for recent artifacts.
            try:
                age_days = max(0.0, (datetime.now(timezone.utc) - datetime.fromisoformat(str(row["updated_at"]))).total_seconds() / 86400.0)
            except ValueError:
                age_days = 365.0
            freshness = 1.0 + max(0.0, (30.0 - age_days) / 600.0)
            score = lexical * freshness
            if score <= 0:
                continue
            scored.append(
                {
                    "id": row["id"],
                    "orchestrator": row["orchestrator"],
                    "namespace": row["namespace"],
                    "memory_key": row["memory_key"],
                    "version": row["version"],
                    "status": row["status"],
                    "updated_at": row["updated_at"],
                    "score": round(score, 6),
                    "snippet": str(row["content"])[:320],
                    "metadata": json.loads(str(row["metadata_json"])),
                }
            )

        scored.sort(key=lambda x: x["score"], reverse=True)
        return scored[: max(1, limit)]

    def apply_lifecycle_governance(
        self,
        *,
        archive_superseded_after_days: int = 30,
        retain_versions_per_key: int = 5,
        hard_delete_archived_after_days: int = 365,
    ) -> dict[str, int]:
        now = datetime.now(timezone.utc)
        archived = 0
        deleted = 0
        trimmed = 0

        cur = self.conn.cursor()
        cur.execute("SELECT id, status, updated_at, orchestrator, namespace, memory_key FROM memory_entries")
        rows = cur.fetchall()

        for row in rows:
            try:
                updated_at = datetime.fromisoformat(str(row["updated_at"]))
            except ValueError:
                updated_at = now - timedelta(days=9999)
            age_days = (now - updated_at).days
            if row["status"] == "superseded" and age_days >= archive_superseded_after_days:
                self.conn.execute("UPDATE memory_entries SET status='archived', updated_at=? WHERE id=?", (_utc_now(), row["id"]))
                self._audit(str(row["id"]), "ARCHIVE", {"age_days": age_days})
                archived += 1
            elif row["status"] == "archived" and age_days >= hard_delete_archived_after_days:
                self.conn.execute("DELETE FROM memory_entries WHERE id=?", (row["id"],))
                self._audit(str(row["id"]), "DELETE", {"age_days": age_days})
                deleted += 1

        # Trim excessive historical versions per key.
        cur.execute(
            """
            SELECT orchestrator, namespace, memory_key
            FROM memory_entries
            GROUP BY orchestrator, namespace, memory_key
            """
        )
        groups = cur.fetchall()
        for g in groups:
            cur.execute(
                """
                SELECT id
                FROM memory_entries
                WHERE orchestrator = ? AND namespace = ? AND memory_key = ?
                ORDER BY version DESC
                """,
                (g["orchestrator"], g["namespace"], g["memory_key"]),
            )
            ids = [str(r["id"]) for r in cur.fetchall()]
            for old_id in ids[retain_versions_per_key:]:
                self.conn.execute("UPDATE memory_entries SET status='archived', updated_at=? WHERE id=?", (_utc_now(), old_id))
                self._audit(old_id, "TRIM_ARCHIVE", {"retain_versions": retain_versions_per_key})
                trimmed += 1

        self.conn.commit()
        return {"archived": archived, "deleted": deleted, "trimmed": trimmed}

    def stats(self) -> dict[str, Any]:
        cur = self.conn.cursor()
        cur.execute("SELECT status, COUNT(*) as c FROM memory_entries GROUP BY status")
        by_status = {str(r["status"]): int(r["c"]) for r in cur.fetchall()}
        cur.execute("SELECT COUNT(*) as c FROM memory_entries")
        total = int(cur.fetchone()["c"])
        cur.execute("SELECT COUNT(*) as c FROM memory_audit")
        audit_count = int(cur.fetchone()["c"])
        return {"total_entries": total, "by_status": by_status, "audit_events": audit_count, "db_path": str(self.db_path)}

    def export_active_latest(self) -> list[dict[str, Any]]:
        """Export latest active row per (orchestrator, namespace, memory_key) for team git sync."""
        cur = self.conn.cursor()
        cur.execute(
            """
            SELECT e.id, e.orchestrator, e.namespace, e.memory_key, e.content, e.metadata_json,
                   e.version, e.status, e.updated_at, e.checksum
            FROM memory_entries e
            INNER JOIN (
              SELECT orchestrator, namespace, memory_key, MAX(version) AS max_v
              FROM memory_entries
              WHERE status = 'active'
              GROUP BY orchestrator, namespace, memory_key
            ) x
              ON e.orchestrator = x.orchestrator
             AND e.namespace = x.namespace
             AND e.memory_key = x.memory_key
             AND e.version = x.max_v
            WHERE e.status = 'active'
            """
        )
        out: list[dict[str, Any]] = []
        for row in cur.fetchall():
            out.append(
                {
                    "orchestrator": str(row["orchestrator"]),
                    "namespace": str(row["namespace"]),
                    "memory_key": str(row["memory_key"]),
                    "content": str(row["content"]),
                    "metadata": json.loads(str(row["metadata_json"])),
                    "version": int(row["version"]),
                    "updated_at": str(row["updated_at"]),
                    "checksum": str(row["checksum"]),
                }
            )
        return out

    def import_team_export(
        self,
        records: list[dict[str, Any]],
        *,
        conflict_strategy: str = "last_write_wins",
    ) -> dict[str, int]:
        """Merge records from a team JSONL export into the local DB."""
        applied = 0
        skipped = 0
        for rec in records:
            orch = str(rec.get("orchestrator", "")).strip()
            ns = str(rec.get("namespace", "")).strip()
            key = str(rec.get("memory_key", "")).strip()
            content = str(rec.get("content", ""))
            if not orch or not ns or not key:
                skipped += 1
                continue
            meta = rec.get("metadata")
            if not isinstance(meta, dict):
                meta = {}
            remote_ts = str(rec.get("updated_at", ""))
            latest = self._latest(orch, ns, key)
            if latest is not None:
                try:
                    local_ts = str(latest["updated_at"])
                    if remote_ts and local_ts and remote_ts < local_ts:
                        skipped += 1
                        continue
                except (TypeError, ValueError):
                    pass
            self.upsert(
                orch,
                ns,
                key,
                content,
                meta,
                conflict_strategy=conflict_strategy,
            )
            applied += 1
        return {"applied": applied, "skipped": skipped}

