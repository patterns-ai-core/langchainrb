# frozen_string_literal: true

require "logger"
require "pathname"
require "zeitwerk"
require "uri"
require "json"

loader = Zeitwerk::Loader.for_gem
loader.ignore("#{__dir__}/langchainrb.rb")
loader.ignore("#{__dir__}/langchain/assistants/llm")

loader.inflector.inflect(
  "ai21" => "AI21",
  "ai21_response" => "AI21Response",
  "ai21_validator" => "AI21Validator",
  "csv" => "CSV",
  "google_vertex_ai" => "GoogleVertexAI",
  "html" => "HTML",
  "json" => "JSON",
  "jsonl" => "JSONL",
  "llm" => "LLM",
  "mistral_ai" => "MistralAI",
  "mistral_ai_response" => "MistralAIResponse",
  "mistral_ai_message" => "MistralAIMessage",
  "openai" => "OpenAI",
  "openai_validator" => "OpenAIValidator",
  "openai_response" => "OpenAIResponse",
  "openai_message" => "OpenAIMessage",
  "pdf" => "PDF"
)
loader.collapse("#{__dir__}/langchain/llm/response")
loader.collapse("#{__dir__}/langchain/assistants")

loader.collapse("#{__dir__}/langchain/tool/calculator")
loader.collapse("#{__dir__}/langchain/tool/database")
loader.collapse("#{__dir__}/langchain/tool/docs_tool")
loader.collapse("#{__dir__}/langchain/tool/file_system")
loader.collapse("#{__dir__}/langchain/tool/google_search")
loader.collapse("#{__dir__}/langchain/tool/ruby_code_interpreter")
loader.collapse("#{__dir__}/langchain/tool/news_retriever")
loader.collapse("#{__dir__}/langchain/tool/tavily")
loader.collapse("#{__dir__}/langchain/tool/vectorsearch")
loader.collapse("#{__dir__}/langchain/tool/weather")
loader.collapse("#{__dir__}/langchain/tool/wikipedia")

# RubyCodeInterpreter does not work with Ruby 3.3;
# https://github.com/ukutaht/safe_ruby/issues/4
loader.ignore("#{__dir__}/langchain/tool/ruby_code_interpreter") if RUBY_VERSION >= "3.3.0"

loader.setup

# Langchain.rb a is library for building LLM-backed Ruby applications. It is an abstraction layer that sits on top of the emerging AI-related tools that makes it easy for developers to consume and string those services together.
#
# = Installation
# Install the gem and add to the application's Gemfile by executing:
#
#     $ bundle add langchainrb
#
# If bundler is not being used to manage dependencies, install the gem by executing:
#
#     $ gem install langchainrb
#
# Require the gem to start using it:
#
#     require "langchain"
#
# = Concepts
#
# == Processors
# Processors load and parse/process various data types such as CSVs, PDFs, Word documents, HTML pages, and others.
#
# == Chunkers
# Chunkers split data based on various available options such as delimeters, chunk sizes or custom-defined functions. Chunkers are used when data needs to be split up before being imported in vector databases.
#
# == Prompts
# Prompts are structured inputs to the LLMs. Prompts provide instructions, context and other user input that LLMs use to generate responses.
#
# == Large Language Models (LLMs)
# LLM is a language model consisting of a neural network with many parameters (typically billions of weights or more), trained on large quantities of unlabeled text using self-supervised learning or semi-supervised learning.
#
# == Vectorsearch Databases
# Vector database is a type of database that stores data as high-dimensional vectors, which are mathematical representations of features or attributes. Each vector has a certain number of dimensions, which can range from tens to thousands, depending on the complexity and granularity of the data.
#
# == Embedding
# Word embedding or word vector is an approach with which we represent documents and words. It is defined as a numeric vector input that allows words with similar meanings to have the same representation. It can approximate meaning and represent a word in a lower dimensional space.
#
#
# = Logging
#
# Langchain.rb uses standard logging mechanisms and defaults to :debug level. Most messages are at info level, but we will add debug or warn statements as needed. To show all log messages:
#
# Langchain.logger.level = :info
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
