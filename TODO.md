# TODO

## Design (doc/design/)

- [ ] Authentication flow — guest-to-logged-in transition, session lifecycle
- [ ] Development environment setup — `bin/setup`, required environment variables
- [ ] CI/CD pipeline — GitHub Actions workflow structure
- [ ] Terraform details — S3 bucket policy, CloudFront distribution configuration
- [ ] DB migrations — ROM::Migrations usage and operational conventions
- [ ] Logging / observability — log output policy

## Implementation

- [ ] User registration — create `users` and `user_profiles` in a single transaction; every user must have a profile
