# Logging and Monitoring

## Logs

All Lambda functions write to CloudWatch Logs (`/aws/lambda/pasta-atlas-production-{app,s3-cleanup,task}`, 30-day retention). The application logs JSON lines to standard output at `INFO` and above; Lambda adds `START`, `END` and `REPORT` lines, and Puma and the Web Adapter write their own startup lines.

| Field | Meaning |
|---|---|
| `severity`, `time`, `progname` | Level, UTC time, `pasta_atlas` |
| `verb`, `path`, `status`, `length` | Request line, response status, request body size |
| `ip` | Client address (the first `X-Forwarded-For` value) |
| `elapsed`, `elapsed_unit` | Handling time, in microseconds |

Policy:

- **Request parameters are not logged.** Hanami adds them to every request entry; for uploads that is the whole `mapshot.json` and up to 200 file names. `PastaAtlas::Logging::ProductionFormatter` drops `params` in production. Follow a request through its path (maps and uploads carry their ULID there) and status.
- **The client IP address is logged**, because abuse cannot be investigated without it. The privacy policy states that access logs are kept for 30 days.
- Exceptions are logged at `ERROR` with the same request fields. Match them with the Lambda `RequestId` in the surrounding `START` and `END` lines.
- Secrets are never logged. `_csrf`, `password` and `password_confirmation` are filtered by Hanami as an extra guard.

Development and test keep Hanami's readable output, including the parameters.

## Reading the logs

```bash
env -u AWS_ENDPOINT_URL AWS_PROFILE=terraform aws logs tail /aws/lambda/pasta-atlas-production-app --since 1h
```

Use `aws logs filter-log-events` with `--filter-pattern '"\"status\":500"'` to find failed requests.

## Alarms

Every alarm notifies the `pasta-atlas-production-alarms` SNS topic, which emails `alarm_email` when it is set (each subscription must be confirmed once). CloudFront reports its metrics in us-east-1, and an alarm can only notify a topic of its own region, so that alarm uses a second topic with the same name in us-east-1 and a second subscription.

| Alarm | Metric | Condition (5 minutes) |
|---|---|---|
| `…-s3-cleanup-dlq-not-empty` | SQS `ApproximateNumberOfMessagesVisible` of the dead-letter queue | above 0 |
| `…-app-errors` | Lambda `Errors` of the `app` function | above 0 |
| `…-app-throttles` | Lambda `Throttles` of the `app` function | above 0 |
| `…-task-errors` | Lambda `Errors` of the `task` function (migration, seed, map deletion, scheduled cleanup) | above 0 |
| `…-app-5xx-rate` | CloudFront `5xxErrorRate` of the application distribution | 5% or more |

`Errors` counts unhandled exceptions and timeouts. A 500 that Puma returns normally is not an invocation error, so the CloudFront alarm is the one that sees it. With little traffic a single failed request exceeds 5%, which is intended. Missing data counts as healthy, so an idle site does not alarm.

Not monitored yet: the `s3-cleanup` function's errors, RDS connections and free storage, and the NAT instance.
