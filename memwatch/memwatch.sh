level_min=${MEMWATCH_LEVEL_MIN:-15}
tree_pct=${MEMWATCH_TREE_PCT:-50}
interval=${MEMWATCH_INTERVAL:-5}
dry_run=${MEMWATCH_DRY_RUN:-0}

total_kb=$(($(/usr/sbin/sysctl -n hw.memsize) / 1024))
tree_limit_kb=$((total_kb * tree_pct / 100))

log() {
  echo "$(/bin/date '+%F %T') $*"
}

pick_victim() {
  /bin/ps -axo pid=,ppid=,rss=,comm= | /usr/bin/awk \
    -v level="$1" -v level_min="$level_min" -v tree_limit="$tree_limit_kb" '
    {
      pid[NR] = $1; ppid[NR] = $2; rss[NR] = $3
      name = $0; sub(/^ *[0-9]+ +[0-9]+ +[0-9]+ +/, "", name); sub(/.*\//, "", name)
      comm[NR] = name
      if (name == "claude") { root[$1] = 1; tree[$1] = 1 }
    }
    END {
      do {
        grew = 0
        for (i = 1; i <= NR; i++)
          if (!(pid[i] in tree) && (ppid[i] in tree)) { tree[pid[i]] = 1; grew = 1 }
      } while (grew)

      for (i = 1; i <= NR; i++) {
        if (!(pid[i] in tree)) {
          if (comm[i] == "watchman" && rss[i] > any_rss) { any_rss = rss[i]; any = i }
          continue
        }
        total += rss[i]
        if (pid[i] in root) continue
        if (rss[i] > child_rss) { child_rss = rss[i]; child = i }
        if (rss[i] > any_rss) { any_rss = rss[i]; any = i }
      }

      if (total > tree_limit && child) v = child
      else if (level < level_min && any) v = any
      else exit
      printf "%s %s %s %s\n", pid[v], rss[v], total, comm[v]
    }'
}

terminate() {
  local pid=$1
  kill -TERM "$pid" 2>/dev/null || return 0
  for _ in 1 2 3 4 5; do
    sleep 1
    kill -0 "$pid" 2>/dev/null || return 0
  done
  kill -KILL "$pid" 2>/dev/null || true
}

log "start: level_min=${level_min}% tree_limit=$((tree_limit_kb / 1024))MB dry_run=${dry_run}"

while sleep "$interval"; do
  level=$(/usr/sbin/sysctl -n kern.memorystatus_level)
  victim=$(pick_victim "$level")
  [ -z "$victim" ] && continue

  read -r pid rss total name <<<"$victim"
  msg="level=${level}% claude_tree=$((total / 1024))MB -> ${name} pid ${pid} ($((rss / 1024))MB)"

  if [ "$dry_run" = 1 ]; then
    log "would kill: $msg"
    continue
  fi

  log "kill: $msg"
  terminate "$pid"
  /usr/bin/osascript -e "display notification \"killed ${name} (${pid}), $((rss / 1024))MB\" with title \"memwatch\"" || true
  sleep 10
done
