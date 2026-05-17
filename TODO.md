# TODO

## Design (doc/design/)

- [ ] CI/CD pipeline — GitHub Actions workflow structure
- [ ] Terraform details — S3 bucket policy, CloudFront distribution configuration
- [ ] DB migrations — repeatable production migration process (initial schema creation and ongoing schema updates via ECS one-off task)
- [ ] Logging / observability — log output policy

## Implementation

- [ ] Serve static assets via CloudFront — place CloudFront in front of the Hanami app and add a `/assets/*` behaviour with a long cache TTL; safe because Vite fingerprints asset filenames with a content hash, so each deploy produces new URLs; HTML responses must use a short TTL or `no-cache` to always reflect the latest asset URLs
