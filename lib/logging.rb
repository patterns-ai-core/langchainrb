# frozen_string_literal: true

require "logger"

module Langchain
  def self.logger
    @@logger ||= Logger.new($stdout, level: :warn, formatter: ->(severity, datetime, progname, msg) { "[LangChain.rb] #{msg}\n" })
  end

  def self.logger=(instance)
    @@logger = instance
  end
end
