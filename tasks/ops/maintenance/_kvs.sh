# Helpers sourced by the ops:maintenance:* tasks. The file is not executable, so mise does not
# list it as a task.

KVS_NAME=pasta-atlas-production-maintenance

kvs_use_production() {
  # The development environment points the AWS CLI at Floci.
  unset AWS_ENDPOINT_URL
  export AWS_PROFILE=terraform
}

# Sets KVS_ARN, KVS_ETAG and KVS_ITEMS (the keys as one JSON object).
# The ETag is read before the keys: a change in between then makes update-keys fail instead of
# acting on keys that are already stale.
kvs_load() {
  KVS_ARN=$(aws cloudfront describe-key-value-store --name "$KVS_NAME" \
    --query KeyValueStore.ARN --output text)
  KVS_ETAG=$(aws cloudfront-keyvaluestore describe-key-value-store --kvs-arn "$KVS_ARN" \
    --query ETag --output text)
  KVS_ITEMS=$(aws cloudfront-keyvaluestore list-keys --kvs-arn "$KVS_ARN" --output json |
    jq -c '(.Items // []) | map({(.Key): .Value}) | add // {}')
}

# Prints {"puts": [...], "deletes": [...]} for update-keys.
# $1: the current keys; $2: the wanted keys, where null or "" means absent.
# Absent keys are deleted only when they exist, so the call does not depend on how UpdateKeys
# treats deleting a missing key.
kvs_plan() {
  jq -cn --argjson current "$1" --argjson wanted "$2" '
    [$wanted | to_entries[] | .absent = (.value == null or .value == "")] as $entries
    | {
        puts: [$entries[] | select((.absent | not) and $current[.key] != .value) | {Key: .key, Value: .value}],
        deletes: [$entries[] | .key as $key | select(.absent and ($current | has($key))) | {Key: $key}]
      }'
}

# Changes the keys to those in $1 (as for kvs_plan) with one UpdateKeys call. It applies all puts
# and deletes or none, so no request sees half a change.
kvs_update() {
  local plan puts deletes
  # Assigned on their own lines so that set -e stops on a failure.
  plan=$(kvs_plan "$KVS_ITEMS" "$1")
  puts=$(jq -c .puts <<<"$plan")
  deletes=$(jq -c .deletes <<<"$plan")
  if [ "$puts" = "[]" ] && [ "$deletes" = "[]" ]; then
    echo "Nothing to change."
    return
  fi

  local args=(--kvs-arn "$KVS_ARN" --if-match "$KVS_ETAG" --output json)
  [ "$puts" = "[]" ] || args+=(--puts "$puts")
  [ "$deletes" = "[]" ] || args+=(--deletes "$deletes")
  aws cloudfront-keyvaluestore update-keys "${args[@]}" >/dev/null
}

# Prints the value of a key, or nothing when it is absent.
kvs_get() {
  jq -r --arg key "$1" '.[$key] // empty' <<<"$KVS_ITEMS"
}

# The function compares allow_ips entries with the viewer IP as text, so a host name or a CIDR
# would never match.
kvs_validate_ip() {
  if ! [[ "$1" =~ ^[0-9A-Fa-f:.]+$ ]]; then
    echo "Not an IPv4 or IPv6 address: $1" >&2
    return 1
  fi
}

# Only .sss is accepted for fractions of a second: Date.parse, in the function and in the browser,
# is defined only for the ECMAScript date time string format.
# `date -d` needs GNU date; BSD date (macOS) has no -d for parsing.
kvs_validate_ends_at() {
  local pattern='^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}(:[0-9]{2}(\.[0-9]{3})?)?(Z|[+-][0-9]{2}:[0-9]{2})$'
  if ! [[ "$1" =~ $pattern ]] || ! date -d "$1" >/dev/null 2>&1; then
    echo "--ends-at must be ISO 8601 with a time zone, e.g. 2026-11-24T15:00+09:00 or 2026-11-24T06:00Z: $1" >&2
    return 1
  fi
}

# Prints allow_ips with an address added (+) or removed (-), keeping the order and no duplicates.
# $1: + or -; $2: the address.
kvs_edit_allow_ips() {
  jq -r --arg op "$1" --arg ip "$2" '
    [(.allow_ips // "") | split(",")[] | gsub("^\\s+|\\s+$"; "") | select(. != "")]
    | if $op == "+" then . + [$ip] else map(select(. != $ip)) end
    | reduce .[] as $x ([]; if any(.[]; . == $x) then . else . + [$x] end)
    | join(",")' <<<"$KVS_ITEMS"
}
