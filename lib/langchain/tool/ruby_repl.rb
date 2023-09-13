require "stringio"

require "pry-byebug"

module Langchain::Tool
  class RubyREPL < Base
    attr_accessor :globals, :locals

    def initialize(globals: {}, locals: {})
      @globals = globals
      @locals = locals
    end

    def run(command)
      old_stdout = $stdout
      $stdout = mystdout = StringIO.new
      begin
        eval(command, binding)
        $stdout = old_stdout
        output = mystdout.string
      rescue => e
        $stdout = old_stdout
        puts e
        output = nil
      end
      output
    end
  end
end
