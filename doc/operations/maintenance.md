# Maintenance Mode

## Overview

Maintenance mode answers requests to `pasta-atlas.app` with a fixed 503 response, except for requests from allowed IP addresses. It is switched with the `ops:maintenance:*` mise tasks and needs no deployment.

A CloudFront Function (`pasta-atlas-production-maintenance`, `cloudfront-js-2.0`, viewer request) runs on the default behavior of the `app` distribution, which forwards to the Lambda Function URL. `/assets/*` and the `mapshots` distribution (tiles) are not affected. The function reads its settings from a CloudFront KeyValueStore of the same name; while maintenance mode is off, it reads one key per request.

The code is in `terraform/production/functions/`. Terraform builds the function from `maintenance.js` followed by `const PAGE = <maintenance.html as a JSON string>;` and `const CANONICAL_HOST = <app_domain_name>;`, so the page can be edited and opened in a browser as plain HTML. Before the maintenance check, the function redirects requests for any other host to `CANONICAL_HOST`; see [Infrastructure](infrastructure.md#app--application-domain-pasta-atlasapp). Terraform creates the store but not its keys, which change at run time.

## Keys

| Key | Meaning | When absent |
|---|---|---|
| `maintenance` | `on` turns maintenance mode on; any other value is off | Off |
| `allow_ips` | Comma-separated viewer IP addresses that pass through, matched exactly (no CIDR) | Nobody passes |
| `message` | The message, in English | `Pasta Atlas is down for maintenance. Please check back later.` |
| `ends_at` | Expected end, ISO 8601 with a time zone | No end time is shown |

## Tasks

| Task | Effect |
|---|---|
| `mise run ops:maintenance:on [--ends-at <time>] [--message <text>]` | Sets `maintenance=on`, and `message` and `ends_at` from the flags; a flag that is not given deletes its key, so nothing is left from an earlier maintenance. Fails when maintenance mode is already on |
| `mise run ops:maintenance:set [--ends-at <time> \| --clear-ends-at] [--message <text> \| --clear-message]` | While maintenance mode is on, changes only the given settings, e.g. to extend the end time. Fails when it is off |
| `mise run ops:maintenance:off` | Deletes all four keys. Running it again changes nothing |
| `mise run ops:maintenance:allow <ip>` | Adds an address to `allow_ips` |
| `mise run ops:maintenance:deny <ip>` | Removes an address from `allow_ips` |
| `mise run ops:maintenance:status` | Shows whether maintenance mode is on and every key |

A typical maintenance:

```bash
mise run ops:maintenance:allow 203.0.113.10
mise run ops:maintenance:on --ends-at 2026-11-24T15:00+09:00 --message "Upgrading the database."
# ...
mise run ops:maintenance:set --ends-at 2026-11-24T16:00+09:00   # it takes longer
# ...
mise run ops:maintenance:off
```

- The tasks use the `terraform` AWS profile and need `jq` and GNU `date`.
- `--ends-at` must match `YYYY-MM-DDThh:mm[:ss[.sss]]` followed by `Z` or `±hh:mm`, and be a real date and time. Otherwise the task stops before changing anything. A time in the past is accepted with a warning.
- `on` warns when `allow_ips` is empty.
- `off` also deletes `allow_ips`, because the allowed addresses are usually those of a dynamic connection.
- The address to allow is the one CloudFront sees. The distribution accepts IPv6, so it may be an IPv6 address.
- Each task changes the keys with one `UpdateKeys` call, which applies all changes or none, with the store's ETag. When the store changed after the task read it, the call fails; run the task again.
- A change reaches the edge servers one by one. After `off` in production, some requests still got the maintenance page for about a minute. Wait about a minute after `on` before starting the work, and expect the same after `off` and `set`.

## Response

Every response from maintenance mode is `503 Service Unavailable` with `Cache-Control: no-store`. When `ends_at` is in the future, `Retry-After` gives the seconds until it.

- A URI under `/api/` gets JSON: `{"error":"maintenance","message":…,"ends_at":…}`, with `ends_at` as stored or `null`.
- Any other URI gets the HTML page with the message (HTML-escaped) and the end time. A script shows the end time in the viewer's time zone; without JavaScript the ISO 8601 text stays. The end time is still shown after it has passed. An `ends_at` outside the format the tasks accept is treated as absent: the function parses that format itself, because `Date.parse` in CloudFront Functions rejects values with an offset such as `+09:00`.

## What it does not stop

Maintenance mode only stops requests that come through CloudFront. Requests that bypass it are already rejected at the Function URL ([origin protection](lambda.md#origin-protection)). The following keep running, so pause them separately when the maintenance needs that:

- The `s3-cleanup` function, triggered by SQS
- The [scheduled cleanup](lambda.md#scheduled-cleanup)
- Tasks run through the `task` function, by the workflows or `ops:seed`
