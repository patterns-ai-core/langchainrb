# frozen_string_literal: true

module Langchain
  module Utils
    class Colorizer
      def self.colorize(line, options)
        decorated_line = Rainbow(line)
        options.each_pair.each do |modifier, value|
          decorated_line = if modifier == :mode
            decorated_line.public_send(value)
          else
            decorated_line.public_send(modifier, value)
          end
        end
        decorated_line
      end
    end
  end
end
