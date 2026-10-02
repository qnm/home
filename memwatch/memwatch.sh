level_min=${MEMWATCH_LEVEL_MIN:-20}
interval=${MEMWATCH_INTERVAL:-5}
dry_run=${MEMWATCH_DRY_RUN:-0}

log() {
  echo "$(/bin/date '+%F %T') $*"
}

pick_victim() {
  {
    /usr/bin/top -l 1 -stats pid,mem
    echo "--ps--"
    /bin/ps -axo pid=,ppid=,rss=,comm=
  } | /usr/bin/awk '
    $0 == "--ps--" { in_ps = 1; next }
    !in_ps {
      if ($1 ~ /^[0-9]+$/ && $2 ~ /^[0-9.]+[BKMG]/) {
        v = $2 + 0; u = $2; sub(/^[0-9.]+/, "", u); u = substr(u, 1, 1)
        if (u == "B") v /= 1024; else if (u == "M") v *= 1024; else if (u == "G") v *= 1048576
        foot[$1] = int(v)
      }
      next
    }
    {
      n++
      pid[n] = $1; ppid[n] = $2; rss[n] = ($1 in foot) ? foot[$1] : $3
      name = $0; sub(/^ *[0-9]+ +[0-9]+ +[0-9]+ +/, "", name); sub(/.*\//, "", name)
      comm[n] = name
      if (name == "claude") { root[$1] = 1; tree[$1] = 1 }
    }
    END {
      do {
        grew = 0
        for (i = 1; i <= n; i++)
          if (!(pid[i] in tree) && (ppid[i] in tree)) { tree[pid[i]] = 1; grew = 1 }
      } while (grew)

      for (i = 1; i <= n; i++) {
        if (!(pid[i] in tree)) {
          if (comm[i] == "watchman" && rss[i] > any_rss) { any_rss = rss[i]; any = i }
          continue
        }
        total += rss[i]
        if (pid[i] in root) continue
        if (rss[i] > any_rss) { any_rss = rss[i]; any = i }
      }

      if (!any) exit
      printf "%s %s %s %s\n", pid[any], rss[any], total, comm[any]
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

log "start: level_min=${level_min}% dry_run=${dry_run}"

while sleep "$interval"; do
  level=$(/usr/sbin/sysctl -n kern.memorystatus_level)
  [ "$level" -ge "$level_min" ] && continue
  victim=$(pick_victim)
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
