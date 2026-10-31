# frozen_string_literal: true

require "faraday"
require "mcp"
require "securerandom"
require "timeout"
require "uri"

module Langchain::Tool
  # Keyless web search and page fetching through Parallel Search MCP.
  # Assistants supply their conversation ID; related standalone calls can pass
  # the same opaque session_id explicitly instead of starting a new research run.
  class ParallelSearch
    extend Langchain::ToolDefinition

    ENDPOINT = "https://search.parallel.ai/mcp"

    class RequestTimeout < Timeout::Error; end
    private_constant :RequestTimeout

    define_function :search, description: "Search current web sources and return excerpts and source URLs" do
      property :objective, type: "string", description: "The information to find", required: true
      property :search_queries, type: "array", description: "Related keyword queries, 3-6 words each", required: true do
        item type: "string"
      end
    end

    define_function :fetch, description: "Read specific web pages when search excerpts are insufficient" do
      property :urls, type: "array", description: "HTTP or HTTPS URLs to read (up to 20)", required: true do
        item type: "string"
      end
      property :objective, type: "string", description: "What to find in the pages (up to 200 characters)"
      property :search_queries, type: "array", description: "Queries used to find these URLs" do
        item type: "string"
      end
      property :full_content, type: "boolean", description: "Return full page markdown instead of focused excerpts"
    end

    # @param timeout [Numeric] Total request budget in seconds, plus at most one second for cleanup.
    def initialize(timeout: 30)
      unless timeout.is_a?(Numeric) && timeout.finite? && timeout.positive?
        raise ArgumentError, "timeout must be a finite positive number"
      end
      @timeout = timeout
    end

    # @return [Langchain::ToolResponse] Search excerpts with source URLs, or an explicit service error.
    def search(objective:, search_queries:, session_id: SecureRandom.uuid)
      validate_text!(objective, "objective")
      validate_queries!(search_queries)
      call_tool("web_search", {objective: objective, search_queries: search_queries}, session_id)
    end

    # @return [Langchain::ToolResponse] Page excerpts/markdown, or an explicit service error.
    def fetch(urls:, objective: nil, search_queries: nil, full_content: false, session_id: SecureRandom.uuid)
      unless urls.is_a?(Array) && urls.size.between?(1, 20) && urls.all? { |url| http_url?(url) }
        raise ArgumentError, "urls must contain 1-20 HTTP or HTTPS URLs"
      end
      if objective
        validate_text!(objective, "objective")
        raise ArgumentError, "objective must be at most 200 characters" if objective.length > 200
      end
      validate_queries!(search_queries) if search_queries
      unless [true, false].include?(full_content)
        raise ArgumentError, "full_content must be a boolean"
      end
      call_tool("web_fetch", {urls: urls, objective: objective, search_queries: search_queries, full_content: full_content}.compact, session_id)
    end

    private

    def call_tool(name, arguments, session_id)
      validate_text!(session_id, "session_id")
      raise ArgumentError, "session_id must be at most 100 characters" if session_id.length > 100

      # This version identifies the Langchain.rb Parallel adapter, independently of the gem release.
      transport = MCP::Client::HTTP.new(
        url: ENDPOINT,
        headers: {"User-Agent" => "langchainrb-parallel-search/1.0"},
        max_reconnection_wait: @timeout
      ) do |connection|
        connection.options.timeout = @timeout
        connection.options.open_timeout = @timeout
      end

      Timeout.timeout(@timeout, RequestTimeout) do
        client = MCP::Client.new(transport: transport)
        client.connect(client_info: {name: "langchainrb", version: Langchain::VERSION}, protocol_version: "2025-03-26", mode: :legacy)
        tool = client.tools.find { |available| available.name == name }
        raise MCP::Client::ValidationError, "Server does not offer #{name}" unless tool

        response = client.call_tool(tool: tool, arguments: arguments.merge(session_id: session_id))
        result = response["result"]
        unless result.is_a?(Hash) && result["content"].is_a?(Array)
          raise MCP::Client::ValidationError, "Server returned invalid tool content"
        end
        content = result["content"].filter_map { |block| block["text"] if block.is_a?(Hash) && block["type"] == "text" && block["text"].is_a?(String) }.join("\n")
        raise MCP::Client::ValidationError, "Server returned no text content" if content.empty?

        tool_response(content: result["isError"] ? "Parallel Search error: #{content}" : content)
      end
    rescue MCP::Client::ServerError, MCP::Client::RequestHandlerError, MCP::Client::ValidationError, RequestTimeout, JSON::ParserError, Faraday::Error => e
      tool_response(content: "Parallel Search error: #{e.message}")
    ensure
      if transport
        begin
          Timeout.timeout([@timeout, 1].min, RequestTimeout) { transport.close }
        rescue RequestTimeout, Faraday::Error, MCP::Client::RequestHandlerError => e
          Langchain.logger.warn("Parallel Search connection cleanup failed: #{e.class}")
        end
      end
    end

    def validate_text!(value, name)
      raise ArgumentError, "#{name} must be a nonempty string" unless value.is_a?(String) && !value.strip.empty?
    end

    def validate_queries!(queries)
      unless queries.is_a?(Array) && !queries.empty? && queries.all? { |query| query.is_a?(String) && !query.strip.empty? }
        raise ArgumentError, "search_queries must contain nonempty strings"
      end
    end

    def http_url?(value)
      return false unless value.is_a?(String)
      uri = URI.parse(value)
      %w[http https].include?(uri.scheme) && uri.host && !uri.userinfo
    rescue URI::InvalidURIError
      false
    end
  end
end
