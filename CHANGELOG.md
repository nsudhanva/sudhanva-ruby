# Changelog

## 0.2.0 — 2026-10-01

- Requires Ruby 3.3 or newer. Tested on Ruby 3.3, 3.4, and 4.0.
- Error responses in RFC 9457 problem format, which the profile-insight endpoints return, now report their `detail` and `type` instead of a generic "Request failed".
- `APIError` exposes `hint` and `docs_url` from the standard error envelope.
- Unexpected error bodies, such as a JSON array or a string `error`, raise `APIError` instead of `NoMethodError`.
- `Sudhanva::VERSION`, the gemspec, and the `User-Agent` header report the same version.
- Releases publish to RubyGems.org from GitHub Actions through trusted publishing.

## 0.1.0 — 2026-08-24

- First release: profile, articles, search, batch reads, and profile-insight jobs.
