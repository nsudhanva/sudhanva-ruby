# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/sudhanva"

class FakeTransport
  attr_reader :requests

  def initialize(*responses)
    @responses = responses
    @requests = []
  end

  def call(method, uri, headers, body, timeout)
    @requests << [method, uri, headers, body, timeout]
    @responses.shift
  end
end

class SudhanvaClientTest < Minitest::Test
  def response(status, payload)
    Sudhanva::Response.new(status: status, headers: {}, body: JSON.generate(payload))
  end

  def test_gemspec_and_user_agent_share_one_version
    specification = Gem::Specification.load(File.expand_path("../sudhanva.gemspec", __dir__))

    assert_equal Sudhanva::VERSION, specification.version.to_s
    assert_equal "sudhanva-ruby/#{Sudhanva::VERSION}", Sudhanva::Client::USER_AGENT
  end

  def test_posts_encodes_filters_and_identifies_client
    transport = FakeTransport.new(response(200, "posts" => []))
    client = Sudhanva::Client.new(base_url: "https://example.test/api/v1", transport: transport)

    assert_equal({ "posts" => [] }, client.posts(limit: 5, tag: "machine-learning"))

    method, uri, headers, body, timeout = transport.requests.first
    assert_equal "GET", method
    assert_equal "https://example.test/api/v1/posts?limit=5&tag=machine-learning", uri.to_s
    assert_equal "sudhanva-ruby/0.2.0", headers["User-Agent"]
    assert_nil body
    assert_equal 10, timeout
  end

  def test_profile_insight_sends_idempotency_key
    transport = FakeTransport.new(response(202, "job_id" => "pi_1", "status" => "queued"))
    client = Sudhanva::Client.new(transport: transport)

    client.create_profile_insight(
      audience: "agent",
      focus: ["production-ml"],
      idempotency_key: "ruby-test-123"
    )

    method, _uri, headers, body, = transport.requests.first
    assert_equal "POST", method
    assert_equal "ruby-test-123", headers["Idempotency-Key"]
    assert_equal({ "audience" => "agent", "focus" => ["production-ml"] }, JSON.parse(body))
  end

  def test_wait_stops_at_terminal_state
    transport = FakeTransport.new(
      response(200, "status" => "running"),
      response(200, "status" => "succeeded", "result" => { "summary" => "done" })
    )
    client = Sudhanva::Client.new(transport: transport)

    job = client.wait_for_profile_insight("pi_test", timeout: 1, poll_interval: 0)

    assert_equal "succeeded", job["status"]
    assert_equal 2, transport.requests.length
  end

  def test_ask_uses_site_root
    transport = FakeTransport.new(response(200, "results" => []))
    client = Sudhanva::Client.new(base_url: "https://example.test/api/v1", transport: transport)

    client.ask("Kubernetes", limit: 3, mode: "summarize")

    _method, uri, _headers, body, = transport.requests.first
    assert_equal "https://example.test/ask", uri.to_s
    assert_equal 3, JSON.parse(body).dig("query", "limit")
    assert_equal "summarize", JSON.parse(body).dig("prefer", "mode")
  end

  def test_structured_errors_are_exposed
    transport = FakeTransport.new(
      response(404, "error" => { "code" => "not_found", "message" => "Missing" })
    )
    client = Sudhanva::Client.new(transport: transport)

    error = assert_raises(Sudhanva::APIError) { client.post("missing") }
    assert_equal 404, error.status
    assert_equal "not_found", error.code
  end
end
