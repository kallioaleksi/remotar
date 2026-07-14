# remotar

**remote + tar.** Copy a directory between local and remote by piping a tar
stream over SSH — no temp files, no rsync required on the other end.

```sh
# fetch: remote -> local
remotar user@host:/var/logs ./out          # -> ./out/logs

# push: local -> remote
remotar ./logs user@host:/var/backup       # -> /var/backup/logs
```

Direction is inferred scp-style: exactly one argument must look like
`[user@]host:/path`. The directory itself is copied into the destination —
there is no rsync trailing-slash magic.

## Install

```sh
brew tap kallioaleksi/remotar https://github.com/kallioaleksi/remotar
brew install remotar
```

## Options

| Flag | Effect | Requires |
| ---- | ------ | -------- |
| `-z` | compress the stream with zstd (good over slow links) | `zstd` on both ends |
| `-p` | show transfer progress | `pv` locally |

```sh
remotar -zp user@host:/var/lib/big-dataset ./data
```

Install the optional tools with `brew install zstd pv`.

## Notes

- An argument counts as remote if it contains a colon with no slash before it
  (the scp rule). Write a local path that contains a colon with a leading
  `./` or as an absolute path.
- Remote paths are escaped with `printf %q`, so spaces, quotes, and `$` are
  safe. Paths containing control characters need a bash/zsh/ksh shell on the
  remote side.
- All hosts, ports, identities, and multiplexing options come from your
  regular SSH config.

## Development

```sh
tests/run.sh                                    # offline suite (fake ssh shim)
shellcheck bin/remotar tests/run.sh tests/shim/ssh
```

## Releasing

Versions follow [semantic versioning](https://semver.org/).

1. Bump `VERSION` in `bin/remotar` and the `url` in `Formula/remotar.rb`; commit.
2. `git tag vX.Y.Z && git push --tags && gh release create vX.Y.Z`
3. `curl -sL https://github.com/kallioaleksi/remotar/archive/refs/tags/vX.Y.Z.tar.gz | shasum -a 256`
4. Update `sha256` in `Formula/remotar.rb`; commit and push.

## License

[MIT](LICENSE)
