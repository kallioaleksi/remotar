#!/usr/bin/env bash
# Offline test suite for remotar. Uses tests/shim/ssh so the "remote" side
# runs in a local bash — no network or SSH access needed.
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
remotar="$repo_root/bin/remotar"
export PATH="$repo_root/tests/shim:$PATH"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
export SSH_SHIM_LOG="$work/ssh.log"

failures=0

pass() { echo "ok - $1"; }
fail() { echo "FAIL - $1" >&2; failures=$((failures + 1)); }

make_fixture() {
  local dir="$1"
  mkdir -p "$dir/sub dir"
  echo "hello" > "$dir/plain.txt"
  echo "spaces" > "$dir/with space.txt"
  echo "quote" > "$dir/it's.txt"
  echo "dollar" > "$dir/\$var.txt"
  echo "nested" > "$dir/sub dir/deep.txt"
}

# --- fetch: remote -> local -------------------------------------------------

for flags in "" "-z"; do
  label="fetch ${flags:-plain}"
  src="$work/fetch-src${flags}"
  dest="$work/fetch-dest${flags}"
  make_fixture "$src/payload"
  # shellcheck disable=SC2086
  if "$remotar" $flags "testhost:$src/payload" "$dest" \
      && diff -r "$src/payload" "$dest/payload" >/dev/null; then
    pass "$label"
  else
    fail "$label"
  fi
done

# --- push: local -> remote --------------------------------------------------

for flags in "" "-z"; do
  label="push ${flags:-plain}"
  src="$work/push-src${flags}"
  dest="$work/push-dest${flags}/created/by/mkdir"   # mkdir -p must create this
  make_fixture "$src/payload"
  # shellcheck disable=SC2086
  if "$remotar" $flags "$src/payload" "testhost:$dest" \
      && diff -r "$src/payload" "$dest/payload" >/dev/null; then
    pass "$label"
  else
    fail "$label"
  fi
done

# --- shim sanity: ssh was actually invoked with the host --------------------

if [ "$(sort -u "$SSH_SHIM_LOG")" = "testhost" ]; then
  pass "ssh invoked with host argument"
else
  fail "ssh invoked with host argument (log: $(cat "$SSH_SHIM_LOG"))"
fi

# --- usage and direction errors ----------------------------------------------

expect_exit() {
  local label="$1" expected="$2"
  shift 2
  local rc=0
  "$@" >/dev/null 2>&1 || rc=$?
  if [ "$rc" -eq "$expected" ]; then
    pass "$label"
  else
    fail "$label (expected exit $expected, got $rc)"
  fi
}

expect_exit "both args remote -> exit 2" 2 "$remotar" "a:/x" "b:/y"
expect_exit "both args local -> exit 2" 2 "$remotar" "$work" "$work"
expect_exit "missing args -> exit 2" 2 "$remotar"
expect_exit "unknown flag -> exit 2" 2 "$remotar" -q "a:/x" "$work"
expect_exit "empty remote path -> exit 2" 2 "$remotar" "host:" "$work"
expect_exit "--help -> exit 0" 0 "$remotar" --help
expect_exit "--version -> exit 0" 0 "$remotar" --version
expect_exit "-h -> exit 0" 0 "$remotar" -h

# local path with a colon after a slash is treated as local, so this pair
# is local+remote and must attempt a push of a missing dir -> die (exit 1)
mkdir -p "$work/colon"
expect_exit "./a:b treated as local" 1 "$remotar" "$work/colon/a:b" "host:/tmp/x"

# push of nonexistent local source -> clean error, exit 1
expect_exit "push missing source -> exit 1" 1 "$remotar" "$work/nope" "host:/tmp/x"

# --version content
if [ "$("$remotar" --version)" = "remotar 1.0.0" ]; then
  pass "--version output"
else
  fail "--version output"
fi

# --- result ------------------------------------------------------------------

echo
if [ "$failures" -eq 0 ]; then
  echo "All tests passed."
else
  echo "$failures test(s) failed." >&2
  exit 1
fi
