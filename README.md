# sudhanva for Ruby

Minimal, dependency-free Ruby client for the public
[sudhanva.me API](https://sudhanva.me/openapi.json). It retrieves published profile and article
metadata, performs bounded batch reads, searches the published site, and creates or polls temporary
profile-insight jobs.

The API is public and requires no credentials. Do not send private data.

## Install

```bash
gem install sudhanva --version 0.2.0
```

Or add it to a `Gemfile`:

```ruby
gem "sudhanva", "~> 0.2.0"
```

## Use

```ruby
require "sudhanva"

client = Sudhanva::Client.new

profile = client.profile
posts = client.posts(limit: 5, tag: "kubernetes")
article = client.post("making-your-site-agent-friendly")

job = client.create_profile_insight(
  audience: "hiring-manager",
  focus: ["production-ml", "inference"],
  idempotency_key: "my-workflow-2026-08-23"
)
result = client.wait_for_profile_insight(job["job_id"])
```

All methods return decoded JSON hashes. Non-success responses raise `Sudhanva::APIError` with
`status`, `code`, and the decoded response body.

## API coverage

- `profile`
- `posts` and `post`
- `batch`
- `create_profile_insight`, `profile_insight`, and `wait_for_profile_insight`
- `ask` for NLWeb conversational search

The client follows the stable `/api/v1` contract. See the
[developer documentation](https://sudhanva.me/developers/sdks/) and
[versioning policy](https://sudhanva.me/developers/versioning/).

## Development

```bash
bundle install
bundle exec rake test
gem build sudhanva.gemspec
```

The test suite uses an injected transport and never calls production.

## License

MIT
