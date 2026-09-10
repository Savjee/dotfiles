#!/usr/bin/env bash
# Collect rclone RC status for every configured remote.

set -euo pipefail

RUNTIME=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
HOME=${HOME:-$(getent passwd "$(id -u)" | cut -d: -f6)}
WANT_ABOUT=0
[[ ${1:-} == --about ]] && WANT_ABOUT=1

if ! command -v jq >/dev/null || ! command -v rclone >/dev/null; then
  echo '{"ok":false,"error":"rclone or jq is missing"}'
  exit 1
fi

rc_json() {
  local socket=$1 timeout=$2
  shift 2
  if [[ ! -S $socket ]]; then
    printf '%s\n' 'null'
    return 0
  fi
  local out
  if ! out=$(timeout "$timeout" rclone rc --unix-socket "$socket" "$@" 2>/dev/null); then
    printf '%s\n' 'null'
    return 0
  fi
  if [[ -z $out ]] || ! jq -e 'type == "object" and (has("error") | not)' >/dev/null 2>&1 <<<"$out"; then
    printf '%s\n' 'null'
    return 0
  fi
  printf '%s\n' "$out"
}

list_remotes_json() {
  local listed='[]'
  local raw
  if raw=$(timeout 5 rclone listremotes --json 2>/dev/null); then
    listed=$(jq -c '
      [ .[]? | select(type == "object") | {
          name: ((.name // "") | rtrimstr(":") | gsub("^\\s+|\\s+$"; "")),
          type: (.type // "")
        } | select(.name != "")
      ]
    ' <<<"$raw" 2>/dev/null || echo '[]')
  fi

  local extras='[]'
  shopt -s nullglob
  local path stem name
  for path in "$RUNTIME"/rclone-*.sock; do
    stem=${path##*/}
    name=${stem#rclone-}
    name=${name%.sock}
    [[ -n $name ]] || continue
    extras=$(jq -c --arg name "$name" '. + [{"name":$name,"type":""}]' <<<"$extras")
  done

  jq -sc '
    (.[0] + .[1])
    | unique_by(.name)
    | sort_by(.name)
  ' <<<"$listed"$'\n'"$extras"
}

build_remote() {
  local name=$1 type=$2 stats=$3 transferred=$4 vfs=$5 queue=$6 about=$7
  jq -nc \
    --arg name "$name" \
    --arg type "$type" \
    --arg mountPath "$HOME/Cloud/$name" \
    --argjson wantAbout "$WANT_ABOUT" \
    --argjson stats "$stats" \
    --argjson transferred "$transferred" \
    --argjson vfs "$vfs" \
    --argjson queue "$queue" \
    --argjson about "$about" \
    -f /dev/stdin <<'JQ'
def basename:
  split("/") | .[-1];

def as_num($fallback):
  if . == null then $fallback
  else (try tonumber catch $fallback) end;

def transferring($stats; $queue; $remote):
  ($remote + ":") as $fs
  | [
      (($stats // {}).transferring // [])[]
      | select(type == "object")
      | . as $item
      | ($item.name // "") as $path
      | {
          remote: $remote,
          name: (if $path == "" then "Transfer" else ($path | basename) end),
          path: $path,
          bytes: ($item.bytes | as_num(0)),
          size: ($item.size | as_num(0)),
          percentage: ($item.percentage | as_num(0)),
          speed: (($item.speedAvg // $item.speed) | as_num(0)),
          eta: ($item.eta | as_num(-1)),
          direction: (
            if (($item.srcFs // "") | index($fs)) != null
               and (($item.dstFs // "") | index($fs)) == null
            then "download" else "upload" end
          )
        }
    ] as $active
  | ($active | map(.path) | map(select(. != ""))) as $seen
  | $active + [
      (($queue // {}).queue // [])[]
      | select(type == "object")
      | . as $item
      | ($item.name // "") as $path
      | select($path != "" and ($seen | index($path) | not))
      | {
          remote: $remote,
          name: ($path | basename),
          path: $path,
          bytes: 0,
          size: ($item.size | as_num(0)),
          percentage: 0,
          speed: 0,
          eta: -1,
          direction: "upload",
          queued: ($item.uploading | not),
          uploading: ($item.uploading == true)
        }
    ]
  | .[:16];

def recent($transferred; $remote):
  ($remote + ":") as $fs
  | [
      ((($transferred // {}).transferred // []) | reverse)[]
      | select(type == "object" and .what == "transferring")
      | . as $item
      | ($item.name // "") as $path
      | select($path != "")
      | {
          remote: $remote,
          name: ($path | basename),
          path: $path,
          bytes: (($item.bytes // $item.size) | as_num(0)),
          completedAt: ($item.completed_at // ""),
          direction: (
            if (($item.srcFs // "") | index($fs)) != null
               and (($item.dstFs // "") | index($fs)) == null
            then "download" else "upload" end
          ),
          error: ($item.error // "")
        }
    ]
  | .[:8];

(($vfs // {}).diskCache // {}) as $cache
| transferring($stats; $queue; $name) as $transfers
| {
    name: $name,
    type: $type,
    mounted: ($stats != null),
    mountPath: $mountPath,
    speed: ($transfers | map(.speed) | add // 0),
    bytes: ((($stats // {}).bytes) | as_num(0)),
    transfers: ((($stats // {}).transfers) | as_num(0) | floor),
    transferring: $transfers,
    recent: recent($transferred; $name),
    uploadsInProgress: (($cache.uploadsInProgress | as_num(0)) | floor),
    uploadsQueued: (($cache.uploadsQueued | as_num(0)) | floor),
    usedBytes: ((($about // {}).used) | as_num(0)),
    totalBytes: ((($about // {}).total) | as_num(0)),
    freeBytes: ((($about // {}).free) | as_num(0)),
    quotaKnown: ($wantAbout == 1 and $stats != null and (((($about // {}).total) | as_num(0)) > 0)),
    cacheBytes: (($cache.bytesUsed | as_num(0))),
    cacheFiles: (($cache.files | as_num(0)) | floor)
  }
JQ
}

remotes_json=$(list_remotes_json)
out='[]'

while IFS= read -r item; do
  [[ -n $item ]] || continue
  name=$(jq -r '.name' <<<"$item")
  type=$(jq -r '.type' <<<"$item")
  socket=$RUNTIME/rclone-$name.sock
  stats='null'
  transferred='null'
  vfs='null'
  queue='null'
  about='null'

  if stats=$(rc_json "$socket" 3 core/stats); then
    :
  fi
  if [[ $stats != null ]]; then
    transferred=$(rc_json "$socket" 3 core/transferred)
    vfs=$(rc_json "$socket" 3 vfs/stats)
    queue=$(rc_json "$socket" 3 vfs/queue "fs=${name}:")
    if (( WANT_ABOUT )); then
      about=$(rc_json "$socket" 8 operations/about "fs=${name}:")
    fi
  fi

  remote=$(build_remote "$name" "$type" "$stats" "$transferred" "$vfs" "$queue" "$about")
  out=$(jq -c --argjson remote "$remote" '. + [$remote]' <<<"$out")
done < <(jq -c '.[]' <<<"$remotes_json")

jq -nc --argjson remotes "$out" '{ok: true, remotes: $remotes}'
