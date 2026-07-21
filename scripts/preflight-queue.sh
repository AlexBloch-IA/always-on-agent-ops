#!/usr/bin/env bash
# Preflight: one authenticated GET, count the items, dispatch only if count > 0.
# Zero LLM tokens. Run it often (every 5-15 min); let the heavy cron sleep.
#
# THE PREFLIGHT DECIDES NOTHING. IT COUNTS.
# It must never fetch a work item, mutate state, or judge what to do next.
#
# Reads ${QUEUE_URL} and ${API_TOKEN} from scripts/secrets.env (chmod 600, never in git).
# No secrets.env = no network. Every exit path emits exactly one status line.
# Deliberately NOT `set -e`: a preflight that dies mid-run is the silence this skill exists to prevent.
set -uo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$DIR/cron-message.sh"

# Fail closed AND audible: absent config is a status line, not a shell error.
if [ ! -f "$DIR/secrets.env" ]; then
  cron_message "pf-10-queue" "Human action required" "secrets.env absent - no network configured." \
    "preflight" "Create scripts/secrets.env (chmod 600). See SKILL.md, Setup." "reason=no_config"
  exit 0
fi
# shellcheck disable=SC1091
source "$DIR/secrets.env"

if [ -z "${QUEUE_URL:-}" ] || [ -z "${API_TOKEN:-}" ]; then
  cron_message "pf-10-queue" "Human action required" "QUEUE_URL or API_TOKEN missing from secrets.env." \
    "preflight" "Set both, then rerun." "reason=no_config"
  exit 0
fi

# `-fs` + 2>/dev/null on purpose: curl's own diagnostic on stderr would land in the channel
# next to the status line. One event, one line. The Error line below carries the meaning.
json="$(curl -fs --max-time 30 "$QUEUE_URL" -H "Authorization: Bearer ${API_TOKEN}" 2>/dev/null || true)"
if [ -z "$json" ]; then
  cron_message "pf-10-queue" "Error" "Queue unreachable (HTTP error, timeout, or empty body)." \
    "outbound queue" "No cron started; the heavy job's spaced fallback still covers this." "reason=fetch_failed"
  exit 0
fi

# Tolerant count: honour an explicit numeric `count`, else the SHALLOWEST array found
# anywhere in the payload (breadth-first, so a nested {data:{items:[...]}} still counts).
#
# "Counted zero" and "found nothing to count" are DIFFERENT ANSWERS. An empty array is 0.
# A payload with no count and no array anywhere - a 200 carrying {"error":"unauthorized"},
# a shape we do not understand - prints `nocount` and becomes an Error line. Returning 0
# there would report "Queue empty" while the queue fills: the silence this skill exists to
# prevent, manufactured by its own counter.
count="$(printf '%s' "$json" | node -e '
let s = "";
process.stdin.on("data", (d) => (s += d));
process.stdin.on("end", () => {
  let j;
  try { j = JSON.parse(s); } catch { process.stdout.write("unparsable"); return; }
  if (j === null || typeof j !== "object") { process.stdout.write("unparsable"); return; }
  if (typeof j.count === "number" && Number.isFinite(j.count)) {
    process.stdout.write(String(Math.max(0, Math.trunc(j.count))));
    return;
  }
  const q = [j];
  for (let i = 0; i < q.length && i < 2000; i++) {
    const n = q[i];
    if (Array.isArray(n)) { process.stdout.write(String(n.length)); return; }
    for (const v of Object.values(n)) if (v !== null && typeof v === "object") q.push(v);
  }
  process.stdout.write("nocount");
});
' || echo "unparsable")"

case "$count" in
  nocount)
    cron_message "pf-10-queue" "Error" "Payload carries no count and no array - cannot tell empty from full." \
      "outbound queue" "Check the endpoint and the token; a 200 carrying an API error object looks like this." "reason=no_countable_field"
    exit 0
    ;;
  ''|*[!0-9]*)
    cron_message "pf-10-queue" "Error" "Unreadable payload (not JSON, or not an object/array)." \
      "outbound queue" "Check the endpoint; a login page or proxy error looks like this." "reason=bad_payload"
    exit 0
    ;;
esac

if [ "$count" -gt 0 ]; then
  # One event, one status line: the dispatcher speaks, the preflight stays quiet.
  # `exec bash` on purpose: ClawHub ships text, not file modes, so the exec bit may
  # be absent on a fresh install. A bare exec would die 126 with NO status line -
  # the exact silence this skill exists to prevent.
  exec bash "$DIR/event-dispatch.sh" work_ready "$count"
fi

cron_message "pf-10-queue" "Nothing to do" "Queue empty." "outbound queue" \
  "No cron started." "count=0"
exit 0
