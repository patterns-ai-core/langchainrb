# frozen_string_literal: true

module Langchain
  class ContextualLogger
    MESSAGE_COLOR_OPTIONS = {
      debug: {
        color: :white
      },
      error: {
        color: :red
      },
      fatal: {
        color: :red,
        background: :white,
        mode: :bold
      },
      unknown: {
        color: :white
      },
      info: {
        color: :white
      },
      warn: {
        color: :yellow,
        mode: :bold
      }
    }

    def initialize(logger)
      @logger = logger
      @levels = Logger::Severity.constants.map(&:downcase)
    end

    def respond_to_missing?(method, include_private = false)
      @logger.respond_to?(method, include_private)
    end

    def method_missing(method, *args, **kwargs, &block)
      return @logger.send(method, *args, **kwargs, &block) unless @levels.include?(method)

      for_class = kwargs.delete(:for)
      for_class_name = for_class&.name

      log_line_parts = []
      log_line_parts << colorize("[Langchain.rb]", color: :yellow)
      log_line_parts << if for_class.respond_to?(:logger_options)
        colorize("[#{for_class_name}]", for_class.logger_options) + ":"
      elsif for_class_name
        "[#{for_class_name}]:"
      end
      log_line_parts << colorize(args.first, MESSAGE_COLOR_OPTIONS[method])
      log_line = log_line_parts.compact.join(" ")

      @logger.send(
        method,
        log_line
      )
    end

    private

    def colorize(line, options)
      Langchain::Utils::Colorizer.colorize(line, options)
    end
  end
end
