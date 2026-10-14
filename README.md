# sudhanva for Ruby

This is a small Ruby client for the public [sudhanva.me API](https://sudhanva.me/openapi.json).
It has no dependencies. Use it to get the published profile and article metadata, to read items in
batches of a limited size, and to search the published site. You can also use it to create and poll
temporary profile-insight jobs.

The API is public. It does not need credentials. Do not send private data to it.

## Install

You must have Ruby 3.3 or a later version.

```bash
gem install sudhanva --version 0.2.0
```

You can also add it to a `Gemfile`:

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

All methods return decoded JSON hashes.

If a response is not a success, the client raises `Sudhanva::APIError`. This error has the fields
`status`, `code`, `hint`, `docs_url`, and the decoded response body. The exception message contains
the explanation from the API.

The profile-insight endpoints can send an RFC 9457 problem response. For this type of response,
the client puts `detail` (or `title`) in the message. It puts the last segment of `type` in `code`.

## API coverage

- `profile`
- `posts` and `post`
- `batch`
- `create_profile_insight`, `profile_insight`, and `wait_for_profile_insight`
- `ask` for NLWeb conversational search

The client uses the stable `/api/v1` contract. For more information, read the
[developer documentation](https://sudhanva.me/developers/sdks/) and the
[versioning policy](https://sudhanva.me/developers/versioning/).

## Development

```bash
bundle install
bundle exec rake test
gem build sudhanva.gemspec
```

The test suite uses an injected transport. It does not call production.

## License

MIT
