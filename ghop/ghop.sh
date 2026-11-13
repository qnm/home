if [ -n "${GITHUB_TOKEN:-}${GH_TOKEN:-}" ]; then
  exec "$real_gh_dir/gh" "$@"
fi
PATH="$real_gh_dir:$PATH" exec op plugin run -- gh "$@"
