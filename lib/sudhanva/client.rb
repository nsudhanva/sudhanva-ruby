# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module Sudhanva
  Response = Struct.new(:status, :headers, :body, keyword_init: true)

  class APIError < StandardError
    attr_reader :status, :code, :body

    def initialize(status:, code:, message:, body:)
      super("#{status} #{code}: #{message}")
      @status = status
      @code = code
      @body = body
    end
  end

  class Client
    DEFAULT_BASE_URL = "https://sudhanva.me/api/v1"
    USER_AGENT = "sudhanva-ruby/#{VERSION}"

    def initialize(base_url: DEFAULT_BASE_URL, timeout: 10, transport: nil)
      raise ArgumentError, "timeout must be positive" unless timeout.positive?

      @base_url = base_url.sub(%r{/+\z}, "")
      parsed = URI.parse(@base_url)
      unless %w[http https].include?(parsed.scheme) && parsed.host
        raise ArgumentError, "base_url must be an absolute HTTP(S) URL"
      end

      @site_url = "#{parsed.scheme}://#{parsed.host}#{":#{parsed.port}" unless parsed.default_port == parsed.port}"
      @timeout = timeout
      @transport = transport || method(:default_transport)
    end

    def profile(locale: "en")
      request("GET", "/profile", query: { locale: locale })
    end

    def posts(limit: 20, tag: nil, cursor: nil)
      raise ArgumentError, "limit must be between 1 and 100" unless (1..100).cover?(limit)

      request("GET", "/posts", query: { limit: limit, tag: tag, cursor: cursor })
    end

    def post(slug)
      raise ArgumentError, "slug is required" if slug.to_s.empty?

      request("GET", "/posts/#{URI.encode_www_form_component(slug)}")
    end

    def batch(operations)
      raise ArgumentError, "operations must contain between 1 and 20 items" unless (1..20).cover?(operations.length)

      request("POST", "/batch", json: { operations: operations })
    end

    def create_profile_insight(audience:, idempotency_key:, focus: nil)
      raise ArgumentError, "idempotency_key is required" if idempotency_key.to_s.empty?

      payload = { audience: audience }
      payload[:focus] = focus if focus
      request(
        "POST",
        "/profile-insights",
        headers: { "Idempotency-Key" => idempotency_key },
        json: payload
      )
    end

    def profile_insight(job_id)
      raise ArgumentError, "job_id is required" if job_id.to_s.empty?

      request("GET", "/profile-insights/#{URI.encode_www_form_component(job_id)}")
    end

    def wait_for_profile_insight(job_id, timeout: 30, poll_interval: 1)
      unless timeout.positive? && poll_interval >= 0
        raise ArgumentError, "timeout must be positive and poll_interval cannot be negative"
      end

      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
      loop do
        job = profile_insight(job_id)
        return job if %w[succeeded failed].include?(job["status"])
        if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
          raise Timeout::Error, "profile insight #{job_id} did not finish within #{timeout}s"
        end

        sleep(poll_interval)
      end
    end

    def ask(text, limit: 10, mode: "list")
      raise ArgumentError, "text is required" if text.to_s.empty?
      raise ArgumentError, "limit must be between 1 and 20" unless (1..20).cover?(limit)

      request(
        "POST",
        "/ask",
        base: @site_url,
        json: {
          query: { text: text, site: @site_url, limit: limit },
          prefer: { streaming: false, response_format: "conversational_search", mode: mode },
          meta: { version: "0.55" }
        }
      )
    end

    private

    def request(method, path, query: {}, headers: {}, json: nil, base: @base_url)
      uri = URI.parse("#{base.sub(%r{/+\z}, "")}/#{path.sub(%r{\A/+}, "")}")
      query = query.reject { |_, value| value.nil? }
      uri.query = URI.encode_www_form(query) unless query.empty?

      request_headers = { "Accept" => "application/json", "User-Agent" => USER_AGENT }.merge(headers)
      body = nil
      if json
        request_headers["Content-Type"] = "application/json"
        body = JSON.generate(json)
      end

      response = @transport.call(method, uri, request_headers, body, @timeout)
      payload = response.body.to_s.empty? ? {} : JSON.parse(response.body)
      unless response.status.between?(200, 299)
        error = payload.fetch("error", payload)
        code = error.fetch("code", payload.fetch("code", "api_error"))
        message = error.fetch("message", payload.fetch("message", "Request failed"))
        raise APIError.new(status: response.status, code: code, message: message, body: payload)
      end

      raise APIError.new(status: response.status, code: "invalid_response", message: "API returned a non-object response", body: payload) unless payload.is_a?(Hash)

      payload
    rescue JSON::ParserError => error
      raise APIError.new(status: response&.status || 0, code: "invalid_response", message: "API returned invalid JSON", body: nil), cause: error
    end

    def default_transport(method, uri, headers, body, timeout)
      request_class = method == "POST" ? Net::HTTP::Post : Net::HTTP::Get
      http_request = request_class.new(uri, headers)
      http_request.body = body if body
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = timeout
      http.read_timeout = timeout
      result = http.request(http_request)
      Response.new(status: result.code.to_i, headers: result.to_hash, body: result.body.to_s)
    end
  end
end
