require "logger"
require "langchain/version"
if defined?(Rails::Engine)
  require "langchain/engine"
else
  # Outside a Rails app there's no engine to autoload the gem, so set up Zeitwerk with the
  # same acronyms as config/initializers/inflections.rb
  require "zeitwerk"

  loader = Zeitwerk::Loader.for_gem
  loader.ignore("#{__dir__}/langchainrb.rb", "#{__dir__}/langchain/engine.rb", "#{__dir__}/langchain/application_record.rb")
  loader.inflector.inflect(
    "ai21" => "AI21",
    "ai21_response" => "AI21Response",
    "csv" => "CSV",
    "google_vertexai" => "GoogleVertexAI",
    "html" => "HTML",
    "json" => "JSON",
    "jsonl" => "JSONL",
    "llm" => "LLM",
    "mistralai" => "MistralAI",
    "mistralai_message" => "MistralAIMessage",
    "mistralai_response" => "MistralAIResponse",
    "openai" => "OpenAI",
    "openai_message" => "OpenAIMessage",
    "openai_response" => "OpenAIResponse",
    "pdf" => "PDF"
  )
  loader.setup
end

module Langchain
  class << self
    # @return [Logger]
    attr_accessor :logger
    # @return [Pathname]
    attr_reader :root
  end

  module Errors
    class BaseError < StandardError; end
  end

  module Colorizer
    class << self
      def red(str)
        "\e[31m#{str}\e[0m"
      end

      def green(str)
        "\e[32m#{str}\e[0m"
      end

      def yellow(str)
        "\e[33m#{str}\e[0m"
      end

      def blue(str)
        "\e[34m#{str}\e[0m"
      end

      def colorize_logger_msg(msg, severity)
        return msg unless msg.is_a?(String)

        return red(msg) if severity.to_sym == :ERROR
        return yellow(msg) if severity.to_sym == :WARN
        msg
      end
    end
  end

  LOGGER_OPTIONS = {
    progname: "Langchain.rb",

    formatter: ->(severity, time, progname, msg) do
      Logger::Formatter.new.call(
        severity,
        time,
        "[#{progname}]",
        Colorizer.colorize_logger_msg(msg, severity)
      )
    end
  }.freeze

  self.logger ||= ::Logger.new($stdout, **LOGGER_OPTIONS)
  @root = Pathname.new(__dir__)
end
