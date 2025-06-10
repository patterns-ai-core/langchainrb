require "logger"
require "langchain/version"
require "langchain/engine"

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
