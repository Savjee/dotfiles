#!/usr/bin/env bash
# Fetch GitHub repos with gh, cache them, and publish Omarchy menu rows.

set -euo pipefail

PLUGIN_ID=xavier.gh-repos
PLUGIN_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CACHE_TMP=/tmp/$PLUGIN_ID.json
CACHE_PERSIST=${XDG_CACHE_HOME:-$HOME/.cache}/$PLUGIN_ID/repos.json
MENU_PATH=$HOME/.config/omarchy/extensions/omarchy-menu.jsonc
JSON_FIELDS=nameWithOwner,description,url,isPrivate,isFork,isArchived
GITHUB_ICON=$'\uf408'
REFRESH_ICON=$'\uf021'
SIGNIN_ICON=$'\U000f0337'

SEED=0
[[ ${1:-} == --seed ]] && SEED=1

strip_jsonc() {
  awk '
    /^[[:space:]]*\/\// { next }
    /^[[:space:]]*$/ { next }
    { lines[++n] = $0 }
    END {
      for (i = 1; i <= n; i++) {
        line = lines[i]
        if (i == n - 1 && lines[n] ~ /^[[:space:]]*}/) sub(/,[[:space:]]*$/, "", line)
        print line
      }
    }
  '
}

atomic_write() {
  local path=$1 dir tmp
  dir=$(dirname -- "$path")
  mkdir -p -- "$dir"
  tmp=$(mktemp -- "$dir/.$(basename -- "$path").XXXXXX")
  cat >"$tmp"
  mv -f -- "$tmp" "$path"
}

normalize_repos() {
  jq -c '[
    .[]? | select((.nameWithOwner // "") != "" and (.url // "") != "") | {
      nameWithOwner: .nameWithOwner,
      description: ((.description // "") | gsub("^\\s+|\\s+$"; "")),
      url: .url,
      isPrivate: (.isPrivate == true),
      isFork: (.isFork == true),
      isArchived: (.isArchived == true)
    }
  ]' 2>/dev/null || echo '[]'
}

repos_from_cache_file() {
  local file=$1
  [[ -f $file ]] || { echo '[]'; return; }
  jq -c '.repos // []' "$file" 2>/dev/null || echo '[]'
}

best_cache_repos() {
  local tmp persist
  tmp=$(repos_from_cache_file "$CACHE_TMP")
  persist=$(repos_from_cache_file "$CACHE_PERSIST")

  if [[ $tmp != '[]' && $persist != '[]' ]]; then
    local tmp_at persist_at
    tmp_at=$(jq -r '.fetchedAt // ""' "$CACHE_TMP" 2>/dev/null || true)
    persist_at=$(jq -r '.fetchedAt // ""' "$CACHE_PERSIST" 2>/dev/null || true)
    if [[ $tmp_at > $persist_at ]]; then
      printf '%s\n' "$tmp"
    else
      printf '%s\n' "$persist"
    fi
  elif [[ $tmp != '[]' ]]; then
    printf '%s\n' "$tmp"
  else
    printf '%s\n' "$persist"
  fi
}

user_menu_items() {
  if [[ ! -f $MENU_PATH ]]; then
    echo '{}'
    return
  fi
  strip_jsonc <"$MENU_PATH" | jq -c '
    if type != "object" then {}
    elif ((.items | type) == "object") and ((.github | type) != "object") then .items
    else . end
    | with_entries(select(
        (.value | type) == "object"
        and .key != "github"
        and (.key | startswith("github.") | not)
        and (.key | startswith("ghrepo-") | not)
      ))
  '
}

managed_items() {
  jq -nc \
    --argjson repos "$1" \
    --arg error "${2:-}" \
    --arg icon "$GITHUB_ICON" \
    --arg refresh_icon "$REFRESH_ICON" \
    --arg signin_icon "$SIGNIN_ICON" \
    --arg refresh_action "$PLUGIN_DIR/fetch.sh" \
    --arg signin_action "omarchy-launch-floating-terminal-with-presentation 'gh auth login'" \
    -f /dev/stdin <<'JQ'
def slugify:
  ascii_downcase | gsub("[^a-z0-9]+"; "-") | gsub("^-+"; "") | gsub("-+$"; "")
  | if . == "" then "item" else . end;

def unique_id($base; $taken):
  if $taken[$base] then unique_id($base + "-dup"; $taken) else $base end;

def short_name: split("/") | .[-1];
def owner: split("/") | if length == 2 then .[0] else "" end;

def flags:
  [
    (if .isPrivate then "private" else empty end),
    (if .isFork then "fork" else empty end),
    (if .isArchived then "archived" else empty end)
  ] | join(", ");

def extra:
  ((.description // "") | gsub("^\\s+|\\s+$"; "")) as $d
  | flags as $f
  | if $d != "" and $f != "" then "\($d) · \($f)"
    elif $d != "" then $d
    else $f end;

def shell_quote:
  "'" + gsub("'"; "'\\''") + "'";

def action:
  "omarchy-launch-browser " + (.url | shell_quote);

{
  github: {
    icon: $icon,
    label: "GitHub",
    aliases: ["gh"],
    description: "Search cached GitHub repositories",
    when: "false"
  },
  "github.refresh": {
    icon: $refresh_icon,
    label: "Refresh repositories",
    description: "Fetch with gh and update the local cache",
    action: $refresh_action
  }
} as $base
| if ($error != "" and ($repos | length) == 0) then
    $base + {
      "github.signin": {
        icon: $signin_icon,
        label: "Sign in with gh",
        description: $error,
        action: $signin_action
      }
    }
  else
    ($repos | map(.nameWithOwner | short_name) | group_by(.) | map({key: .[0], value: length}) | from_entries) as $counts
    | reduce $repos[] as $repo (
        {items: $base, taken: {"github": true, "github.refresh": true, "github.signin": true}};
        ($repo.nameWithOwner) as $full
        | ($full | short_name) as $short
        | ($full | owner) as $owner
        | (if ($counts[$short] // 0) == 1 then $short else "\($short) (\($owner))" end) as $browse_label
        | unique_id("github.\($full | slugify)"; .taken) as $id
        | ($repo | extra) as $extra
        | .items += {
            ($id): {
              icon: $icon,
              label: $browse_label,
              aliases: ["gh", $full],
              description: $extra,
              action: ($repo | action)
            }
          }
        | .taken += {($id): true}
      )
    | .items
  end
JQ
}

dump_jsonc() {
  local user_items=$1 generated=$2
  {
    printf '%s\n' '{'
    printf '%s\n' '  // Omarchy menu extensions.'
    printf '%s\n' '  //'
    printf '%s\n' '  // github.* come from xavier.gh-repos (hidden from the root list).'
    printf '%s\n' '  // scw.* come from xavier.scw (hidden from the root list).'
    printf '%s\n' '  // Other keys in this file are yours.'
    printf '%s\n' ''
    jq -n --argjson user "$user_items" --argjson generated "$generated" -r '
      ($user + $generated)
      | to_entries
      | map("  \(.key | @json): \(.value | tojson)")
      | join(",\n")
    '
    printf '%s\n' '}'
  }
}

publish_menu() {
  local repos=$1 error=${2:-}
  local user_items generated text
  user_items=$(user_menu_items)
  generated=$(managed_items "$repos" "$error")
  text=$(dump_jsonc "$user_items" "$generated")
  if [[ -f $MENU_PATH && $(cat -- "$MENU_PATH") == "$text" ]]; then
    return
  fi
  atomic_write "$MENU_PATH" <<<"$text"
}

write_cache() {
  local payload
  payload=$(jq -nc --argjson repos "$1" --arg fetchedAt "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{fetchedAt: $fetchedAt, repos: $repos}')
  atomic_write "$CACHE_TMP" <<<"$payload"
  atomic_write "$CACHE_PERSIST" <<<"$payload"
}

list_repos() {
  if [[ -n ${1:-} ]]; then
    gh repo list "$1" --limit 1000 --json "$JSON_FIELDS"
  else
    gh repo list --limit 1000 --json "$JSON_FIELDS"
  fi
}

fetch_repos() {
  local owned more org combined='[]'

  if owned=$(list_repos 2>/dev/null); then
    combined=$(normalize_repos <<<"$owned")
  elif ! gh auth status >/dev/null 2>&1; then
    echo 'gh is not signed in' >&2
    echo '[]'
    return 1
  fi

  if [[ $combined == '[]' ]] && ! gh auth status >/dev/null 2>&1; then
    echo 'gh is not signed in' >&2
    echo '[]'
    return 1
  fi

  while IFS= read -r org; do
    [[ -z $org ]] && continue
    if more=$(list_repos "$org" 2>/dev/null); then
      combined=$(jq -s -c 'add | unique_by(.nameWithOwner)' <<<"$combined"$'\n'"$(normalize_repos <<<"$more")")
    fi
  done < <(gh api user/orgs --jq '.[].login' 2>/dev/null || true)

  if [[ $combined == '[]' ]]; then
    echo 'gh returned no repositories' >&2
    echo '[]'
    return 1
  fi

  printf '%s\n' "$combined"
}

cached=$(best_cache_repos)
count=$(jq 'length' <<<"$cached")

if (( SEED )); then
  if [[ $cached == '[]' ]]; then
    publish_menu '[]' 'cache is empty'
  else
    publish_menu "$cached"
  fi
  jq -nc --argjson count "$count" --arg cache "$CACHE_TMP" \
    '{ok: true, seeded: true, count: $count, cache: $cache}'
  exit 0
fi

fetch_err=$(mktemp)
trap 'rm -f -- "$fetch_err"' EXIT

if repos=$(fetch_repos 2>"$fetch_err"); then
  write_cache "$repos"
  publish_menu "$repos"
  count=$(jq 'length' <<<"$repos")
  jq -nc --argjson count "$count" --arg cache "$CACHE_TMP" \
    '{ok: true, count: $count, cache: $cache}'
  exit 0
fi

error=$(tr -d '\n' <"$fetch_err" 2>/dev/null || true)
error=${error:-fetch failed}

if [[ $cached != '[]' ]]; then
  publish_menu "$cached" "$error"
  jq -nc --argjson count "$count" --arg error "$error" \
    '{ok: true, count: $count, stale: true, error: $error}'
  exit 0
fi

publish_menu '[]' "$error"
jq -nc --arg error "$error" '{ok: false, error: $error}'
exit 1
