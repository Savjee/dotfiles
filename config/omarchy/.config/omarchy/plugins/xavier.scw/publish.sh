#!/usr/bin/env bash
# Publish hardcoded Scaleway console services into the Omarchy menu.

set -euo pipefail

PLUGIN_ID=xavier.scw
PLUGIN_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SERVICES_PATH=$PLUGIN_DIR/services.json
MENU_PATH=$HOME/.config/omarchy/extensions/omarchy-menu.jsonc
SCW_ICON=$'\uf0c2'

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
  tmp=$(mktemp --tmpdir="$dir" -- ".$(basename -- "$path").XXXXXX")
  cat >"$tmp"
  mv -f -- "$tmp" "$path"
}

user_menu_items() {
  if [[ ! -f $MENU_PATH ]]; then
    echo '{}'
    return
  fi
  strip_jsonc <"$MENU_PATH" | jq -c '
    if type != "object" then {}
    elif ((.items | type) == "object") and ((.scw | type) != "object") then .items
    else . end
    | with_entries(select(
        (.value | type) == "object"
        and .key != "scw"
        and (.key | startswith("scw.") | not)
        and (.key | startswith("scwsvc-") | not)
      ))
  '
}

managed_items() {
  jq -nc --argjson services "$(jq -c '.services // []' "$SERVICES_PATH")" --arg icon "$SCW_ICON" -f /dev/stdin <<'JQ'
def slugify:
  ascii_downcase | gsub("[^a-z0-9]+"; "-") | gsub("^-+"; "") | gsub("-+$"; "")
  | if . == "" then "item" else . end;

def unique_id($base; $taken):
  if $taken[$base] then unique_id($base + "-dup"; $taken) else $base end;

def shell_quote:
  "'" + gsub("'"; "'\\''") + "'";

def action:
  "omarchy-launch-browser " + (.url | shell_quote);

{
  scw: {
    icon: $icon,
    label: "Scaleway",
    aliases: ["scw"],
    description: "Search Scaleway console services",
    when: "false"
  }
} as $base
| ($services | map(.name) | group_by(.) | map({key: .[0], value: length}) | from_entries) as $counts
| reduce $services[] as $svc (
    {items: $base, taken: {"scw": true}};
    ($svc.id // ($svc.name | slugify)) as $id
    | ($svc.name) as $name
    | ($svc.category // "Scaleway") as $category
    | (if ($counts[$name] // 0) == 1 then $name else "\($name) (\($category))" end) as $browse_label
    | unique_id("scw.\($id)"; .taken) as $item_id
    | (($svc.aliases // []) + [$id] | unique) as $aliases
    | .items += {
        ($item_id): {
          icon: $icon,
          label: $browse_label,
          aliases: (["scw"] + $aliases),
          description: ($svc.description // ""),
          action: ($svc | action)
        }
      }
    | .taken += {($item_id): true}
  )
| .items
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

if [[ ! -f $SERVICES_PATH ]]; then
  jq -nc '{ok: false, error: "services.json is missing"}'
  exit 1
fi

user_items=$(user_menu_items)
generated=$(managed_items)
text=$(dump_jsonc "$user_items" "$generated")
if [[ ! -f $MENU_PATH || $(cat -- "$MENU_PATH") != "$text" ]]; then
  atomic_write "$MENU_PATH" <<<"$text"
fi

count=$(jq '.services | length' "$SERVICES_PATH")
jq -nc --argjson count "$count" '{ok: true, count: $count}'
