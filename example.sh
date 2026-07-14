#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: fetchdir [-z] [-p] user@host:/remote/dir /local/dest"
  echo "  -z   compress with zstd (good over slow links)"
  echo "  -p   show progress (requires pv)"
  exit 1
}

compress=false
progress=false
while getopts "zph" opt; do
  case $opt in
    z) compress=true ;;
    p) progress=true ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))
[ $# -eq 2 ] || usage

src="$1"; dest="$2"
host="${src%%:*}"
remote_path="${src#*:}"
parent="$(dirname "$remote_path")"
dir="$(basename "$remote_path")"

mkdir -p "$dest"

if $compress; then
  remote_cmd="tar cf - -C '$parent' '$dir' | zstd -T0"
  local_cmd="zstd -d | tar xf - -C '$dest'"
else
  remote_cmd="tar cf - -C '$parent' '$dir'"
  local_cmd="tar xf - -C '$dest'"
fi

if $progress; then
  ssh "$host" "$remote_cmd" | pv | eval "$local_cmd"
else
  ssh "$host" "$remote_cmd" | eval "$local_cmd"
fi
