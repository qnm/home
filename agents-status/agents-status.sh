quiet=false
case "${1:-}" in
--quiet) quiet=true ;;
"") ;;
*)
  echo "Usage: agents-status [--quiet]" >&2
  exit 1
  ;;
esac

uid=$(id -u)
stopped=0
while IFS=$'\t' read -r name label log; do
  [ -n "$name" ] || continue
  short_log="${log/#"$HOME"/\~}"
  info=$(launchctl print "gui/$uid/$label" 2>/dev/null || true)
  if grep -q '^\s*state = running' <<<"$info"; then
    $quiet || printf '%s: running · log %s\n' "$name" "$short_log"
    continue
  fi
  stopped=1
  exit_code=$(grep -m1 'last exit code' <<<"$info" | sed 's/.*= //' || true)
  if $quiet; then
    printf '%s: not running (last exit code %s); see agents-status\n' "$name" "${exit_code:-unknown}" >&2
  else
    printf '%s: not running (last exit code %s); the end of %s:\n' "$name" "${exit_code:-unknown}" "$short_log" >&2
    tail -n 10 "$log" 2>/dev/null | sed 's/^/    /' >&2 || true
  fi
done <"$AGENTS_FILE"
exit "$stopped"
